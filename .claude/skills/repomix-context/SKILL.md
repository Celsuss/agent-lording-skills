---
name: repomix-context
description: Codebase navigation policy for Terraform projects packed with Repomix. Use when repomix-output.xml exists alongside .tf files. Consult the XML first for architecture/dependency/cross-file questions; refresh via npx repomix after significant changes; do not manually read .terraform/ directories or .tfstate files.
---

## Repository Context & Navigation

- **Primary Context Source:** Always consult `repomix-output.xml` first when you need to understand the repository structure, review module dependencies, or plan cross-file changes.
- **File Contents:** This file contains the complete, up-to-date, and packed context of all relevant Terraform code, optimized in XML format.
- **Context Refresh:** If you make significant changes to the Terraform files or if the context seems stale, run `npx repomix` to regenerate the `repomix-output.xml` file before proceeding with further analysis.
- **Ignore State/Binaries:** Do not attempt to manually read `.terraform/` directories or `.tfstate` files; rely strictly on the HCL logic packed into the Repomix output.
