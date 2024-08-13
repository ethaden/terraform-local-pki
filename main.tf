
# Generate a ECDSA key used as part of our Certificate Authority (CA)
resource "tls_private_key" "ca_key" {
  algorithm   = var.algorithm
  ecdsa_curve = var.ecdsa_curve
  rsa_bits    = var.rsa_bits
}

# Generate the self-sl
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name         = var.ca_common_name
    organization        = var.organization
    organizational_unit = var.organizational_unit
  }
  validity_period_hours = var.ca_validity_period_hours
  is_ca_certificate     = true
  allowed_uses = [
    "crl_signing",
    "digital_signature",
    "cert_signing"
  ]
}

# Optional: Write the CA key to a file
resource "local_sensitive_file" "ca_key_file" {
  # Write file only if cert_path is not an empty string
  count = (var.cert_path == "") ? 0 : 1

  content  = tls_self_signed_cert.ca_cert.private_key_pem
  filename = "${var.cert_path}/ca_key.pem"
}

# Write the CA cert to a file
resource "local_sensitive_file" "ca_cert_file" {
  # Write file only if cert_path is not an empty string
  count = (var.cert_path == "") ? 0 : 1

  content  = tls_self_signed_cert.ca_cert.cert_pem
  filename = "${var.cert_path}/ca_crt.pem"
}


#####################################
# SERVERS 
#####################################


# Generate a ECDSA key used as part of the server
resource "tls_private_key" "server_keys" {
  for_each = try(tomap(var.server_names), toset(var.server_names))

  algorithm   = var.algorithm
  ecdsa_curve = var.ecdsa_curve
  rsa_bits    = var.rsa_bits
}

# Create a signing request for the server
resource "tls_cert_request" "openvpn_pki_server_csrs" {
  for_each = try(tomap(var.server_names), toset(var.server_names))

  private_key_pem = tls_private_key.server_keys[each.key].private_key_pem

  subject {
    common_name         = each.value
    organization        = var.organization
    organizational_unit = var.organizational_unit
  }
}

# Sign the server keys with our CA key
resource "tls_locally_signed_cert" "server_certs" {
  for_each = try(tomap(var.server_names), toset(var.server_names))

  cert_request_pem   = tls_cert_request.openvpn_pki_server_csrs[each.key].cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.ca_cert.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = var.servers_validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Write the server cert to a file
resource "local_sensitive_file" "server_cert_files" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap((var.cert_path == "") ? {} : var.server_names), toset((var.cert_path == "") ? [] : var.server_names))

  content  = tls_locally_signed_cert.server_certs[each.key].cert_pem
  filename = "${var.cert_path}/server_${each.key}_crt.pem"
}

resource "local_sensitive_file" "server_key_files" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap((var.cert_path == "") ? {} : var.server_names), toset((var.cert_path == "") ? [] : var.server_names))

  content  = tls_private_key.server_keys[each.key].private_key_pem
  filename = "${var.cert_path}/server_${each.key}_key.pem"
}

# Optionally, convert client files to key store
# 1. Convert them to p12 format
resource "terraform_data" "server_cert_and_key_files_p12" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = var.create_keystores ? try(tomap((var.cert_path == "") ? {} : var.server_names), toset((var.cert_path == "") ? [] : var.server_names)) : []

  #filename = "${var.cert_path}/server_${each.key}.p12"
  #input = local_sensitive_file.server_key_files[each.key]
  triggers_replace = {
    filename = local_sensitive_file.server_key_files[each.key].content
    checksum = sha256(local_sensitive_file.server_key_files[each.key].content)
  }

  provisioner "local-exec" {
    command     = "openssl pkcs12 -export -in $CERT_FILE -inkey $KEY_FILE -out $OUTPUT_FILE -name server -CAfile $CA_FILE -caname root -password pass:$PASS"
    environment = {
        KEY_FILE = local_sensitive_file.server_key_files[each.key].filename
        CERT_FILE = local_sensitive_file.server_cert_files[each.key].filename
        OUTPUT_FILE = "${var.cert_path}/server_${each.key}.p12"
        CA_FILE = "${var.cert_path}/ca_key.pem"
        PASS = var.keystore_passphrase
    }
    working_dir = path.root
  }
}

data "local_sensitive_file" "server_cert_and_key_files_p12_files" {
  # Do not write files if cert_path is empty. Otherwise try to cast server_names to map of (name => hostname), or if the fails to set of server names
  for_each = var.create_keystores ? try(tomap((var.cert_path == "") ? {} : var.server_names), toset((var.cert_path == "") ? [] : var.server_names)) : []

  filename = "${var.cert_path}/server_${each.key}.p12"
  depends_on = [ terraform_data.server_cert_and_key_files_p12 ]
}

