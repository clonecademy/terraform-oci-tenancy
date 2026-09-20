# PATH: /src/network.tf

module "vcn" {
  source = "github.com/clonecademy/terraform-oci-module-vcn?ref=v0.0.0"

  compartment_id = oci_identity_compartment.main.id
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.vcn.vcn_id
}

output "oracle_services_network_cidr_block" {
  description = "Service CIDR label routed to the service gateway"
  value       = module.vcn.oracle_services_network_cidr_block
}

output "internet_gateway_id" {
  description = "OCID of the internet gateway used by the public subnet"
  value       = module.vcn.internet_gateway_id
}

output "nat_gateway_id" {
  description = "OCID of the NAT gateway used for outbound traffic from the private subnet"
  value       = module.vcn.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP address that private subnet traffic is translated to"
  value       = module.vcn.nat_gateway_public_ip
}

output "service_gateway_id" {
  description = "OCID of the service gateway to the Oracle Services Network"
  value       = module.vcn.service_gateway_id
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = module.vcn.public_subnet_id
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = module.vcn.private_subnet_id
}
