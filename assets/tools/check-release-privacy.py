#!/usr/bin/env python3
"""Scan an exact Git tree, or explicitly selected working files, for release privacy."""
import argparse
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

GITLEAKS_VERSION = "8.30.1"
PATTERNS = {
    "password-hash": re.compile(rb"\$(?:6|5|1|2[aby]|y)\$[A-Za-z0-9./$]{12,}"),
    "private-key": re.compile(rb"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|AGE-SECRET-KEY-[A-Z0-9]+"),
    "syncthing-device-id": re.compile(rb"(?<![A-Z2-7])(?:[A-Z2-7]{7}-){7}[A-Z2-7]{7}(?![A-Z2-7])"),
    "personal-home-path": re.compile(rb"(?<![\w/.-])(?:file://)?/(?:Users|home)/([A-Za-z0-9_.-]+)"),
}
IPV4 = re.compile(rb"(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])")
PRIVATE_NETWORKS = [
    ipaddress.IPv4Network((0x0A000000, 8)),
    ipaddress.IPv4Network((0xAC100000, 12)),
    ipaddress.IPv4Network((0xC0A80000, 16)),
    ipaddress.IPv4Network((0x64400000, 10)),
]
EXAMPLE_USERS = {b"user", b"username", b"fixture", b"test", b"linuxbrew", b"me"}


def findings_for(relative, data, forbidden_images):
    findings = []
    path = Path(relative)
    if any(part in {'.codegraph', '.private', 'audit-output', 'recovery-output'} for part in path.parts) or path.name in {'.DS_Store', 'codegraph.db', 'nix-batteries-assessment-muse.md'} or path.suffix == '.bundle':
        findings.append({'file': relative, 'line': 1, 'rule': 'private-artifact'})
    if path.name == 'secrets.json' or path.name.startswith('secrets.local.'):
        findings.append({'file': relative, 'line': 1, 'rule': 'private-secret-file'})
    if hashlib.sha256(data).hexdigest() in forbidden_images:
        findings.append({'file': relative, 'line': 1, 'rule': 'identifying-screenshot'})
    for rule, pattern in PATTERNS.items():
        for match in pattern.finditer(data):
            if rule == 'personal-home-path' and match.group(1) in EXAMPLE_USERS:
                continue
            findings.append({'file': relative, 'line': data.count(b'\n', 0, match.start()) + 1, 'rule': rule})
    for match in IPV4.finditer(data):
        try:
            address = ipaddress.IPv4Address(match.group().decode())
        except ipaddress.AddressValueError:
            continue
        if any(address in network for network in PRIVATE_NETWORKS):
            findings.append({'file': relative, 'line': data.count(b'\n', 0, match.start()) + 1, 'rule': 'private-network-address'})
    return findings


def git(root, *args):
    return subprocess.run(['git', '--no-pager', '-C', str(root), *args], check=True, capture_output=True).stdout


def safe_path(raw):
    path = os.fsdecode(raw)
    if Path(path).is_absolute() or '..' in Path(path).parts or '.git' in Path(path).parts:
        raise ValueError('Unsafe source path')
    return path


def source_files(root, revision=None):
    if revision is not None:
        commit = git(root, 'rev-parse', '--verify', '--end-of-options', revision + '^{commit}').decode().strip()
        for entry in git(root, 'ls-tree', '-rz', '--full-tree', commit).split(b'\0'):
            if not entry:
                continue
            header, raw_path = entry.split(b'\t', 1)
            mode, kind, oid = header.split()
            if kind != b'blob' or mode not in {b'100644', b'100755', b'120000'}:
                raise ValueError('Unsupported Git tree entry')
            yield safe_path(raw_path), git(root, 'cat-file', 'blob', oid.decode())
    else:
        paths = git(root, 'ls-files', '--cached', '--others', '--exclude-standard', '-z')
        for raw_path in sorted(set(filter(None, paths.split(b'\0')))):
            relative = safe_path(raw_path)
            source = root / relative
            for parent in source.parents:
                if parent == root:
                    break
                if parent.is_symlink():
                    raise ValueError('Symlink ancestor in working tree: ' + relative)
            if source.is_symlink():
                yield relative, os.fsencode(os.readlink(source))
            elif source.is_file():
                yield relative, source.read_bytes()
            elif source.exists():
                raise ValueError('Unsupported source entry: ' + relative)
            # A deleted tracked file is absent only in explicit working-tree mode.


def check(root, scanner, revision='HEAD'):
    version = subprocess.run([scanner, 'version'], check=True, capture_output=True, text=True).stdout.strip()
    if version != GITLEAKS_VERSION:
        raise ValueError('Gitleaks ' + GITLEAKS_VERSION + ' is required; found ' + version)
    files = dict(source_files(root, revision))
    if not files:
        raise ValueError('Refusing an empty scan')
    config = files.get('.gitleaks.toml')
    if config is None:
        raise ValueError('Missing candidate Gitleaks configuration')
    policy = json.loads(files['assets/release/privacy-policy.json'])
    image_hashes = [entry['sha256'] for entry in policy['forbidden_images']]
    forbidden = set(image_hashes)
    if not forbidden or len(forbidden) != len(image_hashes) or any(not re.fullmatch(r'[a-f0-9]{64}', value) for value in forbidden):
        raise ValueError('Expected distinct SHA-256 screenshot hashes')
    findings = []
    with tempfile.TemporaryDirectory(prefix='nix-batteries-privacy-') as temp:
        directory = Path(temp)
        snapshot = directory / 'source'
        snapshot.mkdir()
        for relative, data in files.items():
            findings.extend(findings_for(relative, data, forbidden))
            target = snapshot / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        config_path = directory / 'gitleaks.toml'
        config_path.write_bytes(config)
        report = directory / 'report.json'
        scan = subprocess.run(
            [scanner, 'dir', str(snapshot), '--config', str(config_path), '--redact=100', '--no-banner', '--no-color',
             '--ignore-gitleaks-allow', '--gitleaks-ignore-path', str(directory / 'unused-ignore'),
             '--max-decode-depth', '5', '--max-archive-depth', '3', '--report-format', 'json', '--report-path', str(report)],
            capture_output=True,
        )
        if scan.returncode not in (0, 1):
            raise RuntimeError('Gitleaks failed with exit status ' + str(scan.returncode))
        leaks = json.loads(report.read_bytes())
        if not isinstance(leaks, list) or (scan.returncode == 1 and not leaks):
            raise RuntimeError('Gitleaks returned inconsistent results')
        for leak in leaks:
            filename = Path(leak['File'])
            if filename.is_absolute():
                filename = filename.relative_to(snapshot)
            findings.append({'file': str(filename), 'line': leak['StartLine'], 'rule': 'gitleaks:' + leak['RuleID']})
    return {'revision': revision, 'files_checked': len(files), 'gitleaks_version': version, 'findings': findings}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--revision', default='HEAD', help='Committed revision to scan (default HEAD)')
    mode.add_argument('--worktree', action='store_true', help='Review tracked and unignored working files; not release certification')
    parser.add_argument('--gitleaks', default='gitleaks', help='Path to Gitleaks 8.30.1')
    args = parser.parse_args()
    try:
        root = args.root.resolve()
        if Path(os.fsdecode(git(root, 'rev-parse', '--show-toplevel')).strip()).resolve() != root:
            raise ValueError('Root must be the repository root')
        result = check(root, args.gitleaks, None if args.worktree else args.revision)
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.CalledProcessError) as error:
        print('Privacy check failed: ' + str(error), file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 1 if result['findings'] else 0


if __name__ == '__main__':
    sys.exit(main())
