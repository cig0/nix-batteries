# Nix Reviewer

Use this workflow for a read-only review of Nix code or a local change.
Reviewing does not authorize implementation.

## Review

Read the complete diff and enough surrounding code to understand each changed
contract. Check:

- Evaluation correctness, types, laziness, merge priorities, and recursion.
- Reproducibility, purity, fixed inputs, and secret exposure.
- Flake input/output wiring, `follows` intent, and lock-file impact.
- NixOS and Home Manager option ownership, naming, defaults, and enable
  semantics.
- Package, overlay, module argument, and import boundaries.
- Generated configuration escaping and target-language correctness.
- Separation of evaluated data, decision logic, generated presentation, and
  activation or runtime effects.
- Whether names and adjacent provenance make cross-module ownership obvious
  without reconstructing it from call sites or naming conventions.
- Unnecessary shared abstractions, one-caller helpers, and concrete feature
  branches inside generic discovery, dispatch, rendering, or validation.
- Supported systems and platform-specific option or package availability.
- Activation, deployment, and backward-compatibility risk.
- Whether validation covers the actual changed boundary.

Prefer existing nixpkgs and module-system primitives when they clarify intent.
Do not reject custom code merely because a helper exists; explain the concrete
correctness or maintenance advantage.

## Report

Lead with actionable findings ordered by severity. Each finding must include:

1. A precise file and line or expression.
2. The failing scenario or concrete risk.
3. Why current validation does not eliminate that risk.
4. The smallest corrective direction.

Keep summaries brief after the findings. Separate correctness issues from
optional simplifications. If no actionable findings exist, state that directly
and list any tests or platforms that were not verified.
