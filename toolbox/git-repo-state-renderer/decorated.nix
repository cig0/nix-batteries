/*
  Git repo state renderer with decorations — prints "Git revision git-<hash><-dirty>" output.

  Stub module. Consumes the gitRepoState runtime library and owns labels,
  colors, and layout for the version line.
*/
{
  gitRepoState,
  libThemes,
  renderer,
}:

let
  revisionLabel = "\\n${libThemes.theme.bold_zero}Git revision ${libThemes.mode.reset}";

  dirtySuffix =
    if renderer.shell == "fish" then
      ''
        set -l __git_dirty_state (${gitRepoState.dirtyStateCall.fish})
        if test -n "$__git_dirty_state"
          printf '%b' "${libThemes.theme.bold_seven}-"
          printf '%s' "$__git_dirty_state"
        end
      ''
    else if renderer.shell == "nushell" then
      ''
        let __git_dirty_state = (${gitRepoState.dirtyStateFunctionName})
        if ($__git_dirty_state != "") {
          print --no-newline "${libThemes.theme.bold_seven}-"
          print --no-newline $__git_dirty_state
        }
      ''
    else
      ''
        __git_dirty_state="$(${gitRepoState.dirtyStateCall.posix})"
        if [[ -n "$__git_dirty_state" ]]; then
          printf '%b' "${libThemes.theme.bold_seven}-"
          printf '%s' "$__git_dirty_state"
        fi
        unset __git_dirty_state
      '';
in
{
  contentPosix = ''
    ${gitRepoState.revisionFunction.posix}
    ${gitRepoState.dirtyStateFunction.posix}

    printf '%b' "${revisionLabel}"
    printf '%s' "git-"
    ${gitRepoState.revisionCall.posix}
    ${dirtySuffix}
    printf '%b' "${libThemes.mode.reset}"
  '';

  contentFish = ''
    ${gitRepoState.revisionFunction.fish}
    ${gitRepoState.dirtyStateFunction.fish}

    printf '%b' "${revisionLabel}"
    printf '%s' "git-"
    ${gitRepoState.revisionCall.fish}
    ${dirtySuffix}
    printf '%b' "${libThemes.mode.reset}"
  '';

  contentNu = ''
    ${gitRepoState.revisionFunction.nushell}
    ${gitRepoState.dirtyStateFunction.nushell}

    print --no-newline "${revisionLabel}"
    print --no-newline "git-"
    ${gitRepoState.revisionCall.nushell}
    ${dirtySuffix}
    print --no-newline "${libThemes.mode.reset}"
  '';
}
