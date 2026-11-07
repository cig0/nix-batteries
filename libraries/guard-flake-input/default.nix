/*
  Look up an exact name in the supplied flake inputs. Callers use has to
  guard imports and input to access the value. Only apply emits a trace,
  when evaluation needs the fallback for a missing input.
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
