
resource "vault_policy" "injector-app" {
  name = "injector-app"

  policy = <<EOT
path "internal/data/database/config" {
  capabilities = ["read"]
}
path "database/rds/postgres/vault-hashi-talks-mock/*" {
  capabilities = ["read"]
}
EOT
}