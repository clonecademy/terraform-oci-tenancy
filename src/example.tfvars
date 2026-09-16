# PATH: /src/example.tfvars
#
# Copy to terraform.tfvars for local runs. Values mirror ~/.config/oci/config.
# CI does not use this file; it passes TF_VAR_* from GitHub Secrets instead,
# and sets private_key (PEM contents) rather than private_key_path.

tenancy_ocid     = "" # ~/.config/oci/config -> tenancy
user_ocid        = "" # ~/.config/oci/config -> user
fingerprint      = "" # ~/.config/oci/config -> fingerprint
region           = "" # ~/.config/oci/config -> region
private_key_path = "" # ~/.config/oci/config -> key_file

# Only if the private key is encrypted.
# private_key_password = ""
