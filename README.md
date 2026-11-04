# AWS Networking & CloudFormation Lab

**[English](README.md) | [Français](README.fr.md)**

A hands-on AWS networking lab for learning how to deploy a public frontend and a private MariaDB backend with **CloudFormation, AWS CLI, Bash, and Git/GitHub**. Build a VPC, control traffic with security groups, reach private servers through an SSH bastion, and install packages through an S3 Gateway Endpoint.

**New here? [Open the complete lab on `develop`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/develop).**

This `main` branch is the project entry point. The current infrastructure, database script, and reproduction guides live on `develop`. The step branches below preserve the project's learning progression; start with `develop` when reproducing the complete lab.

## What you will build

| Layer | Lab implementation |
| --- | --- |
| Network | VPC `10.10.0.0/16`, two public subnets and one private subnet across two AZs |
| Access | SSH bastion restricted to the administrator's IPv4; ProxyJump to frontend and backend |
| Frontend | Amazon Linux 2023 EC2 with an Apache demonstration page |
| Database | Private EC2 running MariaDB, reachable from the frontend on TCP 3306 |
| Private package access | S3 Gateway Endpoint for regional Amazon Linux repositories; optional NAT Gateway |
| Automation | CloudFormation infrastructure and a Bash script for MariaDB setup |

The frontend is a static demonstration page. The MariaDB connection is validated with a SQL client. The two AZs do not provide database replication or high availability. Systems Manager and CI/CD deployment are future work.

## Follow the lab in your language

| Guide | English | Français |
| --- | --- | --- |
| Project overview | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/README.md) | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/README.fr.md) |
| Prerequisites and costs | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/prerequisites.md) | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/prerequisites.md) |
| Architecture | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/architecture.md) | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/architecture.md) |
| Deployment and SSH | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/deployment-guide.md) | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/deployment-guide.md) |
| Validation and troubleshooting | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/validation-tests.md) | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/validation-tests.md) |
| Backup and cleanup | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/cleanup.md) | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/cleanup.md) |

## Explore the branches

| Branch | Purpose |
| --- | --- |
| [`main`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/main) | Project landing page and navigation |
| [`develop`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/develop) | Current complete lab and documentation |
| [`infra/01-vpc`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/01-vpc) | Step 01 — VPC foundation |
| [`infra/02-subnets-routing`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/02-subnets-routing) | Step 02 — Subnets, Internet Gateway, and routing |
| [`infra/03-security-groups`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/03-security-groups) | Step 03 — Security groups and permitted flows |
| [`infra/04-nat-gateway`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/04-nat-gateway) | Step 04 — Optional NAT Gateway |
| [`infra/05-ec2-instances`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/05-ec2-instances) | Step 05 — Bastion, frontend, and backend EC2 |
| [`infra/06-backend-database`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/06-backend-database) | Step 06 — Private backend access and S3 Gateway Endpoint |
| [`infra/07-mariadb-automation`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/07-mariadb-automation) | Step 07 — MariaDB setup automation with Bash |

Step branches are historical snapshots and may contain fewer resources or older instructions than `develop`. Manual installation and SQL validation are explained in the current guides. [Browse all branches](https://github.com/rachadk1/aws-networking-cloudformation-lab/branches), including documentation and review branches.

## Get started

```bash
git clone --branch develop https://github.com/rachadk1/aws-networking-cloudformation-lab.git
cd aws-networking-cloudformation-lab
```

Then follow the prerequisites and deployment guide in your language. Use your own AWS account, regional key pair, and public administrator IPv4. AWS resources may incur charges; read the cost and cleanup guides before deployment. Keep AWS credentials, SSH private keys, database passwords, and SQL dumps out of Git.
