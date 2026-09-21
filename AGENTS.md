# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

Terraform for the Clonecademy Oracle Cloud (OCI) tenancy. Everything lives in `src/`, a single root module; there are no tests beyond `fmt` and `validate`.

## Commands

Run from `src/`. Terraform is pinned to `~> 1.16.0` and the `oracle/oci` provider to `~> 9.1.0`.

```sh
terraform fmt -check -recursive -diff   # CI fails on unformatted files
terraform init -backend-config=backend.hcl
terraform validate
terraform plan                           # reads terraform.tfvars
```

Local runs use `terraform.tfvars` (copied from `example.tfvars`) and `backend.hcl` (OCI API key auth for the state backend); both are gitignored. The state backend (`src/terraform.tf`) is the `terraform` Object Storage bucket, which this configuration itself manages in `buckets.tf` with `prevent_destroy`.

## CI (`.github/workflows/terraform.yml`)

- Pull requests to `main`: fmt, init, validate, plan; the plan is posted as a PR comment and uploaded as an artifact.
- Push to `main`: the `apply` job waits for approval on the `production` environment, re-plans, `diff`s the new rendered plan against the reviewed `tfplan.txt`, and only applies if they match.
- Only the rendered plan text is uploaded, never the binary plan: the repository is public and the binary holds sensitive variable values.
- All inputs come from GitHub Secrets as `TF_VAR_*`. The API signing key and SSH public key are written to files under `$RUNNER_TEMP`. `SSH_INGRESS_CIDRS` must hold JSON (e.g. `["203.0.113.4/32"]`) because the variable is a list. A new variable without a default needs a matching secret and `TF_VAR_` entry in the workflow's shared `env` anchor.

## Architecture

- `compartments.tf`: the `main` compartment; everything except the state bucket and IAM policies is created in it.
- `network.tf`: VCN, gateways, and public/private subnets from the external module `github.com/clonecademy/terraform-oci-module-vcn`.
- `server.tf`: the Always Free compute instance from `github.com/clonecademy/terraform-oci-module-vps`, placed in the public subnet. SSH ingress is an NSG managed by the module, restricted to `ssh_ingress_cidrs` (deliberately no default). Tailscale is installed by hand, not through cloud-init.
- `database.tf`: MySQL HeatWave DB system and HeatWave cluster (Lakehouse) in the private subnet, with an NSG opening the MySQL ports to the VCN CIDRs and the IAM policy the DB system's resource principal needs. A precondition blocks creation outside the tenancy's home region. `ignore_changes = [admin_password, source]` keeps those force-replacing fields from destroying the database.
- `monitoring.tf`: a single Notifications topic with an email subscription, passed to the VPS module as `alarm_destinations`. Future alarms should reuse this topic.

Modules are pinned by git tag (`?ref=vX.Y.Z`); upgrading one means bumping the ref here after tagging the module repo.

## Constraints

- Every resource must stay within OCI's Always Free limits: `MySQL.Free`/`HeatWave.Free` shapes, 50 GB DB storage (validated), no HA or backup policy block on the DB system, and a boot volume that uses the whole 200 GB block volume allowance.
- Mark anything personal or secret `sensitive = true`: plans are posted publicly on pull requests (for example, `alarm_email` is sensitive for this reason).
- Files start with a `# PATH: /src/<file>.tf` header, and comments explain *why* (OCI quirks, Always Free limits) rather than *what*.
