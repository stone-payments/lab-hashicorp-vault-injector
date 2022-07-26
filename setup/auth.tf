resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

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

 