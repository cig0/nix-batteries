# Guard flake input

Use `guardFlakeInput name inputs` to look up an optional dependency by name.
The returned record lets a module guard its imports or choose a fallback.

| Field   | Type                 | Description                                                                            |
| ------- | -------------------- | -------------------------------------------------------------------------------------- |
| `has`   | `bool`               | Whether the input exists                                                               |
| `input` | `a or null`          | The input value, or `null` if missing                                                  |
| `apply` | `(a -> b) -> b -> b` | Call a function with the input if present, else return a fallback with a trace warning |

The lookup is by exact attribute name, so referencing `"rust-overlay"` works whenever that key is present in the given set. Consumers that normalize keys across channels (for example by stripping `-unstable` suffixes) pass the normalized set.

## Examples

### Overlay module

Use an empty overlay list when the input is absent.

```nix
{ _inputs, ... }:

let
  rust = _inputs.nix-batteries.batteriesLib.guardFlakeInput "rust-overlay" _inputs;
in
{
  nixpkgs.overlays = rust.apply (input: [ input.overlays.default ]) [ ];
}
```

### Home Manager module with conditional imports

This example uses a hypothetical `example-tool` input that exports a Home
Manager module declaring `programs.example-tool.enable`.

```nix
{ _inputs, lib, ... }:

let
  tool = _inputs.nix-batteries.batteriesLib.guardFlakeInput "example-tool" _inputs;
in
{
  imports = lib.optionals tool.has [
    tool.input.homeModules.default
    { programs.example-tool.enable = true; }
  ];
}
```

### Multiple guards in one module

This example also assumes an `example-service` input that exports a Home
Manager module declaring `services.example-service.enable`.

```nix
{ _inputs, lib, ... }:

let
  guard = _inputs.nix-batteries.batteriesLib.guardFlakeInput;
  tool = guard "example-tool" _inputs;
  service = guard "example-service" _inputs;
in
{
  imports =
    lib.optionals tool.has [
      tool.input.homeModules.default
      { programs.example-tool.enable = true; }
    ]
    ++ lib.optionals service.has [
      service.input.homeModules.default
      { services.example-service.enable = true; }
    ];
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

Arguments used to compute `imports` must be available before module
configuration is evaluated. Pass `_inputs` and any preconfigured guard through
`specialArgs` (NixOS or `lib.evalModules`) or `extraSpecialArgs` (Home
Manager), or capture them in a lexical closure:

```nix
extraSpecialArgs = {
  _inputs = inputs;
  guard = name: inputs.nix-batteries.batteriesLib.guardFlakeInput name inputs;
};
```

For values used only in configuration, `_module.args` is also suitable:

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

When `apply` handles a missing input, `builtins.trace` writes to stderr during evaluation:

```
[guard-flake-input] rust-overlay module disabled: flake input missing
```

Reading `has` or `input` is silent.
