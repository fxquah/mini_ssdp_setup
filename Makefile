ENV ?= dev
TF_DIR := terraform

.PHONY: init plan apply fmt-check fmt lint

init:
	cd $(TF_DIR) && terraform init -backend-config=backends/$(ENV).hcl -reconfigure

plan:
	cd $(TF_DIR) && terraform plan -var-file=vars/$(ENV).tfvars -out=plan.tfplan

plan-check:
	cd $(TF_DIR) && terraform show -json plan.tfplan | jq '[.resource_changes[] | {address, action: .change.actions}] | group_by(.action) | map({action: .[0].action, resources: map(.address)})'

apply:
	cd $(TF_DIR) && terraform apply plan.tfplan

fmt-check:
	cd $(TF_DIR) && terraform fmt -diff

fmt:
	cd $(TF_DIR) && terraform fmt

lint:
	cd $(TF_DIR) && tflint --init && tflint --var-file=vars/$(ENV).tfvars
