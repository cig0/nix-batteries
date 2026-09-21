# Git Repo State

Runtime shell helpers for printing a Git repository's current short revision
and dirty state. This library emits shell code; it does not read Git metadata
during Nix evaluation.

## Exports

| Attribute                                 | Description                                   |
| ----------------------------------------- | --------------------------------------------- |
| `revisionFunction.{posix,fish,nushell}`   | Define a shell-native `_gitRevision` helper   |
| `revisionCall.{posix,fish,nushell}`       | Call `_gitRevision` in shell-native syntax    |
| `dirtyStateFunction.{posix,fish,nushell}` | Define a shell-native `_gitDirtyState` helper |
| `dirtyStateCall.{posix,fish,nushell}`     | Call `_gitDirtyState` in shell-native syntax  |

The `posix` variants use POSIX shell grammar, so `dash`, `bash`, and `zsh`
all execute them as generated.

## Parameters

```nix
{
  revisionFunctionName = "_gitRevision";
  dirtyStateFunctionName = "_gitDirtyState";
  unknownRevisionText = "unknown";
  dirtyStateText = "dirty";
  repositoryPathEnvVar = "GIT_REPO_PATH";
}
```

## Runtime Boundary

Pure flake evaluation cannot inspect a host checkout's live dirty state. Nix
modules can embed these generated shell functions, but only the runtime shell
can call them and print their result.

Consumers own labels, colors, prefixes, separators, and placement. This library
only prints raw values:

- `<short-hash>` or `unknown`
- `dirty` or an empty string

Revision lookup failure prints `unknownRevisionText`. Dirty-state lookup failure
returns a nonzero status in POSIX/Fish or raises a Nushell error, with no clean
result on stdout. Git diagnostics remain visible; consumers own error display.
An unset or empty repository-path variable selects the current directory.

Labels are literal text, including quotes, dollar signs, backslashes, and line
breaks. They use shell-specific quoting for `%s`, independently of help-legend's
`%b` escaping. Configured identifiers must match `[A-Za-z_][A-Za-z0-9_]*`;
function names must differ and cannot be reserved words or commands used by
these helpers. Invalid identifiers fail during Nix evaluation. Callers must
choose names that do not collide with their other shell functions.

## REPL Example

Pasteable eval that shows the exported helper names:

```sh
nix eval --impure --expr '
let
  flakeRoot = builtins.toPath (builtins.getEnv "PWD");
  gitRepoState = import (flakeRoot + "/libraries/toolbox/git-repo-state") { };
in
  builtins.attrNames gitRepoState.revisionFunction
' --json
```

Print one generated POSIX function:

```sh
nix eval --impure --raw --expr '
let
  gitRepoState = import ./libraries/toolbox/git-repo-state { };
in
  gitRepoState.revisionFunction.posix
'
```

## Consumer Example

Nix module snippet for a POSIX shell. The library provides raw runtime values;
the consumer owns the `git-` display prefix, colors, and separators:

```nix
let
  gitRepoState = _inputs.nix-batteries.batteriesLib.gitRepoState;
in
''
  ${gitRepoState.revisionFunction.posix}
  ${gitRepoState.dirtyStateFunction.posix}

  printf '%b' "Git revision ${libThemes.mode.reset}"
  printf '%s' "git-"
  ${gitRepoState.revisionCall.posix}

  __dirty="$(${gitRepoState.dirtyStateCall.posix})" || __dirty="unknown"
  if [ -n "$__dirty" ]; then
    printf '%b' "${libThemes.theme.bold.notice}-"
    printf '%s' "$__dirty"
  fi
  unset __dirty

  printf '%b' "${libThemes.mode.reset}"
  printf '%b' "\n"
''
```

## Working Example

Run the helpers against this checkout from a POSIX shell:

```sh
tmp="$(mktemp)"
expr="$(mktemp)"
cat > "$expr" <<'NIX'
let
  # This expression lives in a temporary file, so resolve from the checkout.
  root = builtins.toPath (builtins.getEnv "PWD");
  gitRepoState = import (root + "/libraries/toolbox/git-repo-state") { };
in
  gitRepoState.revisionFunction.posix
  + "\n"
  + gitRepoState.dirtyStateFunction.posix
  + "\n"
  + ''
    export GIT_REPO_PATH="$PWD"
    printf "revision=git-"
    ${gitRepoState.revisionCall.posix}
    dirty="$(${gitRepoState.dirtyStateCall.posix})" || dirty="unknown"
    if [ -n "$dirty" ]; then
      printf -- "-%s" "$dirty"
    fi
    printf "\n"
  ''
NIX
nix eval --impure --raw --file "$expr" > "$tmp"
sh "$tmp"
rm -f "$tmp" "$expr"
```

Expected output shape:

```text
revision=git-750b83d-dirty
```

The hash and dirty suffix depend on your checkout state.
