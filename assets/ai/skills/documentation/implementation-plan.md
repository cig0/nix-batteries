# Implementation Plan Documents

Use this workflow when the user explicitly requests a durable implementation
plan, architecture plan, migration plan, or AI review document. Unlike an
adjacent README, a plan may prescribe future work. It must distinguish verified
current facts from approved decisions, recommendations, and unresolved choices.

## Establish the plan boundary

Before writing:

1. Read the applicable repository instructions and current implementation.
2. Identify the authoritative producers, consumers, public interfaces, and
   compatibility constraints.
3. Record which requested behavior is already approved and which decisions
   still require alignment.
4. Keep speculative future work visibly separate from the implementation being
   planned.

## Required content

Include only sections that materially help implementation or review:

- verified current state and constraints;
- exact target behavior, including important error and empty states;
- ownership and producer-to-consumer data flow;
- separation of data, decision logic, presentation, and side effects;
- small vertical implementation slices;
- the generic infrastructure or public behavior expected to remain unchanged;
- compatibility and migration decisions;
- validation at the actual changed boundaries;
- documentation handoff after behavior is reviewed;
- explicit unresolved questions.

Use concrete paths and examples when they make ownership or grammar
unambiguous. Do not invent files, public APIs, provenance, or validation results
that have not been verified.

## Quality safeguards

- Make each slice independently reviewable and leave the affected system in a
  coherent state.
- State why a shared abstraction is justified. Keep one-consumer logic local
  unless extraction establishes a real ownership boundary.
- For extensible systems, record a non-change budget: ordinary additions should
  not require concrete feature branches in generic discovery, dispatch,
  rendering, completion, or validation.
- Keep assertions semantic. Do not couple them to spacing, colors, headings, or
  other presentation choices.
- Require authoritative provenance from loaders or providers rather than
  reconstructing it from names or paths.
- Use names that declare domain intent in both prose and examples.

## Verify

Before delivery:

1. Re-check every factual claim against the current source.
2. Follow every local link and producer-to-consumer trace.
3. Confirm approved decisions and open questions are not conflated.
4. Confirm the plan does not require unrelated refactors or speculative
   abstractions.
5. Inspect the document diff for stale paths, duplicated guidance, and claims
   that belong in the reusable baseline instead of repository policy.
