# Install AWS CLI v2 on your computer

[English](aws-cli-installation.md) | [Français](../aws-cli-installation.md)

[Home](../../README.md) · [Prerequisites and AWS configuration](prerequisites.md) · [Deployment](deployment-guide.md)

## Why does this lab need AWS CLI?

AWS CLI lets you run `aws` commands from your computer: validate the template, create a CloudFormation stack, retrieve EC2 addresses, and delete the lab. **Install AWS CLI v2 on the computer used to follow the guide before running any AWS command.** Installing the software creates no AWS resources and does not automatically sign you in to an account.

Git Bash, PowerShell, and Terminal are command environments; they do not replace AWS CLI. This repository's deployment walkthrough uses Bash / Git Bash.

## 1. Windows — official installer

1. Download the [AWS CLI v2 installer for 64-bit Windows](https://awscli.amazonaws.com/AWSCLIV2.msi).
2. Open the `.msi` file, follow the wizard, and approve installation with administrator rights if prompted by Windows.
3. Close and reopen PowerShell **and Git Bash** to load the updated `PATH`. If you use VS Code's integrated terminal, restart VS Code too.
4. In the new terminal, check:

```powershell
aws --version
```

The output must start with `aws-cli/2.`; the exact version number may vary. Alternatively, from **PowerShell**:

```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

This command opens the installation wizard. Finish the wizard before reopening your terminal. If you do not have administrator rights, AWS also provides a [current-user installer](https://awscli.amazonaws.com/AWSCLIV2-User.msi).

Install the MSI through Windows; do not run the Linux commands below in Git Bash. After installation, the same `aws` program can be used from PowerShell, Command Prompt, and Git Bash when its directory is on their `PATH`.

## 2. macOS — official package

From Terminal, download the package and run the system installer:

```bash
curl -fL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg ./AWSCLIV2.pkg -target /
aws --version
```

The password requested by `sudo` is your macOS account password. Verification output must start with `aws-cli/2.`. You can also download the [official PKG package](https://awscli.amazonaws.com/AWSCLIV2.pkg) in your browser and open it to follow the graphical wizard. Check current macOS requirements in the AWS documentation before installing.

## 3. Linux — select the architecture

These commands apply to a Linux distribution supported by the AWS installer with the glibc library. To identify your computer's architecture:

```bash
uname -m
```

| Result | AWS archive to use |
| --- | --- |
| `x86_64` | `awscli-exe-linux-x86_64.zip` |
| `aarch64` or `arm64` | `awscli-exe-linux-aarch64.zip` |

You need `curl`, `unzip`, and `sudo` access for a system installation. Example of installing these tools on Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y curl unzip
```

Download and install **only one** archive matching your architecture. Run the commands in a temporary or downloads directory, outside the Git repository.

For Linux x86_64:

```bash
curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

For Linux ARM64:

```bash
curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

AWS also documents PGP signature verification for the archives in its [detailed instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). If signature verification fails, do not install the package.

## 4. Check the version and executable path

In the terminal you will use for the lab:

```bash
aws --version
```

Expected: `aws-cli/2.` followed by the version and system information. To locate the executable:

| Terminal | Command |
| --- | --- |
| PowerShell | `Get-Command aws` |
| Windows Command Prompt | `where aws` |
| Bash / Git Bash / macOS Terminal | `command -v aws` |

| Problem | Action |
| --- | --- |
| `aws: command not found` or unrecognized command | Close and reopen the terminal; restart VS Code if needed; check `PATH` |
| AWS CLI works in PowerShell but not Git Bash | Reopen Git Bash after installation and check `command -v aws` |
| Output starts with `aws-cli/1.` | An older version takes precedence; identify its path and follow the official v2 migration guide |
| Installer detects an existing installation | Follow official update instructions for your installation method |
| `Unable to locate credentials` | Software is installed, but the AWS identity still needs configuration |
| `ExpiredToken` | Renew the temporary or SSO session you are using |

## 5. Configure AWS access before deployment

Return to the [prerequisites](prerequisites.md) to configure your account's authorized identity: an SSO profile or the authentication method suitable for your lab. AWS credentials are not installed with the software. An AWS console password is not a Secret Access Key.

This lab uses Region **`us-east-2` (Ohio)** and output format **`json`**. After configuring your identity, verify access:

```bash
aws sts get-caller-identity
```

The command should display the expected identity and account. If it fails, resolve authentication before running CloudFormation. Never share or commit your access keys or credential files.

## Official sources

- [AWS CLI v2 installation and updates — Windows, macOS, and Linux](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [AWS CLI configuration and authentication](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
- [Migration from AWS CLI v1](https://docs.aws.amazon.com/cli/latest/userguide/cliv2-migration.html)
