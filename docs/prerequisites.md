# Prérequis

[Français](prerequisites.md) | [English](en/prerequisites.md)

[Accueil](../README.fr.md) · [Déploiement](deployment-guide.md)

## Installer AWS CLI v2 sur le PC

**AWS CLI doit être installé sur votre ordinateur avant de suivre ce lab.** Consultez le [guide d’installation Windows, macOS et Linux](aws-cli-installation.md), puis revenez ici pour configurer votre accès AWS. Fermez et rouvrez votre terminal après l’installation ; `aws --version` doit afficher `aws-cli/2.`.

## Compte et outils

- Un compte AWS personnel ou de formation avec autorisation de créer le réseau VPC, les EC2 et les ressources CloudFormation du template. Ce lab ne nécessite pas de créer de rôle IAM. Utiliser une identité de travail autorisée plutôt que les identifiants root.
- AWS CLI v2, Git et OpenSSH (`ssh`, `scp`). Les commandes du guide ciblent **Bash**, notamment Git Bash sous Windows. Ne pas les coller telles quelles dans PowerShell.
- La région de référence est `us-east-2` (Ohio). Elle doit disposer d'au moins deux AZ accessibles et du type `t3.micro`.
- Une Key Pair EC2 créée dans **cette région**, dont vous détenez la clé privée. Une Key Pair d'une autre région ne convient pas.
- Votre IPv4 publique actuelle, au format `/32`, à renseigner dans `AdminCidr`. Un VPN ou un changement de connexion peut modifier cette adresse.

Vérifier les outils et l'identité AWS localement :

```bash
git --version
aws --version
ssh -V
aws configure
aws sts get-caller-identity
```

`aws configure` convient à un compte de lab utilisant des clés d'accès autorisées. Si votre organisation utilise IAM Identity Center, employer son profil SSO et `aws sso login --profile VOTRE_PROFIL` à la place. Ne transmettre aucune clé d'accès dans les captures, messages ou commits.

## Coûts à examiner avant de lancer

| Ressource | Point à vérifier |
| --- | --- |
| 3 EC2 `t3.micro` | Durée de fonctionnement, région et éligibilité éventuelle aux crédits |
| Volumes EBS | Stockage facturable même lorsque les EC2 sont arrêtées |
| IPv4 publiques | Adresses du bastion et du frontend ; Elastic IP supplémentaire si NAT activé |
| NAT Gateway optionnel | Frais horaires et traitement des données, même avec peu de trafic |
| S3 Gateway Endpoint | Pas de frais supplémentaires pour l'endpoint ; les autres services et transferts gardent leur tarification |

Ne pas supposer que « micro » signifie gratuit. Configurer une alerte AWS Budgets adaptée à son compte ; une alerte n'arrête pas les ressources. NAT est désactivé dans le parcours standard. Les dépôts Amazon Linux hébergés dans S3 restent accessibles depuis le backend via le Gateway Endpoint régional ; les dépôts tiers et l'accès Internet général ne le deviennent pas.

Sources officielles : [EC2](https://aws.amazon.com/ec2/pricing/on-demand/), [EBS](https://aws.amazon.com/ebs/pricing/), [VPC, NAT et IPv4](https://aws.amazon.com/vpc/pricing/), [S3 Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html), [dépôts Amazon Linux sans Internet](https://repost.aws/knowledge-center/ec2-al1-al2-update-yum-without-internet).

## Paramètres du template

| Paramètre | Défaut | Valeur à choisir |
| --- | --- | --- |
| `AdminCidr` | Aucun | Votre IPv4 publique suivie de `/32` ; éviter `0.0.0.0/0` |
| `EC2KeyPairName` | `1st-web-server` | Nom de votre propre Key Pair dans `us-east-2` |
| `LaunchEc2Instances` | `false` | `true` pour le lab complet |
| `EnableNatGateway` | `false` | Garder `false` pour ce parcours |
| `LatestAmiId` | Paramètre public SSM AL2023 x86_64 | Garder le défaut pour une nouvelle stack |

La résolution du paramètre public SSM ne configure pas Systems Manager sur les instances. Le template ne crée ni IAM Instance Profile ni endpoints SSM.

## Sécurité des fichiers

Conserver la clé privée sur son ordinateur. Le ProxyJump évite de la copier sur le bastion. Garder les paramètres réels et sauvegardes hors du dépôt ; `.gitignore` sert de protection complémentaire. En cas d'exposition d'un secret, le révoquer ou le renouveler : supprimer simplement le fichier du dernier commit ne suffit pas.
