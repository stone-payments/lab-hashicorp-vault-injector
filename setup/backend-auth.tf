# backend auth aws
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
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# backend auth kubernetes
resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "local.kubernetes_host"
  disable_iss_validation = "true"
}


resource "vault_kubernetes_auth_backend_role" "kubernetes" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "${local.project_name}-role"
  bound_service_account_names      = ["${local.project_name}"]
  bound_service_account_namespaces = ["${local.project_name}"]
  token_ttl                        = 3600
  token_policies                   = ["${vault_policy.kubernetes.name}"]
}

# backend auth app role
resource "vault_auth_backend" "approle" {
  type = "approle"

}

resource "vault_approle_auth_backend_role" "approle" {
  backend         = vault_auth_backend.approle.path
  role_name       = "${local.project_name}-approle"
  token_num_uses  = "0"
  secret_id_ttl = "0"
  token_max_ttl = "0"
  secret_id_num_uses = "0"
  token_policies  = ["${local.project_name}-approle"]
}

resource "vault_approle_auth_backend_role_secret_id" "approle" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.approle.role_name
}

resource "vault_approle_auth_backend_login" "approle" {
  backend   = vault_auth_backend.approle.path
  role_id   = vault_approle_auth_backend_role.approle.role_id
  secret_id = vault_approle_auth_backend_role_secret_id.approle.secret_id
}

 