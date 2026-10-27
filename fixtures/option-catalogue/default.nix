/*
  Direct library import + synthetic evalModules declarations → public behavior.
  Throwing unused values make accidental evaluation observable without hosts,
  packages, or a consumer flake.
*/
{ lib, optionCatalogue }:
let
  catalogue = optionCatalogue { inherit lib; };
  childSchema = lib.types.submodule {
    options.child = lib.mkOption {
      type = lib.types.str;
      description = "Child documentation";
    };
  };
  evaluated = lib.evalModules {
    modules = [
      {
        options.demo = {
          visible = lib.mkOption {
            type = lib.types.str;
            description = "Literal \\n and $(not-a-command).";
            default = throw "forced default";
            example = throw "forced example";
          };
          hidden = lib.mkOption {
            type = childSchema;
            visible = false;
          };
          shallow = lib.mkOption {
            type = childSchema;
            visible = "shallow";
          };
          transparent = lib.mkOption {
            type = childSchema;
            visible = "transparent";
          };
          internal = lib.mkOption {
            type = childSchema;
            internal = true;
          };
          "bar.baz" = lib.mkOption { type = lib.types.str; };
          nullType = lib.mkOption {
            type = lib.types.str // {
              description = null;
            };
          };
          readOnly = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
        };
        config.demo.visible = throw "forced effective value";
      }
      {
        _file = "fixture/first.nix";
        options.demo.named = lib.mkOption { type = lib.types.str; };
      }
      {
        _file = "fixture/second.nix";
        options.demo.named = lib.mkOption { description = "Declared twice"; };
      }
    ];
  };
  allOptions = catalogue.project evaluated.options;
  names = options: map (option: option.name) options;
  allNames = names allOptions;
  describe = name: catalogue.describe { inherit allOptions name; };
  visible = describe "demo.visible";
  named = describe "demo.named";
  quoted = describe ''demo."bar.baz"'';
  fails = result: !(builtins.tryEval (builtins.deepSeq result true)).success;
  optionsBySource = {
    alpha = [
      visible
      named
    ];
    beta = [
      named
      quoted
    ];
    broken = throw "forced unrelated supplier";
  };
  selected =
    sources:
    catalogue.list {
      inherit optionsBySource sources;
      allOptions = throw "forced full catalogue during supplier query";
    };
  unknownSource = catalogue.list {
    inherit optionsBySource;
    allOptions = throw "forced unused catalogue";
    sources = [
      "missing"
      "broken"
    ];
  };
  unrelated = quoted // {
    description = throw "forced unrelated description";
    type = throw "forced unrelated type";
  };
