#!/usr/bin/env python3
"""Exercise release snapshot boundaries with disposable synthetic repositories."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('privacy', Path(__file__).with_name('check-release-privacy.py'))
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)


class PrivacyChecks(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / 'repo'
        self.root.mkdir()
        self.git('init', '--quiet')

    def git(self, *args, data=None):
        env = dict(os.environ, GIT_AUTHOR_NAME='Fixture', GIT_AUTHOR_EMAIL='fixture@example.com',
                   GIT_COMMITTER_NAME='Fixture', GIT_COMMITTER_EMAIL='fixture@example.com')
        return subprocess.run(['git', '--no-pager', '-C', str(self.root), *args],
                              input=data, check=True, capture_output=True, env=env).stdout

    def commit(self):
        self.git('add', '--all')
        tree = self.git('write-tree').decode().strip()
        return self.git('commit-tree', tree, '-m', 'Synthetic fixture').decode().strip()

    def test_renamed_image_is_rejected_by_bytes(self):
        data = b'synthetic identifying screenshot bytes'
        forbidden = {hashlib.sha256(data).hexdigest()}
        self.assertEqual(privacy.findings_for('renamed.bin', data, forbidden)[0]['rule'], 'identifying-screenshot')

    def test_tracked_ignored_file_and_export_ignored_file_are_scanned(self):
        (self.root / '.gitignore').write_text('secrets.local.*\n')
        (self.root / '.gitattributes').write_text('hidden.txt export-ignore\n')
        (self.root / 'secrets.local.json').write_text('{}')
        (self.root / 'hidden.txt').write_text('kept in the committed tree')
        self.git('add', '-f', 'secrets.local.json')
        revision = self.commit()
        files = dict(privacy.source_files(self.root, revision))
        self.assertIn('hidden.txt', files)
        self.assertEqual(privacy.findings_for('secrets.local.json', files['secrets.local.json'], set())[0]['rule'], 'private-secret-file')

    def test_committed_scan_ignores_later_worktree_edits(self):
        (self.root / 'example.txt').write_text('committed bytes')
        revision = self.commit()
        (self.root / 'example.txt').write_text('different working bytes')
        (self.root / 'extra.txt').write_text('uncommitted')
        self.assertEqual(dict(privacy.source_files(self.root, revision)), {'example.txt': b'committed bytes'})
        self.assertIn('extra.txt', dict(privacy.source_files(self.root)))

    def test_symlink_target_is_text_and_ancestor_is_rejected(self):
        external = self.root.parent / 'private.txt'
        external.write_text('must never be read')
        (self.root / 'link').symlink_to('../private.txt')
        revision = self.commit()
        self.assertEqual(dict(privacy.source_files(self.root, revision))['link'], b'../private.txt')
        self.assertEqual(dict(privacy.source_files(self.root))['link'], b'../private.txt')
        (self.root / 'nested').mkdir()
        (self.root / 'nested/file').write_text('tracked')
        self.git('add', 'nested/file')
        (self.root / 'nested/file').unlink()
        (self.root / 'nested').rmdir()
        (self.root / 'nested').symlink_to(self.root.parent)
        with self.assertRaisesRegex(ValueError, 'Symlink ancestor'):
            dict(privacy.source_files(self.root))

    def test_public_identity_and_synthetic_examples_remain_allowed(self):
        safe = b'maru 1010 sidecar hoagie hs /workspace/my-flake /home/user https://example.com'
        self.assertFalse(privacy.findings_for('fixture.txt', safe, set()))
        self.assertFalse(privacy.findings_for('secrets.example.json', b'{}', set()))
        private = b'/Users/' + b'private-person/project'
        findings = privacy.findings_for('example.txt', private, set())
        self.assertEqual(findings[0]['rule'], 'personal-home-path')
        self.assertNotIn('private-person', str(findings))

    def test_private_artifacts_remain_disallowed(self):
        for name in ['.DS_Store', '.codegraph/cache', 'recovery-output/state', 'private.bundle', 'nix-batteries-assessment-muse.md']:
            with self.subTest(name=name):
                self.assertEqual(privacy.findings_for(name, b'{}', set())[0]['rule'], 'private-artifact')

    def test_scanner_version_and_operational_failures_are_errors(self):
        (self.root / '.gitleaks.toml').write_text('[extend]\nuseDefault = true\n')
        (self.root / 'assets/release').mkdir(parents=True)
        policy = {'forbidden_images': [{'sha256': hashlib.sha256(str(i).encode()).hexdigest()} for i in range(6)]}
        (self.root / 'assets/release/privacy-policy.json').write_text(json.dumps(policy))
        version = subprocess.CompletedProcess([], 0, stdout='8.30.1\n')
        failure = subprocess.CompletedProcess([], 2, stdout=b'', stderr=b'')
        with patch.object(privacy.subprocess, 'run', side_effect=[version, failure]):
            with patch.object(privacy, 'source_files', return_value=[('.gitleaks.toml', b'[extend]\nuseDefault = true\n'), ('assets/release/privacy-policy.json', json.dumps(policy).encode())]):
                with self.assertRaisesRegex(RuntimeError, 'exit status 2'):
                    privacy.check(self.root, 'scanner')
        with patch.object(privacy.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, stdout='wrong\n')):
            with self.assertRaisesRegex(ValueError, 'required'):
                privacy.check(self.root, 'scanner')
        with self.assertRaises(FileNotFoundError):
            privacy.check(self.root, str(self.root / 'missing-tool'))


if __name__ == '__main__':
    unittest.main()
