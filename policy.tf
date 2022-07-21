
resource "vault_policy" "injector-app" {
  name = "injector-app"

  policy = <<EOT
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOT
}