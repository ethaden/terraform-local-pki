output "ca_key" {
  description = "The generated CA key"
  sensitive   = true
  value       = tls_private_key.ca_key
}

output "ca_cert" {
  description = "The generated (self-signed) CA certificate"
  sensitive   = true
  value       = tls_self_signed_cert.ca_cert
}

output "server_keys" {
  description = "The generated server keys as a map of names to 'tls_private_key' objects"
  sensitive   = true
  value       = tls_private_key.server_keys
}

output "server_certs" {
  description = "The generated signed server certificates as a map of names to 'tls_locally_signed_cert' objects"
  value       = tls_locally_signed_cert.server_certs
  sensitive   = true
}

output "client_keys" {
  description = "The generated client keys as a map of names to 'tls_private_key' objects"
  sensitive   = true
  value       = tls_private_key.client_keys
}

output "client_certs" {
  description = "The generated signed client certificates as a map of names to 'tls_locally_signed_cert' objects"
  sensitive   = true
  value       = tls_locally_signed_cert.client_certs
}
