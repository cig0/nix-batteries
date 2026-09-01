# Nix Debugger

Use this workflow to diagnose a Nix failure or an unexpected evaluation result.
Diagnosis does not authorize implementation unless the user also asks for a
fix.

## Establish the failure

1. Read the complete command, error output, and relevant code.
2. Reproduce with the narrowest read-only command when practical.
3. Classify the failing phase: parsing, evaluation, module merge, flake wiring,
   derivation realization, or activation.
4. Trace the failing value from producer to consumer. Inspect actual flake
   outputs and option definitions instead of inferring their shape from names.
5. Reduce the case until one expression, option, input, or boundary explains
   the observed error.

Check common distinctions explicitly:

- Undefined variable versus missing attribute.
- Missing option declaration versus a declared option receiving an invalid
  value.
- Infinite recursion versus an ordinary type or merge conflict.
- Missing path versus a file excluded from a Git-backed flake source.
- Stale lock data versus a producer that does not export the requested
  attribute.
- A string output suitable for `--raw` versus structured output requiring
  `--json`.

## Report

State:

1. The failing phase and root cause.
2. The exact file and expression or boundary involved.
3. The evidence that rules out plausible alternatives.
4. One recommended minimal fix and why it preserves intended behavior.
5. Any verification still required.

Offer alternatives only when they represent real architectural tradeoffs. Do
not mask the error with `tryEval`, broad defaults, forced option precedence, or
lock-file churn unless that behavior is explicitly intended.
