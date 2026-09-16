# PATH: /src/database.tf

# Place the DB system in another availability domain if out of capacity.
variable "mysql_availability_domain_number" {
  description = "The availability domain that the MySQL HeatWave DB system will be placed in."
  type        = number
  default     = 1

  # Prevent index out of bounds errors.
  validation {
    condition     = var.mysql_availability_domain_number >= 1 && var.mysql_availability_domain_number == floor(var.mysql_availability_domain_number)
    error_message = "Availability domain number must be a whole number of 1 or greater."
  }
}

variable "mysql_admin_username" {
  description = "Username of the MySQL administrative user."
  type        = string
  default     = "admin"
}

variable "mysql_admin_password" {
  description = "Password of the MySQL administrative user."
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.mysql_admin_password) >= 8 &&
      length(var.mysql_admin_password) <= 32 &&
      can(regex("[A-Z]", var.mysql_admin_password)) &&
      can(regex("[a-z]", var.mysql_admin_password)) &&
      can(regex("[0-9]", var.mysql_admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.mysql_admin_password))
    )
    error_message = "Administrator password must be between 8 and 32 characters, and contain at least 1 uppercase, 1 lowercase, 1 numeric, and 1 special character."
  }
}

# Data import only happens when a DB system is created; see the lifecycle block below.
variable "mysql_import_source_url" {
  description = "Object Storage PAR URL (bucket/prefix with object listing, or a @.manifest.json object) to import data from when the DB system is created."
  type        = string
  default     = null
  sensitive   = true
}

variable "mysql_shape_name" {
  description = "Always Free MySQL HeatWave DB system shape (1 ECPU, 8 GB memory)."
  type        = string
  default     = "MySQL.Free"
}

variable "heatwave_shape_name" {
  description = "Always Free HeatWave cluster node shape (16 GB memory)."
  type        = string
  default     = "HeatWave.Free"
}

variable "mysql_data_storage_size_in_gb" {
  description = "Data storage size, in GB, for the DB system."
  type        = number
  default     = 50

  validation {
    condition     = var.mysql_data_storage_size_in_gb <= 50
    error_message = "Always Free MySQL HeatWave storage maxes out at 50 GB."
  }
}

data "oci_identity_availability_domains" "mysql" {
  compartment_id = var.tenancy_ocid
}

# MySQL HeatWave is always free only in the home region.
data "oci_identity_region_subscriptions" "mysql" {
  tenancy_id = var.tenancy_ocid
}

data "oci_core_vcn" "main" {
  vcn_id = module.vcn.vcn_id
}

locals {
  mysql_availability_domain = data.oci_identity_availability_domains.mysql.availability_domains[var.mysql_availability_domain_number - 1].name

  mysql_home_region = one([
    for subscription in data.oci_identity_region_subscriptions.mysql.region_subscriptions :
    subscription.region_name if subscription.is_home_region
  ])

  mysql_port        = 3306
  mysql_port_x      = 33060
  mysql_rest_port   = 443
  mysql_studio_port = 8443

  # The private subnet's security list only allows SSH and ICMP, so open the MySQL ports to the VCN with an NSG.
  mysql_ingress_rules = {
    for pair in setproduct(data.oci_core_vcn.main.cidr_blocks, [local.mysql_port, local.mysql_port_x, local.mysql_rest_port, local.mysql_studio_port]) :
    "${pair[0]}-${pair[1]}" => { source = pair[0], port = pair[1] }
  }
}

resource "oci_core_network_security_group" "mysql" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "main-mysql-nsg"
}

resource "oci_core_network_security_group_security_rule" "mysql_ingress" {
  for_each = local.mysql_ingress_rules

  network_security_group_id = oci_core_network_security_group.mysql.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value.source
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = each.value.port
      max = each.value.port
    }
  }
}

# DB systems act through their resource principal: without these statements, creating a DB system with an NSG fails with
# AuthorizationFailed. See https://docs.oracle.com/en-us/iaas/mysql-database/doc/mandatory-policies-permissions.html.
resource "oci_identity_policy" "mysql" {
  compartment_id = var.tenancy_ocid
  name           = "main-mysql-policy"
  description    = "Allows MySQL HeatWave DB systems in the main compartment to use the network and read Lakehouse data."

  statements = [
    "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment id ${oci_identity_compartment.main.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.main.id}'}",
    "Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id ${oci_identity_compartment.main.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.main.id}'}",
    # HeatWave Lakehouse loading from buckets without a PAR.
    "Allow any-user to read buckets in compartment id ${oci_identity_compartment.main.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.main.id}'}",
    "Allow any-user to read objects in compartment id ${oci_identity_compartment.main.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.main.id}'}",
  ]
}

