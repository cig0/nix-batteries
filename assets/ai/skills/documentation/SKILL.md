---
name: documentation
description: >-
  Create and update adjacent documentation and implementation-plan documents.
  Use for README files, code comments, data-flow descriptions, provenance
  traces, option tables, and reviewed implementation plans.
---

# Documentation

Load the workflow that matches the requested document:

| Need                                                   | File                                               |
| ------------------------------------------------------ | -------------------------------------------------- |
| Adjacent README or inline documentation                | [doc-adjacent-sweep.md](doc-adjacent-sweep.md)     |
| Reviewed implementation-plan document                 | [implementation-plan.md](implementation-plan.md)   |
| Section templates, placement rules, good/bad examples | [doc-reference.md](doc-reference.md)               |

Combine with applicable repository-local guidance when present. Adjacent
READMEs, inline comments, and implementation plans serve different surfaces;
do not apply one surface's voice or structure mechanically to another.

User instructions and repository-local guidance take precedence. Treat this
skill as the reusable documentation baseline, not as a replacement for
project-specific architecture or policy.

## Assumptions

- Adjacent documentation includes nearby `README.md` files and focused inline
  comments or type annotations that explain a code boundary.
- Leaf directories do not need their own README when a nearby parent README
  already gives a clear route.
- Top-level historical docs and TODOs are out of scope unless they actively
  route readers to stale locations.
- Explicit implementation-plan documents may be prescriptive. Adjacent
  READMEs and source comments remain passive descriptions of current behavior.
