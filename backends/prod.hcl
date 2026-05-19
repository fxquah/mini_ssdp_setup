bucket         = "my-tfstate-prod"
key            = "prod/terraform.tfstate"
region         = "eu-west-2"
encrypt        = true
dynamodb_table = "terraform-locks-prod"