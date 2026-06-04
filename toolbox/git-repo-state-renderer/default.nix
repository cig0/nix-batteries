/*
  Git repo state renderer RAW — prints "<git-hash><-dirty>" output without decorations.

  Stub module. Consumes the gitRepoState runtime library.
*/
{
  gitRepoState,
  renderer,
}:

let
  dirtySuffix =
    if renderer.shell == "fish" then
      ''
        set -l __git_dirty_state (${gitRepoState.dirtyStateCall.fish})
        if test -n "$__git_dirty_state"
          printf '%b' "-"
          printf '%s' "$__git_dirty_state"
        end
      ''
    else if renderer.shell == "nushell" then
      ''
        let __git_dirty_state = (${gitRepoState.dirtyStateFunctionName})
        if ($__git_dirty_state != "") {
          print --no-newline "-"
          print --no-newline $__git_dirty_state
        }
      ''
    else
      ''
        __git_dirty_state="$(${gitRepoState.dirtyStateCall.posix})"
        if [[ -n "$__git_dirty_state" ]]; then
          printf '%b' "-"
          printf '%s' "$__git_dirty_state"
        fi
        unset __git_dirty_state
      '';
in
{
  contentPosix = ''
    ${gitRepoState.revisionFunction.posix}
    ${gitRepoState.dirtyStateFunction.posix}

    printf '%s' "git-"
    ${gitRepoState.revisionCall.posix}
    ${dirtySuffix}
  '';

  contentFish = ''
    ${gitRepoState.revisionFunction.fish}
    ${gitRepoState.dirtyStateFunction.fish}

    printf '%s' "git-"
    ${gitRepoState.revisionCall.fish}
    ${dirtySuffix}
  '';

  contentNu = ''
    ${gitRepoState.revisionFunction.nushell}
    ${gitRepoState.dirtyStateFunction.nushell}

    print --no-newline "git-"
    ${gitRepoState.revisionCall.nushell}
    ${dirtySuffix}
  '';
}
