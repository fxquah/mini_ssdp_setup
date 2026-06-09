# mini_pdss_setup

A learning project modelling a PDSS setup on AWS. It demonstrates separating business logic deployment from infrastructure publishing using Lambda versioning.

## Architecture

```
S3 bucket (trigger.json upload)
  → EventBridge rule
  → Step Functions state machine (etl-rd)
  → Lambda: ssdp-trigger-ingestion-{env} (via versioned alias)
```

- **S3** (`terraform/s3.tf`): Ingestion bucket with EventBridge notifications enabled.
- **EventBridge** (`terraform/eventbridge.tf`): Rule fires when `trigger.json` is uploaded to the bucket; targets the state machine.
- **Step Functions** (`terraform/state_machine.tf`): `ssdp-etl-rd-{env}` invokes the Lambda alias, with retries on transient Lambda errors.
- **Lambda** (`terraform/lambda.tf`, `terraform/modules/lambda_external/`): `ssdp-trigger-ingestion-{env}` with versioning enabled. The state machine always invokes via a versioned alias, not `$LATEST`.

## Repo structure

```
business_logic/
  trigger_ingestion/
    handler.py          # Lambda source code
    handler.zip         # Built artifact (gitignored)
  Makefile              # Deploys code to Lambda; copies zip to terraform/artifacts/

terraform/
  artifacts/
    trigger_ingestion.zip   # Handoff point — written by make deploy, read by Terraform (gitignored)
  modules/
    lambda_external/        # Reusable module: aws_lambda_function + aws_lambda_alias
  lambda.tf               # Uses filebase64sha256 on artifacts zip to detect code changes
  state_machine.tf
  eventbridge.tf
  s3.tf
  vars/{dev,prod}.tfvars
  backends/{dev,prod}.hcl
```

## Deployment workflow

Business logic and infrastructure have separate responsibilities:

| Step | Command | Who | What |
|---|---|---|---|
| 1 | `make deploy_business_logic` | Business logic | Zips `handler.py`, calls `aws lambda update-function-code` (code updated, no publish), copies zip to `terraform/artifacts/trigger_ingestion.zip` |
| 2 | `make plan` | INFRA | Terraform computes hash of `terraform/artifacts/trigger_ingestion.zip`, sees it changed, plans to update Lambda and publish a new version |
| 3 | `make apply` | INFRA | Terraform re-uploads the zip and publishes a new version; the alias is updated to point to the new version |

`make deploy_business_logic` intentionally does **not** publish. Publishing is exclusively Terraform's responsibility.

### Why this separation works

Terraform tracks code changes via `filebase64sha256("${path.root}/artifacts/trigger_ingestion.zip")` in `lambda.tf`. When the hash changes, Terraform updates `aws_lambda_function` with `publish = true`, which creates a new version and updates `aws_lambda_alias` to point to it. The state machine always invokes the alias ARN, so it automatically picks up the new version after apply.

`terraform/artifacts/` is the contract boundary — business logic writes to it, Terraform reads from it. Terraform has no knowledge of the `business_logic/` directory.

### First-time setup on a fresh checkout

`make deploy_business_logic` must be run at least once before `make plan`, because Terraform needs `terraform/artifacts/trigger_ingestion.zip` to exist.

## Common make targets

```bash
make init ENV=dev              # terraform init with dev backend
make plan ENV=dev              # terraform plan, outputs plan.tfplan
make apply ENV=dev             # terraform apply plan.tfplan
make deploy_business_logic ENV=dev  # deploy Lambda code + stage artifact
make plan-check                # summarise planned changes as JSON
make fmt                       # terraform fmt
make lint                      # tflint
```

Default `ENV` is `dev`.

## Lambda module (`modules/lambda_external`)

The module creates an `aws_lambda_function` (with `publish = true`) and an `aws_lambda_alias` named `{function_name}-{version}`. Callers must supply `filename` and `source_code_hash` — the module does not manage source code itself.

## AWS region

Default region: `eu-west-2`.