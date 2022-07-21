resource "vault_mount" "internal" {
  path        = "internal"
  type        = "kv"
  options     = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "config" {
  mount                      = vault_mount.internal.path
  max_versions               = 5
  cas_required               = true
}
