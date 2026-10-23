---
name: repomix-context
description: "Codebase navigation policy for Terraform projects packed with Repomix. TRIGGER when: repomix-output.xml exists alongside .tf files and the user asks about repository structure, module dependencies, or cross-file changes. SKIP when: repomix-output.xml is absent; non-Terraform projects; reading a single .tf file you are about to edit. Consult the XML first for architecture/dependency/cross-file questions; refresh via `npx repomix` after significant changes; never read .terraform/ or .tfstate files manually."
---

## When this applies

Applies when `repomix-output.xml` exists alongside `.tf` files and the question is about repository structure, module dependencies, or cross-file changes. Does not apply when the XML is absent, in non-Terraform projects, or when reading a single `.tf` file you are about to edit.

## Rules

- Consult `repomix-output.xml` first for repository structure, module dependencies, and cross-file changes.
- Treat the XML as the packed, up-to-date context of all relevant Terraform code, optimized for review.
- Run `npx repomix` to regenerate `repomix-output.xml` after significant `.tf` changes or when the context seems stale.
- Do not manually read `.terraform/` directories or `.tfstate` files; rely on the HCL logic packed into the Repomix output.

## Examples

**DO:**

```bash
# Consult the packed context first to find which module exposes the input.
grep -n 'name="vpc_id"' repomix-output.xml
```

**DON'T:**

```bash
# Skip the packed XML and dig into Terraform's internal cache by hand.
cat .terraform/modules/network/main.tf
```
