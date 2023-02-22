---
page_title: "Provider: TLS"
description: |-
  The TLS provider provides utilities for working with Transport Layer Security keys and certificates.
---

# TLS Provider

## Example Usage

```terraform
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
```

## Schema

Please have a look into `variables.tf` and `outputs.tf` for now.
