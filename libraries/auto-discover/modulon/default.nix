/*
  Modulon Nix-module collector.

  Callers provide module directories and explicit additions; this library
  returns candidate paths without evaluating them. The module system validates
  imports; Modulette owns passive data-module discovery.
*/
{ lib }:
{
  dirs ? [ ], # caller args → module directories
  excludePaths ? [ ], # caller args → relative path components to skip
  discoveryMode ? "heuristic", # compatibility default; "modules" requires module-only roots
  extraModules ? [ ], # caller args → explicit module additions
  ...
}:
let
  # Filenames to exclude automatically (exact match)
  excludeFilenames = [
    "configuration.nix"
    "flake.nix"
    "hardware-configuration.nix"
    "home.nix"
  ];

  # Directory components below each scan root; ancestors never affect discovery.
  defaultExcludePaths = [
    ".git/"
    "/tests/"
  ];

  # Heuristic patterns to identify potential Nix modules based on content.
  # This is not foolproof but helps filter out non-module .nix files.
  modulePatterns = [
    "... }:"
    "}:"
    "config,"
    "lib,"
    "inputs,"
    "nixosConfig,"
    "pkgs,"
    "config = {"
    "home = {"
    "imports = ["
    "options."
  ];

  # Normalize legacy boundary slashes, but never restore absolute substring matching.
  exclusionComponents = map (
    pattern:
    let
      components = builtins.filter (part: part != "") (lib.splitString "/" pattern);
    in
    if
      components == [ ]
      || builtins.any (
        part:
        builtins.elem part [
          "."
          ".."
        ]
      ) components
    then
      throw "Modulon: excludePaths must contain nonempty relative path components"
    else
      components
  ) (defaultExcludePaths ++ excludePaths);

  # A pattern matches consecutive whole components at any depth below the root.
  containsComponents =
    pattern: components:
    lib.take (builtins.length pattern) components == pattern
    || (components != [ ] && containsComponents pattern (builtins.tail components));

  matchesModuleHeuristics =
    content:
    builtins.length (builtins.filter (pattern: lib.hasInfix pattern content) modulePatterns) >= 2;

  collectModules =
    {
      dir,
    }:
    let
      isExcludedPath =
        components: builtins.any (pattern: containsComponents pattern components) exclusionComponents;

      includeCandidate =
        file:
        let
          content = builtins.readFile file;
        in
        !(lib.hasInfix "@MODULON_SKIP" content)
        && (discoveryMode == "modules" || matchesModuleHeuristics content);

      # Recursively collect .nix files from a directory
      collectModulesRec =
        path: relativeComponents:
        let
          items = builtins.readDir path; # Read the directory contents

          processItem =
            name: type:
            let
              fullPath = path + "/${name}";
              components = relativeComponents ++ [ name ];
            in
            if isExcludedPath components then
              [ ]
            else if type == "regular" && lib.hasSuffix ".nix" name && !(lib.elem name excludeFilenames) then
              lib.optional (includeCandidate fullPath) fullPath
            else if type == "directory" then
              collectModulesRec fullPath components
            else
              [ ]; # Ignore other file types

          itemLists = lib.mapAttrsToList processItem items;
        in
        builtins.concatLists itemLists;
    in
    assert lib.assertMsg (builtins.pathExists dir)
      "Modulon: Directory '${toString dir}' does not exist";
    collectModulesRec dir [ ];
in
assert lib.assertMsg (builtins.elem discoveryMode [
  "heuristic"
  "modules"
]) "Modulon: discoveryMode must be heuristic or modules";
{
  # The final list of module paths to be imported
  imports =
    # Map over each directory and collect modules (already flattened)
    lib.concatMap (dir: collectModules { inherit dir; }) dirs
    # Append any explicitly provided extra modules
    ++ extraModules;
}
