# Laboratoire réseau AWS & CloudFormation

**[Français](README.fr.md) | [English](README.md)**

Un laboratoire pratique pour apprendre à déployer un frontend public et un backend MariaDB privé sur AWS avec **CloudFormation, AWS CLI, Bash et Git/GitHub**. Créez un VPC, contrôlez les flux avec les groupes de sécurité, accédez aux serveurs privés via un bastion SSH et installez les paquets grâce à un Gateway Endpoint S3.

**Vous découvrez le projet ? [Ouvrez le laboratoire complet sur `develop`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/develop).**

La branche `main` est la porte d'entrée du projet. L'infrastructure actuelle, le script de base de données et les guides de reproduction se trouvent dans `develop`. Les branches d'étape ci-dessous conservent la progression pédagogique du projet ; commencez par `develop` pour reproduire le laboratoire complet.

## Ce que vous allez construire

| Couche | Implémentation du lab |
| --- | --- |
| Réseau | VPC `10.10.0.0/16`, deux subnets publics et un subnet privé répartis sur deux AZ |
| Accès | Bastion SSH limité à l'IPv4 administrateur ; ProxyJump vers frontend et backend |
| Frontend | EC2 Amazon Linux 2023 avec une page Apache de démonstration |
| Base de données | EC2 privée avec MariaDB, accessible depuis le frontend sur TCP 3306 |
| Accès privé aux paquets | Gateway Endpoint S3 pour les dépôts régionaux Amazon Linux ; NAT Gateway optionnel |
| Automatisation | Infrastructure CloudFormation et script Bash de configuration MariaDB |

Le frontend est une page statique de démonstration. La connexion MariaDB est validée avec un client SQL. Les deux AZ n'apportent ni réplication ni haute disponibilité à la base. Systems Manager et le déploiement CI/CD restent des évolutions futures.

## Suivre le lab dans votre langue

| Guide | Français | English |
| --- | --- | --- |
| Présentation du projet | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/README.fr.md) | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/README.md) |
| Prérequis et coûts | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/prerequisites.md) | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/prerequisites.md) |
| Architecture | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/architecture.md) | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/architecture.md) |
| Déploiement et SSH | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/deployment-guide.md) | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/deployment-guide.md) |
| Validation et dépannage | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/validation-tests.md) | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/validation-tests.md) |
| Sauvegarde et nettoyage | [Lire](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/cleanup.md) | [Read](https://github.com/rachadk1/aws-networking-cloudformation-lab/blob/develop/docs/en/cleanup.md) |

## Explorer les branches

| Branche | Rôle |
| --- | --- |
| [`main`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/main) | Accueil du projet et navigation |
| [`develop`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/develop) | Version actuelle du laboratoire complet et documentation |
| [`infra/01-vpc`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/01-vpc) | Étape 01 — Fondation du VPC |
| [`infra/02-subnets-routing`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/02-subnets-routing) | Étape 02 — Subnets, Internet Gateway et routage |
| [`infra/03-security-groups`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/03-security-groups) | Étape 03 — Groupes de sécurité et flux autorisés |
| [`infra/04-nat-gateway`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/04-nat-gateway) | Étape 04 — NAT Gateway optionnel |
| [`infra/05-ec2-instances`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/05-ec2-instances) | Étape 05 — EC2 bastion, frontend et backend |
| [`infra/06-backend-database`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/06-backend-database) | Étape 06 — Accès au backend privé et Gateway Endpoint S3 |
| [`infra/07-mariadb-automation`](https://github.com/rachadk1/aws-networking-cloudformation-lab/tree/infra/07-mariadb-automation) | Étape 07 — Automatisation de MariaDB avec Bash |

Les branches d'étape sont des instantanés historiques : elles peuvent contenir moins de ressources ou des instructions plus anciennes que `develop`. L'installation manuelle et les tests SQL sont expliqués dans les guides actuels. [Consultez toutes les branches](https://github.com/rachadk1/aws-networking-cloudformation-lab/branches), y compris celles de documentation et de relecture.

## Démarrer

```bash
git clone --branch develop https://github.com/rachadk1/aws-networking-cloudformation-lab.git
cd aws-networking-cloudformation-lab
```

Suivez ensuite les prérequis et le guide de déploiement dans votre langue. Utilisez votre propre compte AWS, une Key Pair régionale et votre IPv4 publique d'administration. Les ressources AWS peuvent générer des frais ; lisez les coûts et le nettoyage avant de déployer. Gardez hors de Git les identifiants AWS, clés privées SSH, mots de passe SQL et dumps de base.
