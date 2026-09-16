resource "oci_identity_compartment" "main" {
  compartment_id = var.tenancy_ocid
  name           = "main"
  description    = "The main compartment for cloud resources."
}

output "main_compartment_ocid" {
  value = oci_identity_compartment.main.id
}
