module "terraform_pki" {
    source = "github.com/ethaden/terraform-local-pki.git"

    cert_path = "./generated/openvpn_pki"
    organization = "ACME PKI Organization"
    ca_common_name = "ACME PKI Organization CA"
    # Generate a server certifacate without specifying a hostname ...
    server_names = ["server"]
    # ... or with hostname. Multiple distinct server names can be specified.
    #server_names = { "server": "server.acme.org" }
    # Generate a client certifacate without specifying a hostname ...
    client_names = ["client"]
    # ... or with hostname. Multiple distinct client names can be specified.
    #client_names = { "client": "client.acme.org" }
}

# Output some of the values
# Note: Sensitive values have to be queried explicitly after running "terraform apply" with "terraform output <variable-name>"
output "pki_ca_key" {
    sensitive = true
    value = module.terraform_pki.ca_cert.private_key_pem
}

output "pki_ca_cert" {
    value = module.terraform_pki.ca_cert.cert_pem
}

output "pki_server_key" {
    sensitive = true
    value = module.terraform_pki.server_keys["server"].private_key_pem
}

output "pki_server_cert" {
    value = module.terraform_pki.server_certs["server"].cert_pem
}

output "pki_client_key" {
    sensitive = true
    value = module.terraform_pki.client_keys["client"].private_key_pem
}

output "pki_client_cert" {
    value = module.terraform_pki.client_certs["client"].cert_pem
}
