# Prerequisites

[English](prerequisites.md) | [Français](../prerequisites.md)

[Home](../../README.md) · [Deployment](deployment-guide.md)

## Install AWS CLI v2 on your computer

**Install AWS CLI on your computer before following this lab.** Read the [Windows, macOS, and Linux installation guide](aws-cli-installation.md), then return here to configure AWS access. Close and reopen your terminal after installation; `aws --version` must report `aws-cli/2.`.

## Account and tools

- A personal or training AWS account with permission to create the VPC network, EC2 instances, and CloudFormation resources in the template. This lab does not require creating an IAM role. Use an authorized working identity rather than root credentials.
- AWS CLI v2, Git, and OpenSSH (`ssh`, `scp`). The guide's commands target **Bash**, including Git Bash on Windows. Do not paste them unchanged into PowerShell.
- The reference Region is `us-east-2` (Ohio). At least two AZs and the `t3.micro` instance type must be available to your account there.
- An EC2 key pair created in **that Region**, with its private key available on your computer. A key pair from another Region will not work.
- Your current public IPv4 address in `/32` format for `AdminCidr`. Using a VPN or changing your connection may change that address.

Check your tools and AWS identity locally:

```bash
git --version
aws --version
ssh -V
aws configure
aws sts get-caller-identity
```

`aws configure` is suitable for a lab account using authorized access keys. If your organization uses IAM Identity Center, use its SSO profile and `aws sso login --profile YOUR_PROFILE` instead. Never include access keys in screenshots, messages, or commits.

## Costs to review before starting

| Resource | What to check |
| --- | --- |
| 3 `t3.micro` EC2 instances | Running time, Region, and any credit eligibility |
| EBS volumes | Storage remains billable while instances are stopped |
| Public IPv4 addresses | Bastion and frontend addresses; an additional Elastic IP if NAT is enabled |
| Optional NAT Gateway | Hourly and data processing charges, even with little traffic |
| S3 Gateway Endpoint | No additional endpoint charge; other services and transfers retain their own pricing |

Do not assume that “micro” means free. Configure an AWS Budgets alert for your account; an alert does not stop resources. NAT is disabled in the standard walkthrough. Amazon Linux repositories hosted in S3 remain reachable from the backend through the regional Gateway Endpoint; this does not provide access to third-party repositories or the general internet.

Official sources: [EC2](https://aws.amazon.com/ec2/pricing/on-demand/), [EBS](https://aws.amazon.com/ebs/pricing/), [VPC, NAT, and IPv4](https://aws.amazon.com/vpc/pricing/), [S3 Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html), [Amazon Linux repositories without internet access](https://repost.aws/knowledge-center/ec2-al1-al2-update-yum-without-internet).

## Template parameters

| Parameter | Default | Value to choose |
| --- | --- | --- |
| `AdminCidr` | None | Your public IPv4 followed by `/32`; avoid `0.0.0.0/0` |
| `EC2KeyPairName` | `1st-web-server` | Your own key pair name in `us-east-2` |
| `LaunchEc2Instances` | `false` | `true` for the full lab |
| `EnableNatGateway` | `false` | Keep `false` for this walkthrough |
| `LatestAmiId` | Public SSM parameter for AL2023 x86_64 | Keep the default for a new stack |

Resolving a public SSM parameter does not configure Systems Manager on the instances. The template creates neither an IAM instance profile nor SSM endpoints.

## File security

Keep the private key on your computer. ProxyJump avoids copying it to the bastion. Store real parameters and backups outside the repository; `.gitignore` provides an additional safeguard. If a secret is exposed, revoke or rotate it: removing the file from the latest commit is not enough.
