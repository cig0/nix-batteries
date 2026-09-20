/*
  === Modulette ===

  Lightweight Nix module discovery — Modulon's data-oriented sibling.

  Where Modulon discovers NixOS/HM modules (with options/config blocks),
  Modulette discovers data-only modules validated by header conventions.
  Both scan directories and import files, but Modulette skips the module
  system entirely — it validates first-line headers and returns attrsets.

  Exports:

    hasValidHeader    — exact first-line match (string or list of strings)
    hasHeaderPrefix   — prefix match (allows comments after the header)
    discoverModules   — scan directory, filter by header, import, collect

  Modes:

    "flat"       — scan .nix files directly inside the directory (original
                   behavior). Keys by filename without extension.
    "directory"  — scan subdirectories inside the directory. Each
                   subdirectory is treated as a named entry; the file
                   specified by targetFile (default: "host.nix") inside
                   each subdirectory is imported. Keys by directory name.

  Usage — flat mode:

    let modulette = import ./path/to/modulette { inherit lib; };
    in modulette.discoverModules {
      mode = "flat";
      directory = ./my-data-modules;
      headerPrefix = "# My data module.";
      args = { inherit color; };
      exclude = [ "default.nix" ];
    }

  Usage — directory mode:

    let modulette = import ./path/to/modulette { inherit lib; };
    in modulette.discoverModules {
      mode = "directory";
      directory = ./hosts;
      targetFile = "host.nix";
      args = { inherit inputs; };
    }
*/
{ lib }:
let
  /*
    Check whether a file's first line matches a header string or list of strings.
    Used by command modules where the header must match exactly.

    Type: hasValidHeader :: string | [string] -> path -> bool
  */
  hasValidHeader =
    headerText: file:
    let
      content = builtins.readFile file;
      firstLine = builtins.head (builtins.split "\n" content);
      headers = if builtins.isList headerText then headerText else [ headerText ];
    in
    builtins.any (h: firstLine == h) headers;

  /*
    Check whether a file's first line starts with the given prefix.
    More permissive than hasValidHeader — allows additional text after
    the prefix (e.g. "# Theme module. Nushell-inspired color scheme.").

    Type: hasHeaderPrefix :: string -> path -> bool
  */
  hasHeaderPrefix =
    prefix: file:
    let
      firstLine = builtins.head (builtins.split "\n" (builtins.readFile file));
    in
    builtins.substring 0 (builtins.stringLength prefix) firstLine == prefix;

  /*
    Validate a file's first line against headerText or headerPrefix.
    Returns true when no header validation is requested (both null).
    Resolves the file path differently depending on isDirectory:
      flat mode       — directory + "/" + entryName
      directory mode  — directory + "/" + entryName + "/" + targetFile
  */
  isValidHeader =
    {
      directory, # discoverModules → scan root
      entryName, # discoverModules → file or subdirectory name
      headerText ? null, # discoverModules → exact first-line contract
      headerPrefix ? null, # discoverModules → first-line prefix contract
      isDirectory ? false, # discoverModules → directory-mode flag
      targetFile ? "host.nix", # discoverModules → directory-mode import target
    }:
    let
      filePath =
        if isDirectory then directory + "/${entryName}/${targetFile}" else directory + "/${entryName}";
    in
    if headerText != null then
      hasValidHeader headerText filePath
    else if headerPrefix != null then
      hasHeaderPrefix headerPrefix filePath
    else
      true;

  /*
    Scan a directory and collect modules into an attrset.

    Flat mode (mode = "flat"):
      Scans for .nix files directly inside the directory, validates
      optional headers, imports matching files with args, and returns
      an attrset keyed by filename (without .nix extension).

    Directory mode (mode = "directory"):
      Scans for subdirectories inside the directory, validates
      optional headers on the target file inside each subdirectory,
      imports matching files with args, and returns an attrset
      keyed by directory name.

    Parameters:
      mode          — "flat" or "directory" (required, no default)
      directory     — path to scan (required)
      args          — attrset passed to each imported module (default: { })
      exclude       — names to skip: filenames in flat mode, directory
                      names in directory mode (default: [ ])
      headerPrefix  — prefix that the first line must start with
      headerText    — exact first-line string (or list of strings) to match
      targetFile    — filename to import inside each subdirectory in
                      directory mode (default: "host.nix")

    Type: discoverModules ::
      { mode :: "flat" | "directory"
      , directory :: path
      , args ? {}
      , exclude ? [string]
      , headerPrefix ? null
      , headerText ? null
      , targetFile ? string
      } -> attrset
  */
  discoverModules =
    {
      args ? { }, # caller args → forwarded module arguments
      directory, # caller args → scan root
      exclude ? [ ], # caller args → names to skip
      headerPrefix ? null, # caller args → first-line prefix contract
      headerText ? null, # caller args → exact first-line contract
      mode, # caller args → flat or directory discovery
      targetFile ? "host.nix", # caller args → directory-mode import target
    }:
    let
      entryTypes = builtins.readDir directory;
      entries = builtins.attrNames entryTypes;

      result =
        if mode == "flat" then
          let
            nixFiles = builtins.filter (
              name: entryTypes.${name} == "regular" && lib.hasSuffix ".nix" name
            ) entries;
            candidateFiles = builtins.filter (name: !(builtins.elem name exclude)) nixFiles;
            validFiles = builtins.filter (
              name:
              isValidHeader {
                inherit directory headerText headerPrefix;
                entryName = name;
              }
            ) candidateFiles;
            keyFromName = name: builtins.substring 0 (builtins.stringLength name - 4) name;
          in
          builtins.foldl' (a: b: a // b) { } (
            map (name: {
              ${keyFromName name} = import (directory + "/${name}") args;
            }) validFiles
          )

        else if mode == "directory" then
          let
            dirEntries = builtins.attrNames (builtins.filterAttrs (_: type: type == "directory") entryTypes);
            candidateDirs = builtins.filter (name: !(builtins.elem name exclude)) dirEntries;
            validDirs = builtins.filter (
              name:
              let
                targetPath = directory + "/${name}/${targetFile}";
              in
              # Fail with the missing-entry context instead of a bare import or
              # read error when a scanned subdirectory has no target file.
              assert lib.assertMsg (builtins.pathExists targetPath)
                "Modulette: directory '${name}' has no '${targetFile}' to import (mode = \"directory\")";
              isValidHeader {
                inherit
                  directory
                  headerText
                  headerPrefix
                  targetFile
                  ;
                entryName = name;
                isDirectory = true;
              }
            ) candidateDirs;
          in
          builtins.foldl' (a: b: a // b) { } (
            map (name: {
              ${name} = import (directory + "/${name}/${targetFile}") args;
            }) validDirs
          )

        else
          throw "Modulette: mode must be \"flat\" or \"directory\", got \"${mode}\"";
    in
    result;
in
{
  inherit
    discoverModules
    hasHeaderPrefix
    hasValidHeader
    ;
}
