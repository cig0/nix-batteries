/*
  Flake version renderer RAW — prints "<git-hash><-dirty>" output without decorations.

  Stub module. Consumes the flakeVersion runtime library.
*/
{
  flakeVersion,
  renderer,
}:

let
  dirtySuffix =
    if renderer.shell == "fish" then
      ''
        set -l __flake_dirty_state (${flakeVersion.flakeDirtyStateCall.fish})
        if test -n "$__flake_dirty_state"
          printf '%b' "-"
          printf '%s' "$__flake_dirty_state"
        end
      ''
    else if renderer.shell == "nushell" then
      ''
        let __flake_dirty_state = (${flakeVersion.flakeDirtyStateFuncName})
        if ($__flake_dirty_state != "") {
          print --no-newline "-"
          print --no-newline $__flake_dirty_state
        }
      ''
    else
      ''
        local __flake_dirty_state
        __flake_dirty_state="$(${flakeVersion.flakeDirtyStateCall.posix})"
        if [[ -n "$__flake_dirty_state" ]]; then
          printf '%b' "-"
          printf '%s' "$__flake_dirty_state"
        fi
      '';
in
{
  contentPosix = ''
    ${flakeVersion.flakeVersionFunc.posix}
    ${flakeVersion.flakeDirtyStateFunc.posix}

    ${flakeVersion.flakeVersionCall.posix}
    ${dirtySuffix}
  '';

  contentFish = ''
    ${flakeVersion.flakeVersionFunc.fish}
    ${flakeVersion.flakeDirtyStateFunc.fish}

    ${flakeVersion.flakeVersionCall.fish}
    ${dirtySuffix}
  '';

  contentNu = ''
    ${flakeVersion.flakeVersionFunc.nushell}
    ${flakeVersion.flakeDirtyStateFunc.nushell}

    ${flakeVersion.flakeVersionCall.nushell}
    ${dirtySuffix}
  '';
}
