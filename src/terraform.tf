terraform {
  required_version = "~> 1.16.0"

  backend "oci" {
    bucket    = "terraform"
    namespace = "ax99ng5pq6oc"
    key       = "tenancy.tfstate"
    region    = "us-sanjose-1"
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.1.0"
    }
  }
}
