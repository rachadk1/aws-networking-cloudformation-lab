# Déployer et reproduire le lab

[Accueil](../README.md) · [Prérequis](prerequisites.md) · [Tests](validation-tests.md) · [Nettoyage](cleanup.md)

Ce parcours crée **une nouvelle stack** dans votre compte. Pour une stack existante, lire la section dédiée avant toute modification. Toutes les commandes de votre ordinateur utilisent Bash / Git Bash.

## 1. Préparer les paramètres locaux

Depuis la racine du dépôt cloné sur `develop` :

```bash
export AWS_REGION=us-east-2
export AWS_DEFAULT_REGION="$AWS_REGION"
export AWS_PAGER=""
LAB_STACK=aws-networking-lab
read -r -p 'Votre IPv4 publique au format x.x.x.x/32 : ' LAB_ADMIN_CIDR
read -r -p 'Nom de votre Key Pair EC2 dans us-east-2 : ' LAB_KEY_PAIR
aws sts get-caller-identity
aws ec2 describe-key-pairs --key-names "$LAB_KEY_PAIR" --region "$AWS_REGION"
```

Choisir un nom de stack distinct si une stack de ce nom existe déjà. Les variables doivent rester définies dans votre terminal pendant le parcours. Si vous changez de terminal, les redéfinir. Ne pas utiliser une ancienne adresse IP du créateur du dépôt.

## 2. Valider le template

```bash
aws cloudformation validate-template \
  --template-body file://cloudformation/network-lab.yaml \
  --region "$AWS_REGION"
```

Cette commande vérifie le template ; elle ne prouve pas que le déploiement, les quotas ou les permissions réussiront. Aucun `CAPABILITY_IAM` n'est nécessaire pour la version des étapes 01–07 : elle ne crée pas de ressource IAM.

## 3. Préparer puis examiner la création

La commande suivante prépare une stack avec **3 EC2** et **sans NAT Gateway**. Un Change Set de création peut laisser une stack en `REVIEW_IN_PROGRESS` avant exécution, sans avoir encore provisionné le réseau et les EC2.

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

Vérifier les ajouts attendus, dont trois `AWS::EC2::Instance` et le `S3GatewayEndpoint`. Il ne doit pas y avoir de NAT Gateway ni d'EIP NAT. En cas d'échec de préparation, utiliser `describe-change-set` sans `--query` pour lire `StatusReason`.

## 4. Exécuter le déploiement

Après avoir examiné le Change Set et accepté les coûts dans votre compte :

```bash
aws cloudformation execute-change-set \
  --stack-name "$LAB_STACK" --change-set-name initial-lab --region "$AWS_REGION"

aws cloudformation wait stack-create-complete \
  --stack-name "$LAB_STACK" --region "$AWS_REGION"

aws cloudformation describe-stacks \
  --stack-name "$LAB_STACK" --query 'Stacks[0].Outputs' \
  --output table --region "$AWS_REGION"
```

En cas d'échec, consulter les événements avant de relancer :

```bash
aws cloudformation describe-stack-events \
  --stack-name "$LAB_STACK" \
  --query 'StackEvents[].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table --region "$AWS_REGION"
```

## 5. Récupérer les adresses de cette stack

Les sorties fournissent le bastion public, le frontend public et le backend privé. Récupérer aussi l'adresse privée du frontend, en ciblant son ID dans cette stack :

```bash
LAB_FRONTEND_ID=$(aws cloudformation describe-stack-resource \
  --stack-name "$LAB_STACK" --logical-resource-id FrontendInstance \
  --query 'StackResourceDetail.PhysicalResourceId' --output text --region "$AWS_REGION")

aws ec2 describe-instances --instance-ids "$LAB_FRONTEND_ID" \
  --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,PublicIpAddress]' \
  --output table --region "$AWS_REGION"
```

Ne pas filtrer uniquement par tags `Name` si plusieurs stacks de lab coexistent : leurs tags sont identiques. Les EC2 peuvent encore initialiser leurs services après la fin de création de la stack.

## 6. Configurer SSH ProxyJump

Sur votre ordinateur, placer la clé privée dans `~/.ssh/` et limiter son accès. Exemple pour une clé que vous avez vous-même téléchargée :

```bash
chmod 400 ~/.ssh/ma-cle-lab.pem
```

Sous Windows, si OpenSSH refuse les permissions, restreindre aussi les ACL du fichier à votre utilisateur. Ne pas copier la clé sur le bastion et ne pas désactiver la vérification des clés d'hôte.

