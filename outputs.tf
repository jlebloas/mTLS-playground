output "root_ca" {
  value = vault_pki_secret_backend_root_cert.root_ca.certificate
}

output "backend_cert" {
  value = vault_pki_secret_backend_cert.backend_cert.certificate
}
output "backend_key" {
  value = vault_pki_secret_backend_cert.backend_cert.private_key
  sensitive = true
}

output "client_cert" {
  value = vault_pki_secret_backend_cert.client_cert.certificate
}
output "client_key" {
  value = vault_pki_secret_backend_cert.client_cert.private_key
  sensitive = true
}
