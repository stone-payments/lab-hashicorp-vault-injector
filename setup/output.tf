data "vault_approle_auth_backend_role_id" "this" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.approle.role_name
}

output "role-id" {
  value = data.vault_approle_auth_backend_role_id.this.role_id
}

output "secret-id" {
  value = vault_approle_auth_backend_role_secret_id.approle.secret_id
}
