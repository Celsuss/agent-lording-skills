---
name: terraform
description: "Rules and conventions when writing or modifying Terraform/HCL. TRIGGER when: editing .tf files; authoring AWS IAM policies; planning infrastructure changes. SKIP when: editing Kubernetes manifests (use the kubernetes skill); CI configs; non-infrastructure code. Enforces init→fmt→validate→plan workflow (never apply without approval); aws_iam_policy_document for IAM (no inline jsonencode/file); no Access Keys in code; terraform state CLI (not raw S3 state) for drift inspection."
---

## When this applies

Applies when editing `.tf` files, authoring AWS IAM policies, or planning infrastructure changes. Does not apply to Kubernetes manifests (use the `kubernetes` skill), CI configs, or non-infrastructure code.

## Rules

- Run `terraform fmt` and `terraform validate` immediately after writing or modifying any `.tf` file, before responding.
- Never suggest or run `terraform apply`. The lifecycle is strictly `init → fmt → validate → plan -out=tfplan`; present the plan summary and wait for explicit human approval before taking further action.
- After all changes are made, dispatch a subagent to review them.

## AWS

- Build IAM policies with the `aws_iam_policy_document` data source; never inline JSON via `jsonencode()` or `file()`, so the HCL is strictly validated before deployment.
- Never generate or output AWS Access Keys or Secret Keys in responses or in Terraform code. Assume authentication is handled via the local environment's AWS SSO session or assume-role configuration on the AWS provider block.
- Inspect deployed infrastructure for drift via `terraform state list` and `terraform state show <resource_address>`. Do not attempt to download the S3 state file.

## Examples

**DO:**

```hcl
data "aws_iam_policy_document" "s3_read" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "s3-read"
  policy = data.aws_iam_policy_document.s3_read.json
}
```

**DON'T:**

```hcl
resource "aws_iam_policy" "s3_read" {
  name = "s3-read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.assets.arn,
        "${aws_s3_bucket.assets.arn}/*",
      ]
    }]
  })
}
```
