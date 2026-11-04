# Architecture and learning path

[English](architecture.md) | [Français](../architecture.md)

[Home and diagram](../../README.md) · [Deployment](deployment-guide.md)

## Network actually defined by the template

| Logical resource | Network / role |
| --- | --- |
| `LabVPC` | `10.10.0.0/16` |
| `BastionSubnet` | `10.10.0.0/24`, first AZ returned by AWS |
| `FrontendSubnet` | `10.10.1.0/24`, same AZ as the bastion |
| `BackendSubnet` | `10.10.11.0/24`, second AZ returned by AWS |
| `PublicRouteTable` | `0.0.0.0/0` route to the Internet Gateway |
| `PrivateRouteTable` | Local VPC route and S3 prefix route to the Gateway Endpoint |
| `PrivateDefaultRoute` | `0.0.0.0/0` route to NAT, only when enabled |

A subnet is public here because its route table has a route to the IGW. The bastion and frontend receive public IPv4 addresses; the backend does not. Private EC2 addresses are assigned at deployment: always retrieve them from your own stack.

## Inbound flows

| Source | Destination | Port | Control |
| --- | --- | --- | --- |
| `AdminCidr` | Bastion | TCP 22 | `BastionSG` |
| `BastionSG` | Frontend | TCP 22 | `FrontendSG` |
| `BastionSG` | Backend | TCP 22 | `BackendSG` |
| IPv4 internet | Frontend | TCP 80 | `FrontendSG` |
| `FrontendSG` | Backend | TCP 3306 | `BackendSG` |

Referencing a security group authorizes network interfaces associated with that group; it does not authorize the entire subnet. As an additional control, the SQL account `network_app` is restricted to clients matching `10.10.1.%` and four privileges on `network_lab`.

Security groups are stateful. The template does not explicitly restrict egress and does not add a custom NACL. The Gateway Endpoint is associated only with the private route table; the frontend uses its internet route to install Apache and its MariaDB client.

## Seven learning steps

The current template combines the steps: one deployment creates the enabled resources together. This table explains the learning progression; it does not provide seven separate templates.

| Step | What to understand | Check |
| --- | --- | --- |
| 01 | VPC and CIDR | VPC `10.10.0.0/16`, DNS enabled |
| 02 | Subnets, IGW, and route tables | Public/private associations and separate AZs |
| 03 | Security groups | Review the five flows above |
| 04 | Optional NAT | Disabled by default; a general private default route exists only when enabled |
| 05 | EC2 and bastion | SSH ProxyJump and Apache page |
| 06 | S3 Gateway Endpoint and MariaDB | Installation from the private backend and SQL connection from the frontend |
| 07 | Bash automation | Run and rerun `setup-mariadb.sh` |

## What remains manual

CloudFormation does not run `setup-mariadb.sh`. Transfer and execute the script over SSH. It installs MariaDB, creates the database if absent, and grants permissions. If the SQL account already exists, its password is preserved. Otherwise, a password is generated and written to `/root/.config/aws-networking-lab/network-app.password` with restricted access.

The script does not revoke any pre-existing extra privileges, configure MariaDB TLS, load application tables, or manage backups. The secret file is written after account creation: if that write fails, rerunning does not regenerate the password for an account already created. Administrative recovery may then be necessary.

## Limitations

Using two AZs does not provide replication or high availability for the single backend. The site is an HTTP demonstration page with no application connection to the database. SSM, IAM for EC2, centralized secret management, and CI/CD are not integrated in this version.

References: [Gateway Endpoints and routing](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html), [security groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html).
