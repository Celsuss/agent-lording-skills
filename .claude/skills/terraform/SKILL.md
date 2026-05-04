---
name: terraform
description: Rules and conventions when writing or modifying Terraform/HCL. Use when editing .tf files, generating IAM policies, or planning infrastructure changes. Includes AWS-specific guidance (aws_iam_policy_document, no Access Keys in code, terraform state CLI for drift inspection). Triggers init→fmt→validate→plan workflow; never apply without approval.
---

## Terraform rules

After writing or modifying any `.tf` files, immediately run `terraform fmt` and `terraform validate` to check your own work before responding.

Never suggest or run `terraform apply`. Your lifecycle is strictly `init -> fmt -> validate -> plan -out=tfplan`. Always present the plan summary and wait for explicit human approval before taking further action.

Also never use `kubectl` to modify anything in the Kubernetes cluster.

When you are done making all your changes, dispatch a subagent to review your changes.

## AWS

When creating AWS IAM policies, never use inline JSON strings or `file()` functions. Always construct policies using the `aws_iam_policy_document` data source to ensure the HCL is strictly validated before deployment.

Never generate or output AWS Access Keys or Secret Keys in your responses or in the Terraform code. Always assume authentication is handled via the local environment's AWS SSO session or assume-role configuration in the AWS provider block.

If you need to inspect the currently deployed infrastructure to resolve drifts or output missing attributes, do not attempt to download the S3 state file. Instead, strictly use the CLI commands `terraform state list` and `terraform state show <resource_address>` to read the remote state safely.
