# This block tells Terraform which providers we need
# and which versions are acceptable
terraform {

  # The minimum version of Terraform itself required
  # ~> means "any version in the 1.0.x range"
  # so 1.1, 1.2, 1.3 are all fine but not 2.0
  required_version = "~> 1.0"

  # List of providers we need Terraform to download
  required_providers {
    aws = {
      # The official AWS provider maintained by HashiCorp
      source = "hashicorp/aws"

      # ~> 5.0 means any version 5.x is acceptable
      # but not 6.0 (breaking changes could occur)
      version = "~> 5.0"
    }
  }
}

# This block configures the AWS provider itself
# telling it HOW to connect to AWS
provider "aws" {

  # The AWS region where all resources will be created
  # var.aws_region means we are reading from a variable
  # not hardcoding "ap-southeast-2" directly here
  region = var.aws_region

  # Tags added to every single AWS resource automatically
  # default_tags is a powerful feature —
  # instead of adding tags to every resource manually,
  # anything defined here gets applied everywhere
  default_tags {
    tags = {
      # var.project_name and var.environment come from variables
      # so every resource in AWS will be tagged with:
      # Project     = "budget-tracker"
      # Environment = "production"
      # ManagedBy   = "terraform"
      # ManagedBy tells anyone looking at AWS console
      # that this resource was created by Terraform
      # and should NOT be manually modified
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}