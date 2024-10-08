variable "organization" {
  description = "The organization name used in the generated certificates"
  type        = string
  default     = "ACME Examples, Inc"
}

variable "organizational_unit" {
  description = "The organizational unit name used in the generated certificates"
  type        = string
  default     = ""
}

variable "ca_common_name" {
  description = "The common name used in the generated CA"
  type        = string
  default     = "ACME Examples CA"
}

variable "cert_path" {
  description = "Optional: Path where to store the generated keys and certificates. If left empty, no files are generated."
  type        = string
  default     = ""
}

variable "ca_validity_period_hours" {
  description = "Validity period of the CA certificate in hours"
  type        = number
  default     = 24 * 365 * 2
}

variable "servers_validity_period_hours" {
  description = "Validity period of all servers certificates in hours"
  type        = number
  default     = 24 * 365 * 2
}

variable "clients_validity_period_hours" {
  description = "Validity period of all client certificates in hours"
  type        = number
  default     = 24 * 365 * 2
}

variable "algorithm" {
  description = "The algorithm used for creating the keys and certificates"
  type        = string
  default     = "ECDSA"
}

variable "ecdsa_curve" {
  description = "If the algorithm is ECDSA, this variable specifies the type of the curve"
  type        = string
  default     = "P521"
}

variable "rsa_bits" {
  description = "If the algorithm is RSA, this variable specifies the number of bits"
  type        = number
  default     = 4096
}

variable "server_names" {
  description = "List of names of servers to generate keys and signed certificates for"
  type        = any
  default     = []
  validation {
    condition     = can(tomap(var.server_names)) || can(toset(var.server_names))
    error_message = "The server_names value must be either a list of server names ([\"server1\", \"server2\"]) of a map of name to hostnames ({\"server1\": [\"hostname1\", \"hostname2\"], \"server2\": [\"hostname3\"]})"
  }
}

variable "client_names" {
  description = "Specifies clients to generate keys and signed certificates for. Either a list of names or a map of (name => hostname). In the latter case, the hostname is used a certificate subject"
  type        = any
  default     = []
  validation {
    condition     = can(tomap(var.client_names)) || can(toset(var.client_names))
    error_message = "The client_names value must be either a list of client names ([\"client1\", \"client2\"]) of a map of name to hostnames ({\"client1\": [\"hostname1\", \"hostname2\"], \"client2\": [\"hostname3\"]})"
  }
}

variable "create_keystores" {
    type      = bool
    default   = false
    description = "Set to true to generate keystores for each certificate. Requires \"openssl\" and \"keytool\" on the command line"
}

variable "include_ca_in_keystores" {
    type      = bool
    default   = true
    description = "Wether or not to include the certificate authority in the generated key stores for servers and clients"
}

variable "keystore_passphrase" {
    type      = string
    default   = "123456"
    description = "The passphrase used if creating keystores. Please update this variable and change the passphrase for each file afterwords before distributing them to users"
}
