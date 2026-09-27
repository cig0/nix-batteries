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

The guard function takes a flake input name and an inputs attrset (conventionally `_inputs` in consumers), then returns a record with:

| Field   | Type                 | Description                                                                            |
| ------- | -------------------- | -------------------------------------------------------------------------------------- |
| `has`   | `bool`               | Whether the input exists                                                               |
| `input` | `a or null`          | The input value, or `null` if missing                                                  |
| `apply` | `(a -> b) -> b -> b` | Call a function with the input if present, else return a fallback with a trace warning |

The lookup is by exact attribute name, so referencing `"rust-overlay"` works whenever that key is present in the given set. Consumers that normalize keys across channels (for example by stripping `-unstable` suffixes) pass the normalized set.

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
  rust = _inputs.nix-batteries.batteriesLib.guardFlakeInput "rust-overlay" _inputs;
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
  nixvim = _inputs.nix-batteries.batteriesLib.guardFlakeInput "nixvim" _inputs;
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
  guard = _inputs.nix-batteries.batteriesLib.guardFlakeInput;
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
  disko = _inputs.nix-batteries.batteriesLib.guardFlakeInput "disko" _inputs;
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
  guard = _inputs.nix-batteries.batteriesLib.guardFlakeInput;
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

To make `guard-flake-input` available as a module argument, add it to `_module.args` in the same place where the inputs set is already passed:

```nix
_module.args = {
  _inputs = inputs;
  guard = name: inputs.nix-batteries.batteriesLib.guardFlakeInput name inputs;
};
```

Consumers that normalize input keys pass the normalized set instead of raw `inputs`.

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
