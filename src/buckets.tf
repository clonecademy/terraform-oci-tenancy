# PATH: /src/buckets.tf

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = var.tenancy_ocid
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "terraform"

  access_type  = "NoPublicAccess"
  storage_tier = "Standard"

  versioning = "Enabled"

  lifecycle {
    prevent_destroy = true
  }
}
