
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

resource "vault_policy" "appruan" {
  name = "appruan"

  policy = <<EOT
path "internal/data/database/config" {
  capabilities = ["read"]
}
path "database/rds/postgres/vault-hashi-talks-mock/*" {
  capabilities = ["read"]
}
EOT
}