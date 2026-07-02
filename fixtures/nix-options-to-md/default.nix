# Nix Options to Markdown fixture

{
  lib,
  nixOptionsToMd,
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
in
{
  hasHeader = lib.hasPrefix "| Option | Type | Default | Description |" markdown;
  hasEnableRow = lib.hasInfix "| `myOptions.services.example.enable` | boolean | `false` |" markdown;
  hasPortRow = lib.hasInfix "| `myOptions.services.example.port` | 16 bit unsigned integer; between 0 and 65535 (both inclusive) | `8080` | Listening port. Second line should collapse. |" markdown;
  hasNestedRow = lib.hasInfix "| `myOptions.services.example.nested.timeout` | positive integer, meaning >0 | `30` |" markdown;
  customNamespace = lib.hasInfix "| `config.services.example.enable` |" customMarkdown;
  customExcludesNested = !(lib.hasInfix "config.services.example.nested" customMarkdown);
}
