/*
  === Guard Flake Input ===

  Conditionally enable Nix modules based on whether their corresponding
  flake input exists. When an input is missing, the module is silently
  disabled and a trace message is emitted to stderr — no build breakage,
  no manual comment-chasing.

  Flake inputs are normalized by channel-inputs.nix (stripping -unstable
  and -stable suffixes), so the guard works uniformly across channels:
  referencing "rust-overlay" matches whether the host is on stable or
  unstable.

  Exports:

    guard — check a flake input and return a record with:
      has    — bool, whether the input exists in _inputs
      input  — the input value, or null if missing
      apply  — call a function with the input if present, else return
               a fallback value and emit a trace warning

  Usage:

    let
      guard = import ./libraries/guard-flake-input { inherit lib; };
      rust  = guard "rust-overlay" _inputs;
    in
    {
      nixpkgs.overlays = rust.apply (input: [ input.overlays.default ]) [ ];
    }
*/
{ lib }:

name: inputs:
let
  has = builtins.hasAttr name inputs;
in
{
  /*
    Whether the input exists in _inputs.

    Type: has :: bool
  */
  inherit has;

  /*
    The input value, or null if missing.

    Type: input :: a | null
  */
  input = if has then inputs.${name} else null;

  /*
    Conditionally apply a function to the input.
    If the input exists, calls onPresent with it and returns the result.
    If the input is missing, returns onAbsent and emits a trace warning
    to stderr with the input name.

    Type: apply :: (a -> b) -> b -> b
  */
  apply =
    onPresent: onAbsent:
    if has then
      onPresent inputs.${name}
    else
      builtins.trace "[guard-flake-input] ${name} module disabled: flake input missing" onAbsent;
}
