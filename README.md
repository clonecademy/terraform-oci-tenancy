# Clonecademy — Oracle Cloud Tenancy

Infrastructure for Clonecademy on Oracle Cloud Infrastructure (OCI), managed with Terraform. Everything runs within OCI's
[Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) limits, so
the tenancy costs nothing to run.

## What it provisions

| Resource | Details |
| --- | --- |
| Server | An Always Free Ubuntu compute instance with a reserved public IP and a 200 GB boot volume. It accepts SSH from allowed addresses only, web traffic on ports 80 and 443, and direct Tailscale connections. The Dokploy dashboard (port 3000) is reachable over Tailscale, and publicly too if `dokploy_ingress_cidrs` is set. |
| Database | A MySQL HeatWave DB system with a HeatWave cluster (Lakehouse enabled), including MySQL Studio and the MySQL REST service. It sits in a private subnet and can be reached only from inside the network, for example from the server. |
| Network | A virtual cloud network with a public subnet for the server and a private subnet for the database. |
| Alarms | Email notifications when the server needs attention. |

Everything is created in the `main` compartment, except for the `terraform` bucket that holds the Terraform state.

## Connecting

Connection details are published as Terraform outputs:

```sh
cd src
terraform output instance_ssh_command   # ssh as the default ubuntu user
terraform output instance_public_ip
terraform output mysql_hostname         # private hostname; resolves inside the network
terraform output mysql_port             # 3306 (X Protocol: mysql_port_x, 33060)
```

SSH works only from the addresses in `ssh_ingress_cidrs`. Ask a maintainer to add yours if you need access.

## Alarm emails

Alarms go to the address in `alarm_email`. OCI sends a confirmation email to that address first, and no alarms are
delivered until someone clicks the confirmation link.

## Making changes

Changes reach the tenancy only through pull requests to `main`:

1. Open a pull request. The pipeline posts the Terraform plan as a comment so you can see exactly what will change.
2. Merge it once it has been reviewed.
3. A maintainer approves the apply in the `production` environment. The change is applied only if the plan still matches
   the one that was reviewed. Otherwise the run stops and has to be started again.

Plans are posted publicly, so keep secrets and personal details out of variables that are not marked sensitive.

## Configuration

The pipeline reads its inputs from these GitHub Secrets:

| Secret | Purpose |
| --- | --- |
| `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, `OCI_REGION` | OCI API key authentication |
| `OCI_PRIVATE_KEY` | PEM contents of the OCI API signing key |
| `SSH_PUBLIC_KEY` | Public key installed on the server |
| `SSH_INGRESS_CIDRS` | Addresses allowed to reach SSH, as JSON, e.g. `["203.0.113.4/32"]` |
| `MYSQL_ADMIN_PASSWORD` | MySQL administrator password: 8–32 characters, with at least one uppercase letter, one lowercase letter, one digit, and one special character |
| `ALARM_EMAIL` | Where alarm notifications are sent |

To run Terraform locally, copy `src/example.tfvars` to `src/terraform.tfvars` and fill it in.

## Related repositories

- [terraform-oci-module-vcn](https://github.com/clonecademy/terraform-oci-module-vcn): the network
- [terraform-oci-module-vps](https://github.com/clonecademy/terraform-oci-module-vps): the server
