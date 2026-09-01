# Nixpkgs Package Contribution

Use this workflow when contributing a nixpkgs package change: adopting a
package, becoming a maintainer, updating a version, or changing a package's
metadata.

Preparing commit messages or PR content does not authorize committing,
rewriting history, pushing, opening a PR, or changing system-wide Nix
configuration.

## Before committing

- Confirm the package attribute and the appropriate base branch. Most package
  changes target `master`; mass rebuilds may need `staging`.
- Read `CONTRIBUTING.md`, `pkgs/README.md`, and any README that governs the
  package's directory.
- When adding or adopting a package, also read `maintainers/README.md` and
  confirm that you are prepared to maintain it.
- For version updates, read the upstream release notes and check for changed
  dependencies, build flags, patches, tests, runtime behavior, and licensing.
- Follow `CONTRIBUTING.md`'s Automation/AI policy. A responsible person must
  understand and review the contribution before submission, and non-trivial
  automation must be disclosed.

## Commit structure

When adding yourself to a package's `meta.maintainers`, if you are not already
in `maintainers/maintainer-list.nix`, use two commits in this order:

1. Add yourself to the maintainer list:

   ```text
   maintainers: add <handle>
   ```

   Put this commit first and keep it limited to
   `maintainers/maintainer-list.nix`.

2. Package change:

   For a version update plus adoption:

   ```text
   <pkg-name>: <old> -> <new>
   ```

   Example body:

   ```text
   <pkg-name>: 1.2.3 -> 1.4.0

   - Update to latest upstream release.
     https://github.com/owner/repo/releases/tag/v1.4.0
   - Add <handle> to meta.maintainers.
   ```

   For adoption without a version change:

   ```text
   <pkg-name>: add <handle> to maintainers
   ```

- Do not add a trailing period to the summary line.
- Add a fingerprint to the `keys` field only for a PGP/GPG key you actually
  use. If you list one, sign the maintainer-list commit with that key so
  reviewers can verify it. SSH signing keys do not belong in this field.
- When non-trivial AI assistance affected a commit, add the required trailer
  with the tool and primary model name and version:

  ```text
  Assisted-by: <tool> (<model-name-and-version>)
  ```

  A `Co-authored-by:` trailer is not a substitute. Disclose assisted PR text
  and review comments separately as required by the same policy.

## Validation

Run the applicable checks from the Nixpkgs repository root before opening the
PR. Replace every placeholder with a concrete value discovered from the package
before running a command; never execute angle-bracket placeholders literally.
Keep a record of the platforms and commands tested for the PR template.

```sh
# Format only the changed Nix files
nix fmt -- <changed-file> [<changed-file> ...]

# Build the package
nix-build -A <attribute>

# Check package metadata evaluates
nix eval --json -f . <attribute>.meta
```

Exercise a meaningful runtime path after building. For a command-line package,
this may be:

```sh
./result/bin/<binary> --version
```

Do not invent a binary or `--version` flag for a library, service, GUI
application, or package that uses a different interface.

If `maintainers/maintainer-list.nix` changed, validate its structure:

```sh
nix-build lib/tests/maintainers.nix
```

If the package defines `passthru.tests`, build them. Also run existing
applicable NixOS tests (`nixosTests.<name>`) or global package tests
(`tests.<name>`).

```sh
nix-build --attr <attribute>.passthru.tests
```

When reverse dependencies may be affected and the cost is reasonable, run one
of the following according to the current Git state:

```sh
# Uncommitted changes
nix-shell -p nixpkgs-review --run "nixpkgs-review wip"

# Latest commit
nix-shell -p nixpkgs-review --run "nixpkgs-review rev HEAD"
```

A package build plus a meaningful smoke test is the minimum when no automated
test exists. For simple command-line programs, consider adding a version test
with `testers.testVersion` when it provides useful regression coverage.

Check whether sandboxing is enabled before building. Do not edit
`/etc/nix/nix.conf` or other system configuration without explicit
authorization; report sandboxing as an unverified gap when it cannot be enabled
safely. Test every supported platform that is practical, but report only
platforms you actually tested.

## Common pitfalls

- `nix-build -A <pkg>.passthru.tests` fails with `attribute 'tests' in
  selection path ... not found`: the package has no tests. Use the smoke test
  instead.
- Assuming a successful build proves runtime behavior: execute the main binary
  or document another meaningful smoke test.
- Committing the maintainer-list change after the package change breaks the
  convention. Report the ordering problem; use `git rebase -i` only when
  history rewriting is explicitly authorized.
- Adding a PGP/GPG `keys` entry without signing the maintainer-list commit with
  that key creates avoidable review work; omit `keys` if you do not use PGP/GPG.

## PR title

Keep the PR title descriptive and normally aligned with the package commit.
Examples:

```text
<pkg-name>: <old> -> <new>, add <handle> as maintainer
<pkg-name>: adopt and update to <new>
```

The `pkg-name:` prefix on the **commit summary** is what queues automatic
package builds; outside the special `WIP:`/`[WIP]` handling, the PR title is
for humans.
