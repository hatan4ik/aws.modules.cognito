terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.92.0, < 2.0.0"
    }
  }
}

provider "awscc" {
  region = var.primary_region
}

provider "awscc" {
  alias  = "secondary"
  region = var.secondary_region
}
