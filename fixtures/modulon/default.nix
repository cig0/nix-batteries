{
  batteriesLib,
  lib,
  pass,
}:
let
  discover = directory: extra: batteriesLib.modulon ({ dirs = [ directory ]; } // extra);
  ordinary = discover ./relocation { discoveryMode = "modules"; };
  relocated = discover ./tests/relocation { discoveryMode = "modules"; };
  basenames = result: map builtins.baseNameOf result.imports;
  legacy = discover ./classification { };
  explicit = discover ./classification { discoveryMode = "modules"; };
  evaluated = lib.evalModules {
    modules = [
      ordinary
      { options.fixtureEnabled = lib.mkEnableOption "fixture"; }
    ];
  };
  rejectsNonModule = builtins.tryEval (
    builtins.deepSeq
      (lib.evalModules {
        modules = [ explicit ];
      }).config
      true
  );
in
assert basenames ordinary == [ "plain.nix" ];
assert basenames relocated == basenames ordinary;
assert evaluated.config.fixtureEnabled;
assert !rejectsNonModule.success;
# The compatibility classifier still includes comments and misses plain modules.
assert basenames legacy == [ "comment-only.nix" ];
assert
  basenames explicit == [
    "comment-only.nix"
    "plain.nix"
  ];
assert
  (discover ./relocation {
    discoveryMode = "modules";
    excludePaths = [ "/plain.nix/" ];
  }).imports == [ ];
assert
  basenames (
    discover ./relocation {
      discoveryMode = "modules";
      excludePaths = [ "relocation" ];
    }
  ) == [ "plain.nix" ];
assert basenames (discover ./modules { discoveryMode = "modules"; }) == [ "valid.nix" ];
assert
  basenames (
    discover ./relocation {
      discoveryMode = "modules";
      excludePaths = [ "plain" ];
    }
  ) == [ "plain.nix" ];
assert !(builtins.tryEval (discover ./relocation { discoveryMode = "invalid"; })).success;
assert
  !(builtins.tryEval (
    builtins.deepSeq (discover ./relocation { excludePaths = [ "" ]; }).imports true
  )).success;
pass "nix-batteries-modulon-boundaries"