resource "oci_mysql_mysql_db_system" "main" {
  # IAM policies must exist before the service provisions the DB system's VNIC.
  depends_on = [oci_identity_policy.mysql]

  compartment_id      = oci_identity_compartment.main.id
  availability_domain = local.mysql_availability_domain
  display_name        = "main-mysql-db-system"
  shape_name          = var.mysql_shape_name

  subnet_id      = module.vcn.private_subnet_id
  nsg_ids        = [oci_core_network_security_group.mysql.id]
  hostname_label = "mysql"
  port           = local.mysql_port
  port_x         = local.mysql_port_x

  admin_username = var.mysql_admin_username
  admin_password = var.mysql_admin_password

  # Standalone; high availability is not supported on Always Free.
  is_highly_available = false

  # Always Free storage is fixed at 50 GB and cannot auto-expand.
  data_storage_size_in_gb = var.mysql_data_storage_size_in_gb

  # Read-only database mode and administrators-only access mode are unavailable with HeatWave and REST enabled.
  database_mode = "READ_WRITE"
  access_mode   = "UNRESTRICTED"

  crash_recovery = "ENABLED"

  # No backup_policy block: Always Free DB systems reject one at creation and enable automatic backups with 1 day
  # retention by default. Point-in-time recovery is not available on Always Free.

  # MySQL Studio.
  database_console {
    status = "ENABLED"
    port   = local.mysql_studio_port
  }

  rest {
    configuration = "DBSYSTEM_ONLY"
    port          = local.mysql_rest_port
  }

  encrypt_data {
    key_generation_type = "SYSTEM"
  }

  secure_connections {
    certificate_generation_type = "SYSTEM"
  }

  dynamic "source" {
    for_each = var.mysql_import_source_url == null ? [] : [var.mysql_import_source_url]

    content {
      source_type = "IMPORTURL"
      source_url  = source.value
    }
  }

  # No maintenance block: MySQL HeatWave Service assigns the maintenance window automatically.

  lifecycle {
    # Both force replacement, which would destroy the database. The service never returns source_url, so without this
    # every plan after an import would rebuild the DB system. A new import URL only applies when a DB system is created;
    # rotate the admin password in MySQL instead.
    ignore_changes = [admin_password, source]

    # Throw an error if the DB system is provisioned in a region other than the home region.
    precondition {
      condition     = var.region == local.mysql_home_region
      error_message = "The Always Free MySQL HeatWave DB system exists only in the tenancy's home region (${local.mysql_home_region}); region is set to ${var.region}, where this DB system would be billed."
    }
  }
}

resource "oci_mysql_heat_wave_cluster" "main" {
  db_system_id         = oci_mysql_mysql_db_system.main.id
  shape_name           = var.heatwave_shape_name
  cluster_size         = 1
  is_lakehouse_enabled = true
}

output "mysql_db_system_id" {
  description = "OCID of the always-free MySQL HeatWave DB system"
  value       = oci_mysql_mysql_db_system.main.id
}

output "mysql_ip_address" {
  description = "Private IP address of the DB system's primary endpoint in the private subnet"
  value       = oci_mysql_mysql_db_system.main.ip_address
}

output "mysql_hostname" {
  description = "Private DNS hostname of the DB system's primary endpoint"
  value       = try(oci_mysql_mysql_db_system.main.endpoints[0].hostname, null)
}

output "mysql_port" {
  description = "MySQL classic protocol port"
  value       = oci_mysql_mysql_db_system.main.port
}

output "mysql_port_x" {
  description = "MySQL X Protocol port"
  value       = oci_mysql_mysql_db_system.main.port_x
}

output "mysql_rest_port" {
  description = "MySQL REST service port"
  value       = local.mysql_rest_port
}

output "mysql_studio_port" {
  description = "MySQL Studio (database console) port"
  value       = local.mysql_studio_port
}

output "heatwave_cluster_id" {
  description = "OCID of the always-free HeatWave cluster attached to the DB system"
  value       = oci_mysql_heat_wave_cluster.main.id
}
