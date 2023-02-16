terraform {
  required_version = "> 0.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 3.75"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      application = local.function_name
      env         = "dev"
    }
  }
}
