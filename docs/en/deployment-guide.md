# Deploy and reproduce the lab

[English](deployment-guide.md) | [Français](../deployment-guide.md)

[Home](../../README.md) · [Prerequisites](prerequisites.md) · [Tests](validation-tests.md) · [Cleanup](cleanup.md)

This walkthrough creates **a new stack** in your account. For an existing stack, read the dedicated section before making changes. All commands on your computer use Bash / Git Bash.

## 1. Prepare local parameters

From the repository root after cloning `develop`:

```bash
export AWS_REGION=us-east-2
export AWS_DEFAULT_REGION="$AWS_REGION"
export AWS_PAGER=""
LAB_STACK=aws-networking-lab
read -r -p 'Your public IPv4 in x.x.x.x/32 format: ' LAB_ADMIN_CIDR
read -r -p 'Your EC2 key pair name in us-east-2: ' LAB_KEY_PAIR
aws sts get-caller-identity
aws ec2 describe-key-pairs --key-names "$LAB_KEY_PAIR" --region "$AWS_REGION"
```

Choose a different stack name if that name is already in use. Keep the variables defined in your terminal throughout the walkthrough. Redefine them if you open a new terminal. Do not use an old IP address from the repository creator.

## 2. Validate the template

```bash
aws cloudformation validate-template \
  --template-body file://cloudformation/network-lab.yaml \
  --region "$AWS_REGION"
```

This command validates the template; it does not prove that deployment, quotas, or permissions will succeed. `CAPABILITY_IAM` is not required for steps 01–07: the template creates no IAM resource.

## 3. Prepare and inspect creation

The following command prepares a stack with **3 EC2 instances** and **no NAT Gateway**. A creation Change Set may leave a stack in `REVIEW_IN_PROGRESS` before execution, without having provisioned the network or instances yet.

```bash
aws cloudformation create-change-set \
  --stack-name "$LAB_STACK" \
  --change-set-name initial-lab \
  --change-set-type CREATE \
  --template-body file://cloudformation/network-lab.yaml \
  --parameters \
    "ParameterKey=AdminCidr,ParameterValue=$LAB_ADMIN_CIDR" \
    "ParameterKey=EC2KeyPairName,ParameterValue=$LAB_KEY_PAIR" \
    ParameterKey=LaunchEc2Instances,ParameterValue=true \
    ParameterKey=EnableNatGateway,ParameterValue=false \
  --region "$AWS_REGION"

aws cloudformation wait change-set-create-complete \
  --stack-name "$LAB_STACK" --change-set-name initial-lab --region "$AWS_REGION"

aws cloudformation describe-change-set \
  --stack-name "$LAB_STACK" --change-set-name initial-lab \
  --query 'Changes[].ResourceChange.[Action,LogicalResourceId,ResourceType,Replacement]' \
  --output table --region "$AWS_REGION"
```

Check the expected additions, including three `AWS::EC2::Instance` resources and `S3GatewayEndpoint`. There should be no NAT Gateway or NAT EIP. If preparation fails, run `describe-change-set` without `--query` to read `StatusReason`.

## 4. Execute deployment

After reviewing the Change Set and accepting the costs in your account:

```bash
aws cloudformation execute-change-set \
  --stack-name "$LAB_STACK" --change-set-name initial-lab --region "$AWS_REGION"

aws cloudformation wait stack-create-complete \
  --stack-name "$LAB_STACK" --region "$AWS_REGION"

aws cloudformation describe-stacks \
  --stack-name "$LAB_STACK" --query 'Stacks[0].Outputs' \
  --output table --region "$AWS_REGION"
```

If creation fails, inspect the events before retrying:

```bash
aws cloudformation describe-stack-events \
  --stack-name "$LAB_STACK" \
  --query 'StackEvents[].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table --region "$AWS_REGION"
```

## 5. Retrieve this stack's addresses

The outputs provide the public bastion address, public frontend address, and private backend address. Also retrieve the frontend's private address by targeting its instance ID from this stack:

```bash
LAB_FRONTEND_ID=$(aws cloudformation describe-stack-resource \
  --stack-name "$LAB_STACK" --logical-resource-id FrontendInstance \
  --query 'StackResourceDetail.PhysicalResourceId' --output text --region "$AWS_REGION")

aws ec2 describe-instances --instance-ids "$LAB_FRONTEND_ID" \
  --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress]' \
  --output table --region "$AWS_REGION"
```

