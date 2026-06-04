/*
  Flake version renderer with decorations — prints "Flake version <git-hash><-dirty>" output.

  Stub module. Consumes the flakeVersion runtime library and owns labels,
  colors, and layout for the version line.
*/
{
  flakeVersion,
  libThemes,
  renderer,
}:

let
  versionLabel = "\\n${libThemes.theme.bold_zero}Flake version ${libThemes.mode.reset}";

  dirtySuffix =
    if renderer.shell == "fish" then
      ''
        set -l __flake_dirty_state (${flakeVersion.flakeDirtyStateCall.fish})
        if test -n "$__flake_dirty_state"
          printf '%b' "${libThemes.theme.bold_three}-"
          printf '%s' "$__flake_dirty_state"
        end
      ''
    else if renderer.shell == "nushell" then
      ''
        let __flake_dirty_state = (${flakeVersion.flakeDirtyStateFuncName})
        if ($__flake_dirty_state != "") {
          print --no-newline "${libThemes.theme.bold_three}-"
          print --no-newline $__flake_dirty_state
        }
      ''
    else
      ''
        local __flake_dirty_state
        __flake_dirty_state="$(${flakeVersion.flakeDirtyStateCall.posix})"
        if [[ -n "$__flake_dirty_state" ]]; then
          printf '%b' "${libThemes.theme.bold_three}-"
          printf '%s' "$__flake_dirty_state"
        fi
      '';
in
{
  contentPosix = ''
    ${flakeVersion.flakeVersionFunc.posix}
    ${flakeVersion.flakeDirtyStateFunc.posix}

    printf '%b' "${versionLabel}"
    ${flakeVersion.flakeVersionCall.posix}
    ${dirtySuffix}
    printf '%b' "${libThemes.mode.reset}"
  '';

  contentFish = ''
    ${flakeVersion.flakeVersionFunc.fish}
    ${flakeVersion.flakeDirtyStateFunc.fish}

    printf '%b' "${versionLabel}"
    ${flakeVersion.flakeVersionCall.fish}
    ${dirtySuffix}
    printf '%b' "${libThemes.mode.reset}"
  '';

  contentNu = ''
    ${flakeVersion.flakeVersionFunc.nushell}
    ${flakeVersion.flakeDirtyStateFunc.nushell}

    print --no-newline "${versionLabel}"
    ${flakeVersion.flakeVersionCall.nushell}
    ${dirtySuffix}
    print --no-newline "${libThemes.mode.reset}"
  '';
}
