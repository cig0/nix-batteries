{
  description = "Ignite - A Nix flake toolkit with reusable building blocks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, self }:
    let
      flakeRoot = self.outPath;
      lib = nixpkgs.lib;
    in
    {
      lib = rec {
        inherit flakeRoot;

        guardFlakeInput = import "${flakeRoot}/guard-flake-input" { inherit lib; };
        mkGitRepoState = args: import (flakeRoot + "/toolbox/git-repo-state") args;
        gitRepoState = mkGitRepoState { };
        gitRepoStateRenderer = {
          raw = import (flakeRoot + "/toolbox/git-repo-state-renderer");
          decorated = import (flakeRoot + "/toolbox/git-repo-state-renderer/decorated.nix");
        };
        helpLegendDecorator = import "${flakeRoot}/decorators/help-legend" { };
        modulette = import "${flakeRoot}/modulette" { inherit lib; };
        modulon = collectorArgs: import "${flakeRoot}/modulon" { inherit lib; } collectorArgs;
        themes = import "${flakeRoot}/themes/palette.nix" { inherit flakeRoot lib; };
      };
    };
}
