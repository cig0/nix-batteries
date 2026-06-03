# Flake Version

Runtime shell helpers for printing the current flake Git version and dirty
state. This library emits shell code; it does not read Git metadata during Nix
evaluation.

## Exports

| Attribute | Description |
|---|---|
| `flakeVersionFunc.{posix,fish,nushell}` | Define a shell-native `_flakeVersion` helper |
| `flakeVersionCall.{posix,fish,nushell}` | Call `_flakeVersion` in shell-native syntax |
| `flakeDirtyStateFunc.{posix,fish,nushell}` | Define a shell-native `_flakeDirtyState` helper |
| `flakeDirtyStateCall.{posix,fish,nushell}` | Call `_flakeDirtyState` in shell-native syntax |

## Parameters

```nix
{
  flakeVersionFuncName = "_flakeVersion";
  flakeDirtyStateFuncName = "_flakeDirtyState";
  flakeVersionFallback = "git-unknown";
  flakeDirtyStateText = "dirty";
  flakePathEnvVar = "FLAKE_SRC_PATH";
}
```

## Runtime Boundary

Pure flake evaluation cannot inspect the host checkout's live dirty state. Nix
modules can embed these generated shell functions, but only the runtime shell
can call them and print their result.

Consumers own labels, colors, separators, and placement. This library only
prints raw values:

- `git-<short-hash>` or `git-unknown`
- `dirty` or an empty string

## REPL Example

Pasteable eval that shows the exported helper names:

```sh
nix eval --impure --expr '
let
  flakeRoot = builtins.toPath (builtins.getEnv "PWD");
  flakeVersion = import (flakeRoot + "/lib/tools/flake-version") { };
in
  builtins.attrNames flakeVersion.flakeVersionFunc
' --json
```

Print one generated POSIX function:

```sh
nix eval --impure --raw --expr '
let
  flakeVersion = import ./lib/tools/flake-version { };
in
  flakeVersion.flakeVersionFunc.posix
'
```

## Consumer Example

Nix module snippet for a POSIX shell. The library provides raw runtime values;
the consumer owns colors and separators:

```nix
let
  flakeVersion = import "${flakeRoot}/lib/tools/flake-version" { };
in
''
  ${flakeVersion.flakeVersionFunc.posix}
  ${flakeVersion.flakeDirtyStateFunc.posix}

  printf '%b' "Flake version: ${libThemes.theme.bold_one}"
  ${flakeVersion.flakeVersionCall.posix}

  __dirty="$(${flakeVersion.flakeDirtyStateCall.posix})"
  if [[ -n "$__dirty" ]]; then
    printf '%b' "${libThemes.theme.bold_three}-"
    printf '%s' "$__dirty"
  fi
  unset __dirty

  printf '%b' "${libThemes.mode.reset}\n"
''
```

## Working Examples

Run the helpers against this checkout from a POSIX shell:

```sh
tmp="$(mktemp)"
expr="$(mktemp)"
cat > "$expr" <<'NIX'
let
  flakeVersion = import ./lib/tools/flake-version { };
in
  flakeVersion.flakeVersionFunc.posix
  + "\n"
  + flakeVersion.flakeDirtyStateFunc.posix
  + "\n"
  + ''
    export FLAKE_SRC_PATH="$PWD"
    printf "version="
    ${flakeVersion.flakeVersionCall.posix}
    dirty="$(${flakeVersion.flakeDirtyStateCall.posix})"
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
version=git-750b83d-dirty
```

The hash and dirty suffix depend on your checkout state.

Render a decorated version line with the repository theme library:

```sh
tmp="$(mktemp)"
expr="$(mktemp)"
cat > "$expr" <<'NIX'
let
  flakeRoot = builtins.toPath (builtins.getEnv "PWD");
  flake = builtins.getFlake (toString flakeRoot);
  libThemes = import (flakeRoot + "/lib/themes/palette.nix") {
    lib = flake.inputs.nixpkgs.lib;
    inherit flakeRoot;
  };
  theme = libThemes.resolve {
    name = "nushell-inspired";
    enableAnsi = true;
  };
  flakeVersion = import (flakeRoot + "/lib/tools/flake-version") { };
in
  flakeVersion.flakeVersionFunc.posix
  + "\n"
  + flakeVersion.flakeDirtyStateFunc.posix
  + "\n"
  + ''
    export FLAKE_SRC_PATH="$PWD"
    printf "%b" "Flake version: ${theme.theme.bold_one}"
    ${flakeVersion.flakeVersionCall.posix}
    dirty="$(${flakeVersion.flakeDirtyStateCall.posix})"
    if [[ -n "$dirty" ]]; then
      printf "%b" "${theme.theme.bold_three}-"
      printf "%s" "$dirty"
    fi
    printf "%b\n" "${theme.mode.reset}"
  ''
NIX
nix eval --impure --raw --file "$expr" > "$tmp"
bash "$tmp"
rm -f "$tmp" "$expr"
```

Use `enableAnsi = false` in the example above to render the same line without
ANSI escape codes.
