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

resource "vault_mount" "enable_secrets_engine_path" {
  path = "database/rds/postgres/vault-hashi-talks-mock"
  type = "database"
}

resource "vault_database_secret_backend_connection" "backend_connection" {
  backend           = vault_mount.enable_secrets_engine_path.path
  name              = local.database_name
  plugin_name       = "postgresql-database-plugin"
  allowed_roles     = [ "readonly", "readwrite" ]
  verify_connection = true

  postgresql {
    connection_url          = "postgres://{{username}}:{{password}}@${local.endpoint}:${local.database_port}/${local.database_name}"
    max_open_connections    = 4
    max_idle_connections    = 1
    max_connection_lifetime = 300
    username                = local.username_db
  }
  data = {
    password = local.password_db
  }
}

resource "vault_database_secret_backend_role" "role_readonly" {
  backend     = vault_mount.enable_secrets_engine_path.path
  name        = "readonly"
  db_name     = vault_database_secret_backend_connection.backend_connection.name
  default_ttl = 3600
  max_ttl     = 43200

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' CONNECTION LIMIT 10 VALID UNTIL '{{expiration}}';",
    "GRANT readers TO \"{{name}}\";",
    "ALTER ROLE  \"{{name}}\" SET statement_timeout = 600000;",
    "ALTER ROLE  \"{{name}}\" SET idle_in_transaction_session_timeout = 600000;",
  ]
  revocation_statements = [
    "GRANT  \"{{name}}\" TO CURRENT_USER;",
    "SET ROLE  \"{{name}}\";",
    "DROP OWNED BY  \"{{name}}\";",
    "RESET role;",
    "REVOKE  \"{{name}}\" FROM CURRENT_USER;",
    "DROP ROLE \"{{name}}\";",
  ]
}

resource "vault_database_secret_backend_role" "role_readwrite" {
  backend     = vault_mount.enable_secrets_engine_path.path
  name        = "readwrite"
  db_name     = vault_database_secret_backend_connection.backend_connection.name
  default_ttl = 3600
  max_ttl     = 43200

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' CONNECTION LIMIT 10 VALID UNTIL '{{expiration}}';",
    "GRANT writers TO \"{{name}}\";",
    "ALTER ROLE  \"{{name}}\" SET statement_timeout = 600000;",
    "ALTER ROLE  \"{{name}}\" SET idle_in_transaction_session_timeout = 600000;",
  ]
  revocation_statements = [
    "GRANT  \"{{name}}\" TO CURRENT_USER;",
    "SET ROLE  \"{{name}}\";",
    "DROP OWNED BY  \"{{name}}\";",
    "RESET role;",
    "REVOKE  \"{{name}}\" FROM CURRENT_USER;",
    "DROP ROLE \"{{name}}\";",
  ]
}

