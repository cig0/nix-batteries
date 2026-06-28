# Git Repo State

Runtime shell helpers for printing a Git repository's current short revision
and dirty state. This library emits shell code; it does not read Git metadata
during Nix evaluation.

## Exports

| Attribute | Description |
|---|---|
| `revisionFunction.{posix,fish,nushell}` | Define a shell-native `_gitRevision` helper |
| `revisionCall.{posix,fish,nushell}` | Call `_gitRevision` in shell-native syntax |
| `dirtyStateFunction.{posix,fish,nushell}` | Define a shell-native `_gitDirtyState` helper |
| `dirtyStateCall.{posix,fish,nushell}` | Call `_gitDirtyState` in shell-native syntax |

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

## REPL Example

Pasteable eval that shows the exported helper names:

```sh
nix eval --impure --expr '
let
  flakeRoot = builtins.toPath (builtins.getEnv "PWD");
  gitRepoState = import (flakeRoot + "/toolbox/git-repo-state") { };
in
  builtins.attrNames gitRepoState.revisionFunction
' --json
```

Print one generated POSIX function:

```sh
nix eval --impure --raw --expr '
let
  gitRepoState = import ./toolbox/git-repo-state { };
in
  gitRepoState.revisionFunction.posix
'
```

## Consumer Example

Nix module snippet for a POSIX shell. The library provides raw runtime values;
the consumer owns the `git-` display prefix, colors, and separators:

```nix
let
  gitRepoState = _inputs.nix-fuel.fuelLibs.gitRepoState;
in
''
  ${gitRepoState.revisionFunction.posix}
  ${gitRepoState.dirtyStateFunction.posix}

  printf '%b' "Git revision ${libThemes.mode.reset}"
  printf '%s' "git-"
  ${gitRepoState.revisionCall.posix}

  __dirty="$(${gitRepoState.dirtyStateCall.posix})"
  if [[ -n "$__dirty" ]]; then
    printf '%b' "${libThemes.theme.bold_three}-"
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
  gitRepoState = import ./toolbox/git-repo-state { };
in
  gitRepoState.revisionFunction.posix
  + "\n"
  + gitRepoState.dirtyStateFunction.posix
  + "\n"
  + ''
    export GIT_REPO_PATH="$PWD"
    printf "revision=git-"
    ${gitRepoState.revisionCall.posix}
    dirty="$(${gitRepoState.dirtyStateCall.posix})"
    if [[ -n "$dirty" ]]; then
      printf -- "-%s" "$dirty"
    fi
    printf "\n"
  ''
NIX
nix eval --impure --raw --file "$expr" > "$tmp"
bash "$tmp"
rm -f "$tmp" "$expr"
```

Expected output shape:

```text
revision=git-750b83d-dirty
```

The hash and dirty suffix depend on your checkout state.
