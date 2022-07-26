terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.7.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "4.23.0"
    }    
  }
}