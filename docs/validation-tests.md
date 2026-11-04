# Valider le lab

[Français](validation-tests.md) | [English](en/validation-tests.md)

[Accueil](../README.fr.md) · [Déploiement](deployment-guide.md) · [Nettoyage](cleanup.md)

Ces contrôles sont à exécuter dans votre propre environnement. Les résultats décrits sont des **attendus**, pas une preuve d'exécution sur votre compte.

## 1. Infrastructure — depuis votre ordinateur

Réutiliser `LAB_STACK` et `AWS_REGION` du guide de déploiement.

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

Attendus : les trois CIDR documentés, le backend dans une AZ différente, une route publique vers l'IGW, et une route de préfixe S3 vers le Gateway Endpoint dans la table privée. Sans NAT, cette table privée n'a pas de route `0.0.0.0/0`. Vérifier les règles SG avec le [tableau des flux](architecture.md).

## 2. Site HTTP — depuis votre ordinateur

```bash
LAB_FRONTEND_PUBLIC_IP=$(aws cloudformation describe-stacks \
  --stack-name "$LAB_STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendPublicIP'].OutputValue | [0]" \
  --output text --region "$AWS_REGION")
curl --fail --max-time 15 "http://$LAB_FRONTEND_PUBLIC_IP"
```

Attendu : la page contient `AWS Networking Lab - Frontend` et son équivalent français. Le site utilise HTTP, pas HTTPS. Si nécessaire, ouvrir cette URL dans votre navigateur. Si le service n'est pas encore prêt, se connecter au frontend et examiner `sudo systemctl status httpd` et `sudo tail -n 50 /var/log/cloud-init-output.log`.

## 3. Base privée — sur le backend

```bash
ssh aws-lab-backend
sudo systemctl is-active mariadb
sudo ss -lntp | grep ':3306'
sudo mariadb --protocol=socket -e "SHOW GRANTS FOR 'network_app'@'10.10.1.%';"
exit
```

Attendus : service `active`, écoute réseau sur 3306 et quatre privilèges applicatifs sur `network_lab` pour le compte attendu. Une écoute réseau ne prouve pas que le port est public : le backend n'a pas d'IPv4 publique et `BackendSG` limite l'entrée SQL à `FrontendSG`.

## 4. Frontend → MariaDB — sur le frontend

Depuis votre ordinateur :

```bash
ssh aws-lab-frontend
```

Sur le frontend, remplacer l'adresse demandée par la sortie `BackendPrivateIP` de votre stack :

```bash
sudo dnf install -y mariadb105
read -r -p 'IP privée du backend de votre stack : ' LAB_BACKEND_IP
mariadb --connect-timeout=10 -h "$LAB_BACKEND_IP" -P 3306 -u network_app -p network_lab
```

Le mot de passe est demandé de façon interactive. Ne pas l'ajouter après `-p` dans la commande. Dans MariaDB :

```sql
SELECT USER(), CURRENT_USER(), DATABASE();
SHOW GRANTS;
EXIT;
```

Attendus : base `network_lab`, utilisateur connecté depuis le réseau frontend et compte authentifié `network_app@10.10.1.%`. Une base initialement vide est normale : le script ne crée aucune table. Ce test valide le routage privé, les SG, le service et l'authentification ; la page Apache ne réalise pas elle-même cette connexion.

Quitter aussi le frontend avec `exit`.

## 5. Réexécuter le script — sur le backend

```bash
ssh aws-lab-backend
sudo bash ~/setup-mariadb.sh
sudo systemctl is-active mariadb
exit
```

Attendus : message `User already exists. Existing password preserved.` accompagné de sa traduction française, succès final et base conservée. Refaire le test SQL du frontend avec le même mot de passe confirme que la réexécution l'a préservé. Il s'agit d'une idempotence limitée à la configuration prévue ; le script ne corrige pas toutes les dérives et ne supprime pas les permissions supplémentaires.

## Dépannage ciblé

| Symptôme | Vérification utile |
| --- | --- |
| SSH timeout vers le bastion | IPv4 publique actuelle, instance active, route IGW, `AdminCidr` correspondant à votre connexion |
| `Permission denied (publickey)` | Compte `ec2-user`, bonne clé privée et Key Pair régionale |
| SSH direct vers le frontend refusé | Utiliser ProxyJump ; son SG accepte SSH depuis le SG du bastion |
| Backend : erreur de dépôt `dnf` | État de l'endpoint S3, association à la table privée, DNS et dépôt régional Amazon Linux |
| SQL timeout | Adresse privée correcte, écoute 3306, `BackendSG` autorisant `FrontendSG` |
| SQL `Access denied` | Mot de passe et compte `network_app@10.10.1.%` ; ne pas remplacer la règle par `%` pour masquer le problème |
| `Unknown database` | Exécution réussie du script et présence de `network_lab` sur le bon backend |
| HTTP indisponible | IPv4 publique du frontend, port 80 du SG, état `httpd`, journal cloud-init |
| Fichier secret absent | Un utilisateur préexistant garde son ancien mot de passe ; examiner aussi une éventuelle exécution incomplète |

Aucun accès SSM n'est attendu dans cette version. Un résultat vide de `aws ssm describe-instance-information` n'est donc pas un échec du lab 01–07.
