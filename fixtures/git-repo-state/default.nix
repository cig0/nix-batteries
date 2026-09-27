# Runtime contracts for literal labels, clean/dirty state, and Git failures.
{
  batteriesLib,
  lib,
  pkgs,
}:
let
  label = "cost $5 $(touch EXPANDED) `touch EXPANDED` 'quoted' \"double\" back\\slash\tend\nnext\n";
  helpers = batteriesLib.mkGitRepoState {
    unknownRevisionText = label;
    dirtyStateText = label;
  };
  expected = pkgs.writeText "git-state-label" label;
  posix = pkgs.writeText "git-state-runtime.sh" ''
    set -u
    ${helpers.revisionFunction.posix}
    ${helpers.dirtyStateFunction.posix}
    # Set after shell startup, which may otherwise override caller environment.
    export GIT_REPO_PATH="$1"
    if [ "$2" = unavailable ]; then PATH=/nonexistent; fi
    if [ "$2" = revision ]; then _gitRevision; else _gitDirtyState; fi
  '';
  fish = pkgs.writeText "git-state-runtime.fish" ''
    ${helpers.revisionFunction.fish}
    ${helpers.dirtyStateFunction.fish}
    set -gx GIT_REPO_PATH "$argv[1]"
    if test "$argv[2]" = unavailable
      set -gx PATH /nonexistent
    end
    if test "$argv[2]" = revision
      _gitRevision
    else
      _gitDirtyState
    end
  '';
  nu = pkgs.writeText "git-state-runtime.nu" ''
    ${helpers.revisionFunction.nushell}
    ${helpers.dirtyStateFunction.nushell}
    def main [repository: string, mode: string] {
      $env.GIT_REPO_PATH = $repository
      if $mode == "unavailable" { $env.PATH = [] }
      if $mode == "revision" {
        ${helpers.revisionCall.nushell}
      } else {
        ${helpers.dirtyStateCall.nushell}
      }
    }
  '';
  invalidArgs = [
    { revisionFunctionName = "bad-name"; }
    { dirtyStateFunctionName = "x; touch BAD"; }
    { revisionFunctionName = "if"; }
    { revisionFunctionName = "printf"; }
    { repositoryPathEnvVar = "BAD-NAME"; }
    {
      revisionFunctionName = "same";
      dirtyStateFunctionName = "same";
    }
  ];
in
assert builtins.all (
  args: !(builtins.tryEval (batteriesLib.mkGitRepoState args)).success
) invalidArgs;
pkgs.runCommand "nix-batteries-git-state-runtime"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.coreutils
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" repo nonrepo
    git --no-pager -C repo init --quiet
    git --no-pager -C repo -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet --allow-empty -m initial
    git --no-pager -C repo rev-parse --short HEAD | tr -d '\n' > revision.expected
    repository="$PWD/repo"

    check_shell() {
      runtime="$1"
      source="$2"
      "$runtime" "$source" "$repository" revision > actual
      cmp revision.expected actual
      "$runtime" "$source" "$repository" dirty > actual
      test ! -s actual
      touch repo/untracked
      "$runtime" "$source" "$repository" dirty > actual
      cmp ${expected} actual
      rm repo/untracked
      for path in "$PWD/missing" "$PWD/nonrepo"; do
        "$runtime" "$source" "$path" revision > actual
        cmp ${expected} actual
        if "$runtime" "$source" "$path" dirty > actual 2> failure; then
          echo "Git failure incorrectly reported success: $runtime" >&2
          exit 1
        fi
        test ! -s actual
        test -s failure
      done
      if "$runtime" "$source" "$repository" unavailable > actual 2> failure; then
        echo "Missing Git incorrectly reported success: $runtime" >&2
        exit 1
      fi
      test ! -e EXPANDED
    }

    check_shell ${pkgs.bash}/bin/bash ${posix}
    check_shell ${pkgs.zsh}/bin/zsh ${posix}
    check_shell ${pkgs.dash}/bin/dash ${posix}
    check_shell ${pkgs.fish}/bin/fish ${fish}
    check_shell ${pkgs.nushell}/bin/nu ${nu}
    touch "$out"
  ''
