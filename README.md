# mini ddsp replica

My self learning project to produce a mini replica of SSDp.

## Current instructions

### To deploy
For `dev`:
```sh
terraform init -backend-config=backends/dev.hcl -reconfigure
terraform plan -var-file=vars/dev.tfvars
terraform apply -var-file=vars/dev.tfvars
```

For `prod`
```sh
terraform init -backend-config=backends/prod.hcl -reconfigure
terraform plan -var-file=vars/prod.tfvars
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