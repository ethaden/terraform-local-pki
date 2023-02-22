# Terraform PKI (Public Key Infrastructure) Module
This module makes it easy to generate self-signed Certificate Authority (CA) and server and client certificates for testing purposes.
The generated keys are made available as output variables. Optionally, the keys and certificates can be written to files.

## Security Considerations
The generated keys are sensitive data and thus you should to care not to publish them on the internet, e.g. by committing them to git repositories (you might want to add the path for the generated files and/or "*.pem" to your ".gitignore" file).

## Usage

Please have a look at the [examples folder](./examples/). In the future, further information regarding parameters will be given in the [documentation] (./docs/index.md)

For security reasons, this module defaults to generating all keys and certificates using `ECDSA` with curve `P521`. This behavior can be changed by using different values for the module parameters `algorithm` (e.g. `RSA` instead of `ECDSA`) in combination with values for `ecdsa_curve` (for ECDSA) or `rsa_bits` (for RSA). As this module heavily relies on the [Hashicorp TLS provider](https://registry.terraform.io/providers/hashicorp/tls/latest/docs). Details about supported cryptographic algorithms can be found there.

### Schema


## DISCLAIMER
THIS MODULE IS MEANT FOR TESTING ONLY AND NOT FOR PRODUCTION. PLEASE CHECK THE [LICENSE](LICENSE) FOR FURTHER INFORMATION.
