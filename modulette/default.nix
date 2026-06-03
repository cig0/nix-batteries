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

  Usage:

    let modulette = import ./path/to/modulette { inherit lib; };
    in modulette.discoverModules {
      directory = ./my-data-modules;
      headerPrefix = "# My data module.";
      args = { inherit color; };
      excludeFiles = [ "default.nix" ];
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
    the prefix (e.g. "# ANSI theme module. Nushell-inspired color scheme.").

    Type: hasHeaderPrefix :: string -> path -> bool
  */
  hasHeaderPrefix =
    prefix: file:
    let
      firstLine = builtins.head (builtins.split "\n" (builtins.readFile file));
    in
    builtins.substring 0 (builtins.stringLength prefix) firstLine == prefix;

  /*
    Scan a directory for .nix files whose first line matches a header
    convention, import them with the given args, and collect results into
    an attrset keyed by filename (without .nix extension).

    Supports both exact header matching (headerText) and prefix matching
    (headerPrefix). Use headerText for strict validation, headerPrefix
    for permissive matching.

    Parameters:
      args         — attrset passed to each imported module (default: { })
      directory    — path to scan for .nix files
      excludeFiles — list of filenames to skip (default: [ ])
      headerPrefix — prefix that the first line must start with
      headerText   — exact first-line string (or list of strings) to match

    Type: discoverModules ::
      { directory :: path
      , args ? {}
      , excludeFiles ? [string]
      , headerPrefix ? null
      , headerText ? null
      } -> attrset
  */
  discoverModules =
    {
      args ? { },
      directory,
      excludeFiles ? [ ],
      headerPrefix ? null,
      headerText ? null,
    }:
    let
      candidateFiles = builtins.filter (name: !(builtins.elem name excludeFiles)) nixFiles;
      entries = builtins.attrNames (builtins.readDir directory);
      nixFiles = builtins.filter (lib.hasSuffix ".nix") entries;

      isValid =
        if headerText != null then
          name: hasValidHeader headerText (directory + "/${name}")
        else if headerPrefix != null then
          name: hasHeaderPrefix headerPrefix (directory + "/${name}")
        else
          _: true;

      validFiles = builtins.filter (name: isValid name) candidateFiles;
      keyFromName = name: builtins.substring 0 (builtins.stringLength name - 4) name;

      loadModule = name: {
        ${keyFromName name} = import (directory + "/${name}") args;
      };
    in
    builtins.foldl' (a: b: a // b) { } (map loadModule validFiles);
in
{
  inherit
    discoverModules
    hasHeaderPrefix
    hasValidHeader
    ;
}
