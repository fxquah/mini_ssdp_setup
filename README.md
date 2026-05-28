# mini ddsp replica

My self learning project to produce a mini replica of SSDp.

## Current instructions
Add into `terraform.tfvars`

```terraform
aws_profile = "your-aws-profile"
```

Update 26 May: This doesn't seem work anymore. I tried updating this directly in the `backend.tf`, but that also failed. This worked, however, `export AWS_PROFILE=sandbox-jelly`.



### To deploy
For `dev`:
```sh
terraform init -backend-config=backends/dev.hcl -reconfigure
terraform plan -var-file=vars/dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

For `prod`
```sh
terraform init -backend-config=backends/prod.hcl -reconfigure
terraform plan -var-file=vars/prod.tfvars -out=plan.tfplan
terraform apply -var-file=vars/prod.tfvars
```

### For linting
[Format](https://developer.hashicorp.com/terraform/cli/commands/fmt)

```shell
terraform fmt -diff
terraform fmt

tflint --init                                                                                                                                                                          
tflint --var-file=vars/dev.tfvars
```


---

## Long Term plan
Replicate the following

### rd-referral-dp state machine
#### Original version
1. RegisterCase
2. AnnotateVariants - map
3. UpdateGenomicsDBAnnotation
4. LoadOpensearchViaSqs
5. UpdateGenomicsDBIngestion
6. UpdateCaseStatus
7. UpdateCIPAPIStatus

#### Simplified version
1. RegisterCase: trigger by input
2. AnnotateVariants: perform the map, not sure how results are combined
3. LoadOpensearchViaSqs: this doesn't invoke a lambda

https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html

### referral-dp state machine
To come

---

## Notes
S3 → your bucket → Properties tab → scroll down to "Event notifications"

```sh
touch trigger.json
aws s3 cp trigger.json s3://ssdp-ingestion-bucket-dev
aws s3 rm s3://ssdp-ingestion-bucket-dev/trigger.json
```

### `lambda_function_arn` vs `lambda_alias_arn`
Using `lambda_function_arn` (no qualifier) means Step Functions invokes the $LATEST version — the unpublished, mutable snapshot of your function. 

```hcl
  definition = templatefile("${path.module}/state-machine-definitions/etl-rd.asl.json", {
    TriggerIngestionLambda = module.trigger_ingestion.lambda_function_arn
  })
```

```hcl
  definition = templatefile("${path.module}/state-machine-definitions/etl-rd.asl.json", {
    TriggerIngestionLambda = module.trigger_ingestion.lambda_alias_arn
  })
```

- `$LATEST` is always mutable. Any code change takes effect immediately, even before terraform apply runs the publish step.
- This means we lose the **mutability guarantee**
- Logs will only show `$LATEST` in CloudWatch, which is less useful.
- Aliases become irrelevant, as the state machine ignores them completely.

With `lambda_alias_arn` (:LIVE), Step Functions always invokes the specific published version the alias points to at the time of execution.

If you redeploy mid-execution, in-flight executions keep using the old version while new ones pick up the new one.

You can retrieve information about the lambda like this 
```sh
aws lambda get-function --function-name ssdp-trigger-ingestion-dev
```
