# Nix Flake Architect

Use this workflow for architecture analysis, ownership decisions, flake output
design, or a requested structural migration. Do not turn a focused code change
into a repository redesign.

## Analyze

1. Identify supported systems, host types, users, deployment paths, and
   compatibility constraints.
2. Map flake inputs to outputs and trace how modules receive inputs and custom
   arguments.
3. Identify ownership boundaries among hosts, NixOS, Home Manager, packages,
   overlays, libraries, dev shells, and passive data.
4. Evaluate module discovery, import direction, option namespaces, channel
   strategy, and lock-file consequences.
5. Distinguish current problems supported by evidence from hypothetical future
   needs.
6. Identify the extension boundary and the generic files that an ordinary new
   module, provider, or registry entry should not need to modify.

Use `follows` when inputs are intentionally required to share a dependency and
compatibility set. Do not apply it mechanically when independent pinning is
part of the contract.

## Propose

Provide:

1. Current constraints and verified problems.
2. The smallest target structure that resolves them.
3. Data and control flow across the proposed boundaries.
4. A staged migration that keeps evaluation working at each step.
5. Compatibility, lock, platform, and validation implications.
6. A non-change budget that makes feature leakage into generic infrastructure
   visible during review.

Prefer explicit imports and visible ownership over generic loaders or framework
code unless the repository already uses such a system or repeated complexity
justifies it.
