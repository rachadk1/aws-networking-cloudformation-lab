# Validate the lab

[English](validation-tests.md) | [Français](../validation-tests.md)

[Home](../../README.md) · [Deployment](deployment-guide.md) · [Cleanup](cleanup.md)

Run these checks in your own environment. The results described are **expected outputs**, not evidence that the checks have run in your account.

## 1. Infrastructure — from your computer

Reuse `LAB_STACK` and `AWS_REGION` from the deployment guide.

```bash
aws cloudformation describe-stack-resources \
  --stack-name "$LAB_STACK" \
  --query 'StackResources[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]' \
  --output table --region "$AWS_REGION"

LAB_VPC_ID=$(aws cloudformation describe-stack-resource \
  --stack-name "$LAB_STACK" --logical-resource-id LabVPC \
  --query 'StackResourceDetail.PhysicalResourceId' --output text --region "$AWS_REGION")

aws ec2 describe-subnets --filters "Name=vpc-id,Values=$LAB_VPC_ID" \
  --query 'Subnets[].[CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
  --output table --region "$AWS_REGION"

aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$LAB_VPC_ID" \
  --query 'RouteTables[].{Id:RouteTableId,Associations:Associations,Routes:Routes}' \
  --output json --region "$AWS_REGION"

aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$LAB_VPC_ID" \
  --query 'VpcEndpoints[].{Type:VpcEndpointType,Service:ServiceName,State:State,RouteTables:RouteTableIds}' \
  --output json --region "$AWS_REGION"

aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$LAB_VPC_ID" \
  --query 'SecurityGroups[].{Id:GroupId,Name:GroupName,Ingress:IpPermissions}' \
  --output json --region "$AWS_REGION"
```

Expected: the three documented CIDRs, the backend in a different AZ, a public route to the IGW, and an S3 prefix route to the Gateway Endpoint in the private route table. Without NAT, that private table has no `0.0.0.0/0` route. Compare the security-group rules with the [flow table](architecture.md).

## 2. HTTP site — from your computer

```bash
LAB_FRONTEND_PUBLIC_IP=$(aws cloudformation describe-stacks \
  --stack-name "$LAB_STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendPublicIP'].OutputValue | [0]" \
  --output text --region "$AWS_REGION")
curl --fail --max-time 15 "http://$LAB_FRONTEND_PUBLIC_IP"
```

Expected: the page contains `AWS Networking Lab - Frontend` and its French equivalent. The site uses HTTP, not HTTPS. You can also open the URL in your browser. If the service is not ready, connect to the frontend and inspect `sudo systemctl status httpd` and `sudo tail -n 50 /var/log/cloud-init-output.log`.

## 3. Private database — on the backend

```bash
ssh aws-lab-backend
sudo systemctl is-active mariadb
sudo ss -lntp | grep ':3306'
sudo mariadb --protocol=socket -e "SHOW GRANTS FOR 'network_app'@'10.10.1.%';"
exit
```

Expected: an `active` service, a network listener on 3306, and the four application privileges on `network_lab` for the expected account. A network listener does not prove public access: the backend has no public IPv4 and `BackendSG` restricts SQL ingress to `FrontendSG`.

## 4. Frontend → MariaDB — on the frontend

From your computer:

```bash
ssh aws-lab-frontend
```

On the frontend, enter your stack's `BackendPrivateIP` output when prompted:

```bash
sudo dnf install -y mariadb105
read -r -p 'Your stack backend private IP: ' LAB_BACKEND_IP
mariadb --connect-timeout=10 -h "$LAB_BACKEND_IP" -P 3306 -u network_app -p network_lab
```

Enter the password interactively. Do not append it to `-p` in the command. Inside MariaDB:

```sql
SELECT USER(), CURRENT_USER(), DATABASE();
SHOW GRANTS;
EXIT;
```

Expected: database `network_lab`, a user connecting from the frontend network, and authenticated account `network_app@10.10.1.%`. An initially empty database is normal: the script creates no tables. This test validates private routing, security groups, the service, and authentication; the Apache page does not make this connection itself.

Also exit the frontend with `exit`.

## 5. Rerun the script — on the backend

```bash
ssh aws-lab-backend
sudo bash ~/setup-mariadb.sh
sudo systemctl is-active mariadb
exit
```

Expected: the message `User already exists. Existing password preserved.` and its French translation, successful completion, and a preserved database. Repeating the frontend SQL test with the same password confirms that rerunning preserved it. Idempotence is limited to the intended configuration; the script does not correct every form of drift or remove extra privileges.

## Targeted troubleshooting

| Symptom | Useful check |
| --- | --- |
| SSH timeout to bastion | Current public IPv4, running instance, IGW route, and `AdminCidr` matching your connection |
| `Permission denied (publickey)` | `ec2-user`, correct private key, and regional key pair |
| Direct SSH to frontend rejected | Use ProxyJump; its SG accepts SSH from the bastion SG |
| Backend `dnf` repository error | S3 endpoint state, private route-table association, DNS, and regional Amazon Linux repository |
| SQL timeout | Correct private address, listener on 3306, and `BackendSG` allowing `FrontendSG` |
| SQL `Access denied` | Password and account `network_app@10.10.1.%`; do not replace the host restriction with `%` to hide the problem |
| `Unknown database` | Successful script execution and `network_lab` on the correct backend |
| HTTP unavailable | Frontend public IPv4, SG port 80, `httpd` state, and cloud-init log |
| Missing secret file | An existing user keeps its original password; also check for an incomplete script run |

SSM access is not expected in this version. An empty `aws ssm describe-instance-information` result is therefore not a failure of lab steps 01–07.
