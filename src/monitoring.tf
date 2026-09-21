# PATH: /src/monitoring.tf

# Sensitive so that the address stays out of plans, which are posted to pull requests on this public repository.
variable "alarm_email" {
  description = "Email address that alarm notifications are sent to. OCI emails a confirmation link that must be clicked before any alarms are delivered."
  type        = string
  sensitive   = true
}

# One topic for the whole tenancy so that alarms from every resource reach the same inbox. Always Free covers 1,000 emails a
# month.
resource "oci_ons_notification_topic" "alarms" {
  compartment_id = oci_identity_compartment.main.id
  name           = "main-alarms"
  description    = "Alarm notifications for resources in the main compartment."
}

resource "oci_ons_subscription" "alarms_email" {
  compartment_id = oci_identity_compartment.main.id
  topic_id       = oci_ons_notification_topic.alarms.id
  protocol       = "EMAIL"
  endpoint       = var.alarm_email
}

output "alarms_topic_id" {
  description = "OCID of the Notifications topic that alarms deliver to"
  value       = oci_ons_notification_topic.alarms.id
}
