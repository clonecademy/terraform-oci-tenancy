# PATH: /src/variables.tf

variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "region" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "private_key_password" {
  type      = string
  default   = null
  sensitive = true
}
