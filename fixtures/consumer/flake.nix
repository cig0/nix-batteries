/*
  A standalone consumer with only a sidecar input.

  The smoke output exercises public helpers without flake-parts in the
  consumer. modules/checks.nix also evaluates this output in the fixture suite.
*/
{
  inputs.sidecar.url = "path:../..";

  outputs =
    { sidecar, ... }:
    let
      helpers = sidecar.sidecarLibs;
      guard = helpers.guardFlakeInput "example" { example.value = 42; };
      gitState = helpers.mkGitRepoState { revisionFunctionName = "consumerRevision"; };
      theme = helpers.themes.resolve {
        name = "nord";
        enableColors = false;
      };
      # Public source paths remain usable by consumers that import directly.
      directGitState = import (helpers.flakeRoot + "/libraries/toolbox/git-repo-state") {
        revisionFunctionName = "consumerRevision";
      };
    in
    {
      smoke =
        assert guard.has;
        assert guard.apply (input: input.value) null == 42;
        assert gitState.revisionCall.posix == "consumerRevision";
        assert gitState == directGitState;
        assert theme.colors == null;
        assert theme.mode.reset == "";
        assert helpers.flakeRoot == sidecar.outPath;
        true;
    };
}
