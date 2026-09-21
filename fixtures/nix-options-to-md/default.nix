# Nix Options to Markdown fixture

{
  lib, # fixtures/default.nix → nixpkgs.lib
  nixOptionsToMd, # fixtures/default.nix → batteriesLib.nixOptionsToMd
}:

let
  options = {
    services = {
      example = {
        enable = lib.mkEnableOption "the example service";
        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = ''
            Listening port.
            Second line should collapse.
          '';
        };
        nested = {
          timeout = lib.mkOption {
            type = lib.types.ints.positive;
            default = 30;
          };
        };
        mode = lib.mkOption {
          type = lib.types.str;
          default = "fast";
        };
      };
    };
  };

  docs = nixOptionsToMd {
    inherit lib options;
    namespace = "myOptions";
  };

  markdown = docs.markdown docs.allEntries;
  customMarkdown = docs.markdownForNamespace {
    newNamespace = "config";
    includeHeader = true;
    exclude = [ "services.example.nested" ];
  };
  edgeDocs = nixOptionsToMd {
    inherit lib;
    namespace = "edge|`";
    options = {
      untyped = lib.mkOption { default = 1; };
      expression = lib.mkOption { defaultText = lib.literalExpression "pkgs.`a``|b`"; };
      special = lib.mkOption {
        type = {
          description = "a|b";
        };
        default = "a|b``c\n";
        description = lib.literalMD "line one|two\nline three";
      };
      unsupported = lib.mkOption { default = _: null; };
      storeValue = lib.mkOption {
        default = {
          type = "derivation";
          outPath = "/nix/store/fixture";
          unused = _: null;
        };
      };
      spaces = lib.mkOption { default = "two  spaces"; };
    };
  };
  edgeMarkdown = edgeDocs.markdownForNamespace {
    newNamespace = "edge|`";
    exclude = [ "unsupported" ];
  };
  unsupported = builtins.tryEval (builtins.deepSeq (edgeDocs.markdown edgeDocs.allEntries) true);
in
{
  missingType = lib.hasInfix "untyped`` | unknown | `1` |" edgeMarkdown;
  literalExpression = lib.hasInfix "``` pkgs.`a``\\|b` ```" edgeMarkdown;
  controlCharacters = lib.hasInfix "| a\\|b | ```\"a\\|b``c\\n\"``` | line one\\|two line three |" edgeMarkdown;
  escapedNamespace = lib.hasInfix "``edge\\|`.special``" edgeMarkdown;
  rejectsUnsupportedDefault = !unsupported.success;
  preservesStoreValue = lib.hasInfix "`\"/nix/store/fixture\"`" edgeMarkdown;
  preservesLiteralSpaces = lib.hasInfix "`\"two  spaces\"`" edgeMarkdown;
  hasHeader = lib.hasPrefix "| Option | Type | Default | Description |" markdown;
  hasEnableRow = lib.hasInfix "| `myOptions.services.example.enable` | boolean | `false` |" markdown;
  hasPortRow = lib.hasInfix "| `myOptions.services.example.port` | 16 bit unsigned integer; between 0 and 65535 (both inclusive) | `8080` | Listening port. Second line should collapse. |" markdown;
  hasNestedRow = lib.hasInfix "| `myOptions.services.example.nested.timeout` | positive integer, meaning >0 | `30` |" markdown;
  # String literals keep their quotes, matching nixpkgs option-doc rendering.
  hasStringDefaultRow = lib.hasInfix "| `myOptions.services.example.mode` | string | `\"fast\"` |" markdown;
  customNamespace = lib.hasInfix "| `config.services.example.enable` |" customMarkdown;
  customExcludesNested = !(lib.hasInfix "config.services.example.nested" customMarkdown);
}
