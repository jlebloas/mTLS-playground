provider "vault" {
}

resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_pki_secret_backend_root_cert" "root_ca" {
  backend               = vault_mount.pki.path
  type                  = "internal"
  common_name           = "Root CA"
  ttl                   = "315360000"
  format                = "pem"
  key_type              = "rsa"
  key_bits              = 4096
  exclude_cn_from_sans  = true
  ou                    = "My OU"
  organization          = "My organization"
}

resource "vault_pki_secret_backend_role" "default" {
  backend        = vault_pki_secret_backend_root_cert.root_ca.backend
  name           = "default"
  ttl            = 3600
  allow_ip_sans  = true
  key_type       = "rsa"
  key_bits       = 4096
  allow_any_name = true
  client_flag    = true
  server_flag    = true
}

resource "vault_pki_secret_backend_cert" "backend_cert" {
  backend     = vault_pki_secret_backend_root_cert.root_ca.backend
  common_name = "app.local"
  name        = vault_pki_secret_backend_role.default.name
}

resource "vault_pki_secret_backend_cert" "client_cert" {
  backend     = vault_pki_secret_backend_root_cert.root_ca.backend
  common_name = "jlebloas"
  name        = vault_pki_secret_backend_role.default.name
}