resource "terraform_data" "create_server_keystores" {
  for_each = var.create_keystores ? try(tomap((var.cert_path == "") ? {} : var.server_names), toset((var.cert_path == "") ? [] : var.server_names)) : []
  triggers_replace = {
    checksum = sha256(data.local_sensitive_file.server_cert_and_key_files_p12_files[each.key].content)
  }
  provisioner "local-exec" {
    command     = "keytool -importkeystore -noprompt -deststorepass password -destkeystore $OUTPUT_FILE -srckeystore $INPUT_FILE -srcstoretype PKCS12 -srcstorepass $PASS -alias server"
    environment = {
        OUTPUT_FILE = "${var.cert_path}/server_${each.key}.jks"
        INPUT_FILE = "${var.cert_path}/server_${each.key}.p12"
        PASS = var.keystore_passphrase
    }
    working_dir = path.root
  }
}


#####################################
# CLIENTS 
#####################################

# Generate a ECDSA key used as part of the clients
resource "tls_private_key" "client_keys" {
  # Try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap(var.client_names), toset(var.client_names))

  algorithm   = var.algorithm
  ecdsa_curve = var.ecdsa_curve
  rsa_bits    = var.rsa_bits
}

# Create a signing request for the clients
resource "tls_cert_request" "client_csrs" {
  # Try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap(var.client_names), toset(var.client_names))

  private_key_pem = tls_private_key.client_keys[each.key].private_key_pem

  subject {
    common_name         = each.value
    organization        = var.organization
    organizational_unit = var.organizational_unit
  }
}

# Sign the client keys with our CA key
resource "tls_locally_signed_cert" "client_certs" {
  # Try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap(var.client_names), toset(var.client_names))

  cert_request_pem   = tls_cert_request.client_csrs[each.key].cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.ca_cert.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = var.clients_validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Write the client keys to files
resource "local_sensitive_file" "client_key_files" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap((var.cert_path == "") ? {} : var.client_names), toset((var.cert_path == "") ? [] : var.client_names))

  content  = tls_private_key.client_keys[each.key].private_key_pem
  filename = "${var.cert_path}/client_${each.key}_key.pem"
}

# Write the client certs to files
resource "local_sensitive_file" "client_cert_files" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = try(tomap((var.cert_path == "") ? {} : var.client_names), toset((var.cert_path == "") ? [] : var.client_names))

  content  = tls_locally_signed_cert.client_certs[each.key].cert_pem
  filename = "${var.cert_path}/client_${each.key}_crt.pem"
}

# Optionally, convert client files to key store
# 1. Convert them to p12 format
resource "terraform_data" "client_cert_and_key_files_p12" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = var.create_keystores ? try(tomap((var.cert_path == "") ? {} : var.client_names), toset((var.cert_path == "") ? [] : var.client_names)) : []

  triggers_replace = {
    filename = local_sensitive_file.client_key_files[each.key].filename
    checksum = sha256(local_sensitive_file.client_key_files[each.key].content)
  }

  provisioner "local-exec" {
    command     = "openssl pkcs12 -export -in $CERT_FILE -inkey $KEY_FILE -out $OUTPUT_FILE -name client -CAfile $CA_FILE -caname root -password pass:$PASS"
    environment = {
        KEY_FILE = local_sensitive_file.client_key_files[each.key].filename
        CERT_FILE = local_sensitive_file.client_cert_files[each.key].filename
        OUTPUT_FILE = "${var.cert_path}/client_${each.key}.p12"
        CA_FILE = "${var.cert_path}/ca_key.pem"
        PASS = var.keystore_passphrase
    }
    working_dir = path.root
  }
}

data "local_sensitive_file" "client_cert_and_key_files_p12_files" {
  # Do not write files if cert_path is empty. Otherwise try to cast client_names to map of (name => hostname), or if the fails to set of client names
  for_each = var.create_keystores ? try(tomap((var.cert_path == "") ? {} : var.client_names), toset((var.cert_path == "") ? [] : var.client_names)) : []

  filename = "${var.cert_path}/client_${each.key}.p12"
  depends_on = [ terraform_data.client_cert_and_key_files_p12 ]
}

resource "terraform_data" "create_client_keystores" {
  for_each = var.create_keystores ? try(tomap((var.cert_path == "") ? {} : var.client_names), toset((var.cert_path == "") ? [] : var.client_names)) : []
  triggers_replace = {
    checksum = sha256(data.local_sensitive_file.client_cert_and_key_files_p12_files[each.key].content)
  }
  provisioner "local-exec" {
    command     = "keytool -importkeystore -noprompt -deststorepass password -destkeystore $OUTPUT_FILE -srckeystore $INPUT_FILE -srcstoretype PKCS12 -srcstorepass $PASS -alias client"
    environment = {
        OUTPUT_FILE = "${var.cert_path}/client_${each.key}.jks"
        INPUT_FILE = "${var.cert_path}/client_${each.key}.p12"
        PASS = var.keystore_passphrase
    }
    working_dir = path.root
  }
}
