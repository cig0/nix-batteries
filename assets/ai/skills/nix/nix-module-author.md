# Nix Module Author

Use this workflow to create or extend a NixOS or Home Manager module.

## Define the contract

1. Confirm the option namespace, owning layer, supported platforms, and expected
   consumers.
2. Search for existing option and module patterns before introducing new ones.
3. Define precise option types, conservative defaults, useful descriptions,
   and examples where the value shape is not obvious.
4. Add `enable = lib.mkEnableOption ...` only for an optional feature that needs
   an independent gate. Do not manufacture enable options for passive data or
   modules that are enabled by an existing parent contract.
5. Use submodules or structured types when callers benefit from validation.
   Avoid untyped attribute sets when a stable schema exists.

## Implement

- Gate owned configuration with `lib.mkIf cfg.enable` when the module has an
  enable option.
- Keep `imports` independent of `config`; imports are resolved before module
  configuration is evaluated.
- Let each option value retain semantic Nix types internally. Convert to
  protocol strings only at the consumer boundary.
- Use `lib` helpers when they make merge behavior or intent clearer, not merely
  to avoid a small direct expression.
- Avoid hardcoded host paths, usernames, systems, package channels, and flake
  input names unless they are part of the declared contract.
- Add platform guards only where behavior or option availability actually
  differs.

## Verify

Evaluate both the default/disabled path and representative enabled
configuration. Check invalid values when the option type or assertions carry
important constraints. Verify generated files or commands at their consumer
boundary, and include concise real-world usage in adjacent documentation when
the repository requires it.
