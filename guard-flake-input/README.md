# Guard Flake Input

Conditionally enable Nix modules based on whether their corresponding flake input exists. When an input is missing, the module is silently disabled and a trace message is emitted — no build breakage, no manual comment-chasing.

## Why

Flake inputs and the modules that depend on them are defined in different places. Removing an input from `flake.nix` without also disabling its module causes a build failure — and the only safeguard is typically a comment:

```nix
# If disabling or removing this input do the same with
# ./config/home-manager/modules/development/rust-overlay.nix
rust-overlay.url = "github:oxalica/rust-overlay";
```

This is fragile. `guard-flake-input` makes the relationship explicit in code: if the input disappears, the module gracefully degrades instead of breaking.

## How It Works

The guard function takes a flake input name and the `_inputs` attrset (normalized by `channel-inputs.nix`), then returns a record with:

| Field | Type | Description |
|---|---|---|
| `has` | `bool` | Whether the input exists |
| `input` | `a or null` | The input value, or `null` if missing |
| `apply` | `(a -> b) -> b -> b` | Call a function with the input if present, else return a fallback with a trace warning |

Because `_inputs` keys are already normalized (suffixes like `-unstable` are stripped by `channel-inputs.nix`), referencing `"rust-overlay"` works uniformly across channels.

## Examples

### Overlay module

Before — breaks if the input is removed:

```nix
{ _inputs, ... }:

{
  nixpkgs.overlays = [ _inputs.rust-overlay.overlays.default ];
}
```

After — degrades gracefully:

```nix
{ _inputs, ... }:

let
  rust = _inputs.nix-ignite.lib.guardFlakeInput "rust-overlay" _inputs;
in
{
  nixpkgs.overlays = rust.apply (input: [ input.overlays.default ]) [ ];
}
```

If `rust-overlay` is present → overlay is applied.  
If `rust-overlay` is missing → overlay is skipped, trace message is emitted.

### Home Manager module with conditional imports

```nix
{ _inputs, lib, ... }:

let
  nixvim = _inputs.nix-ignite.lib.guardFlakeInput "nixvim" _inputs;
in
{
  imports = lib.optional nixvim.has [
    nixvim.input.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim.enable = nixvim.has;
}
```

### Multiple guards in one module

```nix
{ _inputs, lib, ... }:

let
  guard = _inputs.nix-ignite.lib.guardFlakeInput;
  nixIndex = guard "nix-index-database" _inputs;
  nixvim = guard "nixvim" _inputs;
in
{
  imports = lib.optional nixvim.has [
    nixvim.input.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim.enable = nixvim.has;
  programs.nix-index.enable = nixIndex.has;
}
```

### Using `has` for boolean gates

When you don't need the input value itself, just whether it exists:

```nix
{ _inputs, lib, ... }:

let
  disko = _inputs.nix-ignite.lib.guardFlakeInput "disko" _inputs;
in
{
  # Only show disk formatting commands if disko is available
  myOptions.hm.programs.zsh.shellCommands = lib.mkIf disko.has {
    # ...
  };
}
```

### Using `apply` for conditional overlays

```nix
{ _inputs, ... }:

let
  guard = _inputs.nix-ignite.lib.guardFlakeInput;
  rust = guard "rust-overlay" _inputs;
  lanzaboote = guard "lanzaboote" _inputs;
in
{
  nixpkgs.overlays =
    (rust.apply (input: [ input.overlays.default ]) [ ])
    ++ (lanzaboote.apply (input: [ input.overlays.default ]) [ ]);
}
```

## Integration

To make `guard-flake-input` available as a module argument, add it to `_module.args` in the same place where `_inputs` is already passed:

```nix
_module.args = {
  _inputs = releaseChannel._inputs;
  guard = name: releaseChannel._inputs.nix-ignite.lib.guardFlakeInput name releaseChannel._inputs;
};
```

Then modules can use it without importing:

```nix
{ _inputs, guard, ... }:

let
  rust = guard "rust-overlay";
in
{
  nixpkgs.overlays = rust.apply (input: [ input.overlays.default ]) [ ];
}
```

## Trace Output

When an input is missing, `builtins.trace` writes to stderr during evaluation:

```
[guard-flake-input] rust-overlay module disabled: flake input missing
```

This message appears in `nix build`, `nixos-rebuild`, `nh os switch`, and other Nix command output. It does not cause the build to fail — it's informational only.
