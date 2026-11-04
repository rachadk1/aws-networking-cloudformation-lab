# Back up and clean up

[English](cleanup.md) | [Français](../cleanup.md)

[Home](../../README.md) · [Deployment](deployment-guide.md)

The template defines no database retention policy. Deleting the stack terminates the instances; the backend's standard root volume is normally deleted on termination. **Back up useful data and verify the backup before deletion.** Setting `LaunchEc2Instances=false` also deletes the instances.

## 1. Optional SQL export — from your computer

If the database contains data to keep, use a destination **outside the repository**, for example:

```bash
umask 077
mkdir -p "$HOME/aws-lab-backups"
LAB_BACKUP="$HOME/aws-lab-backups/network_lab-$(date +%Y%m%d-%H%M%S).sql"
ssh aws-lab-backend 'sudo mariadb-dump --protocol=socket --single-transaction --databases network_lab' > "$LAB_BACKUP"
```

Check the command's exit status before continuing, the SQL statements, and the expected data. Test restoration into an isolated database if the data matters. A nonempty file alone is not sufficient proof. To ensure consistency with any nontransactional tables, pause writes during export.

This dump exports the database, not the `network_app` account or its password. The script can recreate the user on a new server. Keep the dump private; it may expose all database contents.

## 2. Identify the exact stack to delete

In the terminal where the variables are defined:

```bash
aws sts get-caller-identity
aws cloudformation describe-stacks \
  --stack-name "$LAB_STACK" --region "$AWS_REGION" \
  --query 'Stacks[0].[StackId,StackStatus]' --output table
```

Verify the account, Region, stack name, and backup before the next command.

## 3. Delete the stack

```bash
aws cloudformation delete-stack --stack-name "$LAB_STACK" --region "$AWS_REGION"
aws cloudformation wait stack-delete-complete --stack-name "$LAB_STACK" --region "$AWS_REGION"
```

Deletion can take several minutes, particularly if NAT was enabled. If the stack reaches `DELETE_FAILED`, inspect events and resolve the reported dependency; do not assume remaining resources have stopped incurring charges.

```bash
aws cloudformation describe-stack-events \
  --stack-name "$LAB_STACK" --region "$AWS_REGION" \
  --query 'StackEvents[].[LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table
```

## 4. Check for remaining resources

In the AWS console, check the instances, EBS volumes, snapshots, NAT Gateways, and Elastic IPs associated with your lab. Resources created outside CloudFormation — manual snapshots, S3 files, EC2 keys, and backups — are not necessarily removed with the stack. Delete only those you have identified as belonging to your lab.

Stopping EC2 reduces some charges but removes neither EBS volumes nor a NAT Gateway. Frontend and bastion public IPv4 addresses may change on restart. Billing updates may be delayed: review Billing/Cost Explorer after cleanup.

Keep or remove local backups and SSH entries according to your needs. Do not delete a key shared with another environment.

Sources: [deleting a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html), [VPC pricing](https://aws.amazon.com/vpc/pricing/).