Do not filter only by `Name` tags when several lab stacks coexist: their tags are identical. EC2 services may still be initializing after CloudFormation finishes creating the stack.

## 6. Configure SSH ProxyJump

On your computer, place the private key in `~/.ssh/` and restrict access. Example for a key you downloaded yourself:

```bash
chmod 400 ~/.ssh/my-lab-key.pem
```

On Windows, if OpenSSH rejects the permissions, also restrict the file's ACLs to your user. Do not copy the key to the bastion or disable host-key verification.

Open `~/.ssh/config`, preserve existing entries, and add these blocks after replacing the uppercase values with your own addresses and choosing your key filename. Use different aliases if you already have another lab.

```sshconfig
Host aws-lab-bastion
    HostName YOUR_BASTION_PUBLIC_IP
    User ec2-user
    IdentityFile ~/.ssh/my-lab-key.pem
    IdentitiesOnly yes

Host aws-lab-frontend
    HostName YOUR_FRONTEND_PRIVATE_IP
    User ec2-user
    IdentityFile ~/.ssh/my-lab-key.pem
    IdentitiesOnly yes
    ProxyJump aws-lab-bastion

Host aws-lab-backend
    HostName YOUR_BACKEND_PRIVATE_IP
    User ec2-user
    IdentityFile ~/.ssh/my-lab-key.pem
    IdentitiesOnly yes
    ProxyJump aws-lab-bastion
```

Verify host keys on the first connections, then test:

```bash
ssh aws-lab-bastion
exit
ssh aws-lab-frontend
exit
ssh aws-lab-backend
exit
```

The bastion's public IPv4 may change after a stop/start. Update `HostName` and check that `AdminCidr` still matches your current connection.

## 7. Initialize MariaDB

From your computer, at the repository root:

```bash
scp scripts/setup-mariadb.sh aws-lab-backend:~/setup-mariadb.sh
ssh aws-lab-backend
```

Run the following commands **on the backend**:

```bash
bash -n ~/setup-mariadb.sh
sudo bash ~/setup-mariadb.sh
sudo systemctl is-active mariadb
sudo mariadb --protocol=socket -e "SHOW DATABASES;"
sudo mariadb --protocol=socket -e "SHOW GRANTS FOR 'network_app'@'10.10.1.%';"
sudo ss -lntp | grep ':3306'
```

Expected results include `MariaDB setup completed successfully!`, `active`, the `network_lab` database, and SELECT/INSERT/UPDATE/DELETE privileges. Script status messages include both English and French. Check that MariaDB listens on a network interface reachable from the frontend; listening only on `127.0.0.1` is insufficient.

On a first installation, the script generates the `network_app` password. To view it **only in your private terminal**, without sharing it or storing it in Git:

```bash
sudo cat /root/.config/aws-networking-lab/network-app.password
```

If the script reports an existing user, it preserves that user's password and may not create this file. Use the password already set. The script does not rotate credentials.

Exit the backend with `exit`, then follow the [frontend → MariaDB tests](validation-tests.md). Without NAT, the backend can install packages from Amazon Linux repositories in S3 but cannot download the script directly from GitHub: this guide therefore uses `scp` through the bastion.

If Bash reports `\r` characters, convert the script to LF line endings in your editor and transfer it again. On the backend, a one-time fix is `sed -i 's/\r$//' ~/setup-mariadb.sh` before rerunning.

## Existing stack: update precautions

**No AWS update is needed to read or share the documentation.** Do not rerun the `CREATE` procedure against an existing stack.

For a future template change, prepare an `UPDATE` Change Set, explicitly preserve existing parameters with `UsePreviousValue=true`, and inspect actions and replacements before execution. `LatestAmiId` points to the latest AMI: even with `UsePreviousValue=true`, AWS may resolve a newer image and plan an EC2 replacement. Any template update therefore requires an actual Change Set review.

Setting `LaunchEc2Instances` to `false` deletes the instances; it does not merely stop them. Back up MariaDB before deleting or replacing the backend.

References: [AWS CLI create-change-set](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-change-set.html), [SSM parameters: UsePreviousValue and value resolution](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-supplied-parameter-types.html).