in
{
  visible = builtins.elem "demo.visible" allNames;
  hidden = !(builtins.elem "demo.hidden" allNames || builtins.elem "demo.hidden.child" allNames);
  shallow = builtins.elem "demo.shallow" allNames && !(builtins.elem "demo.shallow.child" allNames);
  transparent =
    !(builtins.elem "demo.transparent" allNames) && builtins.elem "demo.transparent.child" allNames;
  internal =
    !(builtins.elem "demo.internal" allNames || builtins.elem "demo.internal.child" allNames);
  quotedPath =
    quoted.path == [
      "demo"
      "bar.baz"
    ];
  missingDescription = quoted.description == null;
  nullType = (describe "demo.nullType").type == null;
  readOnly = (describe "demo.readOnly").readOnly;
  unknownDeclarations = visible.declarations == [ ];
  multipleDeclarations =
    lib.sort builtins.lessThan named.declarations == [
      "fixture/first.nix"
      "fixture/second.nix"
    ];
  projectionDoesNotReadValues = (builtins.tryEval (builtins.deepSeq allOptions true)).success;
  plainMetadata = visible.description == "Literal \\n and $(not-a-command).";
  completeListing = catalogue.list { inherit allOptions; } == allOptions;
  missingOption = describe "demo.absent" == null;
  quotedLookupIsExact = describe "demo.bar.baz" == null;
  serializedMetadataBoundary =
    catalogue.describe {
      allOptions = builtins.fromJSON (
        builtins.toJSON (
          catalogue.list {
            inherit allOptions;
            prefix = "demo.visible";
          }
        )
      );
      name = "demo.visible";
    } == visible;
  emptyDescriptionLookup =
    catalogue.describe {
      allOptions = [ ];
      name = "missing";
    } == null;
  enumDoesNotProject =
    builtins.attrNames optionsBySource == [
      "alpha"
      "beta"
      "broken"
    ];
  selectedSourceOnly =
    selected [ "alpha" ] == [
      visible
      named
    ];
  emptySelection =
    catalogue.list {
      allOptions = throw "forced full catalogue with empty selection";
      optionsBySource = throw "forced suppliers with empty selection";
      sources = [ ];
    } == [ ];
  completeIgnoresSuppliers =
    catalogue.list {
      inherit allOptions;
      optionsBySource = throw "forced suppliers during complete listing";
    } == allOptions;
  stableSourceOrderAndOverlap =
    selected [
      "beta"
      "alpha"
      "beta"
    ] == [
      visible
      named
      quoted
    ];
  repeatedSourceNames =
    selected [
      "alpha"
      "alpha"
    ] == selected [ "alpha" ];
  duplicatesWithinCompleteList =
    catalogue.list {
      allOptions = [
        quoted
        visible
        quoted
        named
        visible
      ];
    } == [
      quoted
      visible
      named
    ];
  duplicatesWithinOneSupplier =
    catalogue.list {
      allOptions = throw "forced full catalogue during duplicate check";
      optionsBySource.one = [
        quoted
        visible
        quoted
        named
        visible
      ];
      sources = [ "one" ];
    } == [
      quoted
      visible
      named
    ];
  rejectsConflictWithinCompleteList = fails (
    catalogue.list {
      allOptions = [
        visible
        (visible // { description = "different"; })
      ];
    }
  );
  rejectsConflictWithinOneSupplier = fails (
    catalogue.list {
      allOptions = throw "forced full catalogue during conflict check";
      optionsBySource.one = [
        visible
        (visible // { description = "different"; })
      ];
      sources = [ "one" ];
    }
  );
  rejectsLegacyStructuredDescription = fails (
    catalogue.list {
      allOptions = [
        (
          visible
          // {
            description = {
              _type = "mdDoc";
              text = "Legacy";
            };
          }
        )
      ];
    }
  );
  pathComponentsDoNotCollide =
    let
      nested = quoted // {
        name = "demo.bar.baz";
        path = [
          "demo"
          "bar"
          "baz"
        ];
      };
    in
    catalogue.list {
      allOptions = [
        quoted
        nested
      ];
    } == [
      quoted
      nested
    ];
  rejectsUnknownSource = fails unknownSource;
  rejectsFailedSelectedSource = fails (selected [ "broken" ]);
  rejectsConflictingOverlap = fails (
    catalogue.list {
      inherit allOptions;
      optionsBySource = {
        alpha = [ named ];
        beta = [ (named // { description = "different"; }) ];
      };
      sources = [
        "alpha"
        "beta"
      ];
    }
  );
  prefixDoesNotReadUnmatchedMetadata =
    catalogue.list {
      allOptions = [
        unrelated
        visible
      ];
      prefix = "demo.visible";
    } == [ visible ];
  exactLookupDoesNotReadUnmatchedMetadata =
    catalogue.describe {
      allOptions = [
        unrelated
        visible
      ];
      name = "demo.visible";
    } == visible;
  literalPrefix =
    catalogue.list {
      inherit allOptions;
      prefix = ''demo."bar.'';
    } == [ quoted ];
  rejectsAmbiguousDescription = fails (
    catalogue.describe {
      allOptions = [
        visible
        visible
      ];
      name = "demo.visible";
    }
  );
  rejectsExtraMetadata = fails (
    catalogue.list { allOptions = [ (visible // { value = "secret"; }) ]; }
  );
  rejectsInvalidDescription = fails (
    catalogue.describe {
      allOptions = [ (visible // { description = 42; }) ];
      name = "demo.visible";
    }
  );
  rejectsMalformedName = fails (catalogue.list { allOptions = [ { name = 42; } ]; });
  rejectsNonListCatalogue = fails (catalogue.list { allOptions = { }; });
  rejectsNonListSupplier = fails (
    catalogue.list {
      allOptions = [ ];
      optionsBySource.bad = { };
      sources = [ "bad" ];
    }
  );
  rejectsInvalidSourceSelection = fails (selected "alpha");
  rejectsInvalidSourceName = fails (selected [ 1 ]);
  rejectsInvalidPrefix = fails (
    catalogue.list {
      allOptions = [ ];
      prefix = 1;
    }
  );
  rejectsInvalidLookupName = fails (
    catalogue.describe {
      allOptions = [ ];
      name = 1;
    }
  );
  evaluatedOptionKeepsNames = catalogue.project evaluated.options.demo.visible == [ visible ];
  evaluatedSubmoduleKeepsVisibility =
    names (catalogue.project evaluated.options.demo.shallow) == [ "demo.shallow" ];
  evaluatedSubtreeKeepsNames =
    catalogue.project evaluated.options.demo
    == lib.filter (option: builtins.head option.path == "demo") allOptions;
  rootedSupplierKeepsNames =
    catalogue.project {
      demo.visible = evaluated.options.demo.visible;
    } == [ visible ];
}
