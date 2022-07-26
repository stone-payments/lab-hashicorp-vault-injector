resource "vault_auth_backend" "aws" {
  type = "aws"
}

resource "vault_aws_auth_backend_client" "aws" {
  backend = vault_auth_backend.aws.path
  access_key = aws_iam_access_key.vault_auth.id
  secret_key = aws_iam_access_key.vault_auth.secret
}

resource "vault_aws_auth_backend_role" "aws_auth_role_with_web_identity" {
  role      = "app-example-iam-auth"
  auth_type = "iam"
  bound_iam_principal_arns = [aws_iam_role.iam_assumable_role_with_web_identity.arn]
  token_period  = 240
  token_max_ttl = 2160
  token_policies = ["app-example-iam-auth"]
}