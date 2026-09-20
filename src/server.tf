# PATH: /src/server.tf

variable "ssh_public_key_path" {
  description = "Path to the SSH public key installed on the server via authorized_keys."
  type        = string
}

variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the server. Narrow this to known addresses, or pass an empty list once the server is reachable over a VPN."
  type        = list(string)
}

module "vps" {
  source = "github.com/clonecademy/terraform-oci-module-vps?ref=v0.2.0"

  compartment_id      = oci_identity_compartment.main.id
  tenancy_ocid        = var.tenancy_ocid
  region              = var.region
  subnet_id           = module.vcn.public_subnet_id
  ssh_public_key_path = var.ssh_public_key_path
  ssh_ingress_cidrs   = var.ssh_ingress_cidrs
}

output "instance_availability_domain" {
  description = "Availability domain the instance was placed in"
  value       = module.vps.instance_availability_domain
}

output "instance_boot_volume_size_in_gbs" {
  description = "Boot volume size, which consumes the entire 200 GB Always Free block volume allowance"
  value       = module.vps.instance_boot_volume_size_in_gbs
}

output "instance_id" {
  description = "OCID of the always-free compute instance"
  value       = module.vps.instance_id
}

output "instance_image_name" {
  description = "Display name of the Ubuntu image the instance was launched from"
  value       = module.vps.instance_image_name
}

output "instance_private_ip" {
  description = "Private IP address of the instance in the public subnet"
  value       = module.vps.instance_private_ip
}

output "instance_public_ip" {
  description = "Reserved public IP address of the instance"
  value       = module.vps.instance_public_ip
}

output "instance_ssh_command" {
  description = "Command to connect to the instance as the default ubuntu user"
  value       = module.vps.instance_ssh_command
}
