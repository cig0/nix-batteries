# Option catalogue

Pure metadata projection and queries for evaluated Nix module options. The
caller supplies its evaluation library, option trees, and supplier membership.
This first implementation is available by direct import; the public flake export
and check registration are a separate migration phase.

```text
caller evaluation.options -> project -> metadata lists
named supplier lists + selection -> list
complete metadata list + exact displayed name -> describe
```

## Operations

`import ./default.nix { inherit lib; }` returns:

- `project options`: public metadata from an evaluated option tree. Hidden and
  internal options, including descendants of internal parents, are excluded.
- `list { allOptions; optionsBySource ? {}; sources ? null; prefix ? ""; }`:
  select metadata by supplier and literal displayed-name prefix. Null sources
  selects the complete list; an empty list selects nothing. Named suppliers are
  visited in sorted order, retaining their record order. Repeated source names
  and identical records at the same path are deduplicated. Conflicting records
  for one path fail with their supplier names, including duplicates within one
  supplied list.
- `describe { allOptions; name; }`: one record or null if absent. More than one
  matching displayed name is an error. It does not depend on listing policy.

Metadata records contain exactly `name`, `path`, `type`, `description`,
`declarations`, and `readOnly`. Type and description may be null; missing
declaration locations are an empty list. Names and path components come from
Nix's evaluated declarations, preserving quoted attribute names. Descriptions
remain literal data; renderers own colors, escaping, and formatting. This version
requires descriptions to be strings or null; legacy structured `mdDoc` values
are unsupported and rejected by queries. It does not promise compatibility with
every historical nixpkgs documentation helper.

## Evaluation boundary

The library reads declaration metadata, excluding defaults, examples, and
effective values. It uses the supplied library's `optionAttrSetToDocList` for
submodule traversal. Custom option types can still evaluate their suboption
schema; metadata projection is not a zero-cost operation. Internal-parent
suppression traverses the selected tree's option paths and visibility flags;
queries do not require nonmatching descriptions or types.

Supplier entries are lazy lists from `project`. Selecting one supplier does not
read the complete catalogue or other supplier lists. Listing supplier names
uses `builtins.attrNames optionsBySource` without projecting them. Prefix and
exact-name queries traverse names but do not read nonmatching descriptions or
types. Only matching records are validated; records with extra fields are
rejected rather than exposing values outside the metadata contract.

All supplied trees belong to the same evaluation. The caller preserves their
original paths and any option-valued ancestors governing visibility. Evaluated
options and subtrees retain their own `loc`; extracting children must not bypass
an ancestor's visibility. A whole branch under ordinary attribute groups can be
retained without renaming:

```nix
let
  catalogue = import ./default.nix { inherit lib; };
  allOptions = catalogue.project evaluated.options;
  optionsBySource.editor = catalogue.project {
    programs.editor = evaluated.options.programs.editor;
  };
in
catalogue.list {
  inherit allOptions optionsBySource;
  sources = [ "editor" ];
}
```

Here `evaluated` is caller-owned and `editor` is an illustrative supplier name.
Supplier labels describe the caller's chosen interfaces, not exclusive file
authorship. Actual declaration locations remain in each record. Input discovery,
module evaluation, ownership attribution, host policy, serialization, and command
execution stay with the consumer. Unsupported argument shapes, missing suppliers,
and malformed selected records raise Nix errors.

[Focused fixture](../../../fixtures/option-catalogue/default.nix) covers metadata,
visibility, lazy selection, overlap, and failures without a consumer repository.
