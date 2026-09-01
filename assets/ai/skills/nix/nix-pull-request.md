# Nix Pull Request

Use this workflow only for an actual pull request, its checks, or its review
feedback. Use the local reviewer workflow for an unsubmitted diff.

## Inspect

1. Read repository guidance and PR metadata.
2. Establish the base and head revisions, then inspect the complete diff and
   relevant surrounding code.
3. Read existing review threads and CI results when available. Distinguish
   unresolved findings from resolved or outdated comments.
4. Check whether new files, generated outputs, and lock changes are included
   and intentional.
5. Evaluate the change using [nix-reviewer.md](nix-reviewer.md).

Do not modify code, resolve threads, submit a review, commit, push, or change PR
state unless the user explicitly requests that action.

## Report

Lead with actionable findings ordered by severity. For each finding, identify
the file and narrow line range, explain the user-visible or evaluation impact,
and state the smallest corrective direction. Avoid requiring a complete
rewritten expression when a precise change is clearer.

Then summarize:

- PR purpose and approach.
- Validation and CI status.
- Platform or host coverage.
- Lock-file and compatibility impact.
- Remaining questions or risks.

If there are no actionable findings, say so directly and identify any
verification gap that prevents stronger confidence.
