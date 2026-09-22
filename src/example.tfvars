# PATH: /src/example.tfvars
#
# Copy to terraform.tfvars for local runs. Values mirror ~/.config/oci/config.
# CI does not use this file; it passes TF_VAR_* from GitHub Secrets instead,
# and writes the private key to a temporary file for private_key_path.

tenancy_ocid     = "" # ~/.config/oci/config -> tenancy
user_ocid        = "" # ~/.config/oci/config -> user
fingerprint      = "" # ~/.config/oci/config -> fingerprint
region           = "" # ~/.config/oci/config -> region
private_key_path = "" # ~/.config/oci/config -> key_file

# Only if the private key is encrypted.
# private_key_password = ""

# For initial server administration.
ssh_public_key_path = ""

# Addresses allowed to reach SSH on the server. ["0.0.0.0/0"] is the whole
# internet; narrow it to known addresses. CI passes TF_VAR_ssh_ingress_cidrs,
# which must be JSON because the variable is a list, e.g. '["203.0.113.4/32"]'.
ssh_ingress_cidrs = ["0.0.0.0/0"]

# Addresses allowed to reach the Dokploy dashboard (TCP 3000) on the server.
# Leave unset ("[]") to reach it only over Tailscale. To expose it publicly
# too, narrow this to known addresses, same JSON-list caveat as above, and
# add a matching DOKPLOY_INGRESS_CIDRS secret plus TF_VAR_dokploy_ingress_cidrs
# entry in the workflow's shared env anchor for CI/apply to pick it up.
# dokploy_ingress_cidrs = []

# MySQL HeatWave administrator; CI passes TF_VAR_mysql_admin_password instead.
mysql_admin_password = ""

# Where alarm notifications are emailed; CI passes TF_VAR_alarm_email instead.
alarm_email = ""
