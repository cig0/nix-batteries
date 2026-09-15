# Git-state generator and its default payload → the two public Git helpers.
{ ... }:
let
  mkGitRepoState = args: import ../../libraries/toolbox/git-repo-state args;
in
{
  flake.sidecarLibs = {
    inherit mkGitRepoState;
    gitRepoState = mkGitRepoState { };
  };
}
