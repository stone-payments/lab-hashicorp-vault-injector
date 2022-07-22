resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://172.20.0.1:443"
  disable_iss_validation = "true"
}


# resource "vault_kubernetes_auth_backend_role" "kubernetes" {
#   backend                          = vault_auth_backend.kubernetes.path
#   role_name                        = "kube-role"
#   bound_service_account_names      = ["vault-eks-homolog"]
#   bound_service_account_namespaces = ["vault-teste"]
#   token_ttl                        = 3600
#   token_policies                   = ["injector-app"]
# }



resource "vault_kubernetes_auth_backend_role" "appruan" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "appruan"
  bound_service_account_names      = ["appruan"]
  bound_service_account_namespaces = ["appruan"]
  token_ttl                        = 3600
  token_policies                   = ["appruan"]
}
