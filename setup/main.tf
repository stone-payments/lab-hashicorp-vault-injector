provider "vault" {
  address = local.VAULT_ADDR
  
}

provider "aws" {
  region = "us-east-1"
}