Ouvrir `~/.ssh/config`, préserver les entrées existantes et ajouter ces blocs en remplaçant les valeurs en majuscules par vos propres valeurs. Utiliser des alias différents si vous avez déjà un autre lab.

```sshconfig
Host aws-lab-bastion
    HostName VOTRE_IP_PUBLIQUE_BASTION
    User ec2-user
    IdentityFile ~/.ssh/ma-cle-lab.pem
    IdentitiesOnly yes

Host aws-lab-frontend
    HostName VOTRE_IP_PRIVEE_FRONTEND
    User ec2-user
    IdentityFile ~/.ssh/ma-cle-lab.pem
    IdentitiesOnly yes
    ProxyJump aws-lab-bastion

Host aws-lab-backend
    HostName VOTRE_IP_PRIVEE_BACKEND
    User ec2-user
    IdentityFile ~/.ssh/ma-cle-lab.pem
    IdentitiesOnly yes
    ProxyJump aws-lab-bastion
```

Valider les clés d'hôte lors des premières connexions, puis tester :

```bash
ssh aws-lab-bastion
exit
ssh aws-lab-frontend
exit
ssh aws-lab-backend
exit
```

Après un arrêt/redémarrage, l'IPv4 publique du bastion peut changer. Mettre à jour `HostName` et vérifier que `AdminCidr` correspond toujours à votre connexion actuelle.

## 7. Initialiser MariaDB

Depuis votre ordinateur, à la racine du dépôt :

```bash
scp scripts/setup-mariadb.sh aws-lab-backend:~/setup-mariadb.sh
ssh aws-lab-backend
```

Les commandes suivantes s'exécutent **sur le backend** :

```bash
bash -n ~/setup-mariadb.sh
sudo bash ~/setup-mariadb.sh
sudo systemctl is-active mariadb
sudo mariadb --protocol=socket -e "SHOW DATABASES;"
sudo mariadb --protocol=socket -e "SHOW GRANTS FOR 'network_app'@'10.10.1.%';"
sudo ss -lntp | grep ':3306'
```

Le résultat attendu inclut `MariaDB setup completed successfully!`, `active`, la base `network_lab` et les permissions SELECT/INSERT/UPDATE/DELETE. Vérifier que MariaDB écoute sur une interface réseau permettant l'accès depuis le frontend ; une écoute uniquement sur `127.0.0.1` ne suffit pas.

Sur une première installation, le script génère le mot de passe de `network_app`. Pour le consulter **dans votre terminal privé uniquement**, sans le partager ni l'enregistrer dans Git :

```bash
sudo cat /root/.config/aws-networking-lab/network-app.password
```

S'il annonce que l'utilisateur existe déjà, le script conserve son mot de passe et ne crée pas nécessairement ce fichier. Utiliser le mot de passe déjà défini. Le script n'effectue pas de rotation des identifiants.

Quitter le backend avec `exit`, puis suivre les [tests frontend → MariaDB](validation-tests.md). Sans NAT, le backend peut installer les paquets provenant des dépôts Amazon Linux dans S3, mais ne peut pas télécharger directement le script depuis GitHub : c'est pourquoi ce guide utilise `scp` via le bastion.

Si Bash signale des caractères `\r`, convertir le script en fins de ligne LF dans votre éditeur puis le transférer à nouveau. Sur le backend, une correction ponctuelle est possible avec `sed -i 's/\r$//' ~/setup-mariadb.sh` avant de relancer.

## Stack existante : précautions de mise à jour

Pour la PR de documentation, **aucune mise à jour AWS n'est nécessaire**. Ne pas relancer la procédure `CREATE` sur une stack existante.

Pour une future modification du template, préparer un Change Set de type `UPDATE`, reprendre explicitement les paramètres existants avec `UsePreviousValue=true`, puis vérifier les actions et remplacements avant exécution. Le paramètre `LatestAmiId` pointe vers la dernière AMI : même avec `UsePreviousValue=true`, AWS peut résoudre une nouvelle image et prévoir un remplacement EC2. Une modification du template demande donc un examen réel du Change Set.

Basculer `LaunchEc2Instances` à `false` supprime les EC2 ; cela ne les arrête pas simplement. Sauvegarder MariaDB avant une suppression ou un remplacement du backend.

Référence : [AWS CLI create-change-set](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-change-set.html).

Pour les paramètres SSM : [comportement de UsePreviousValue et résolution des valeurs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-supplied-parameter-types.html).
