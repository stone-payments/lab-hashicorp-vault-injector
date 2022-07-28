resource "vault_policy" "kubernetes" {
  name = "${local.project_name}-kubernetes"

  policy = <<EOT
path "internal/data/database/config" {
  capabilities = ["read"]
}
path "database/rds/postgres/vault-hashi-talks-mock/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "vault-hashitalks" {
  name = "${local.project_name}-approle"

  policy = <<EOT
path "internal/data/database/config" {
  capabilities = ["read"]
}
path "database/rds/postgres/vault-hashi-talks-mock/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "app-example-iam-auth" {
  name = "app-example-iam-auth"

  policy = <<EOT
path "internal/data/database/config" {
  capabilities = ["read"]
}
path "database/rds/postgres/vault-hashi-talks-mock/*" {
  capabilities = ["read"]
}
EOT
}