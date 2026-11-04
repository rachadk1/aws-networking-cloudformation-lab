# Architecture et parcours pédagogique

[Accueil et diagramme](../README.md) · [Déploiement](deployment-guide.md)

## Réseau réellement décrit par le template

| Ressource logique | Réseau / rôle |
| --- | --- |
| `LabVPC` | `10.10.0.0/16` |
| `BastionSubnet` | `10.10.0.0/24`, première AZ retournée par AWS |
| `FrontendSubnet` | `10.10.1.0/24`, même AZ que le bastion |
| `BackendSubnet` | `10.10.11.0/24`, deuxième AZ retournée par AWS |
| `PublicRouteTable` | Route `0.0.0.0/0` vers l'Internet Gateway |
| `PrivateRouteTable` | Route locale du VPC et route de préfixe S3 vers le Gateway Endpoint |
| `PrivateDefaultRoute` | Route `0.0.0.0/0` vers le NAT, seulement si activé |

Un subnet est public ici parce que sa table possède une route vers l'IGW. Le bastion et le frontend reçoivent une IPv4 publique ; le backend n'en reçoit pas. Les adresses privées des EC2 sont attribuées au déploiement : toujours les récupérer dans sa propre stack.

## Flux entrants

| Source | Destination | Port | Contrôle |
| --- | --- | --- | --- |
| `AdminCidr` | Bastion | TCP 22 | `BastionSG` |
| `BastionSG` | Frontend | TCP 22 | `FrontendSG` |
| `BastionSG` | Backend | TCP 22 | `BackendSG` |
| Internet IPv4 | Frontend | TCP 80 | `FrontendSG` |
| `FrontendSG` | Backend | TCP 3306 | `BackendSG` |

Le référencement d'un SG autorise les interfaces associées à ce SG ; ce n'est pas une autorisation générale donnée à tout le subnet. En complément, le compte SQL `network_app` est limité aux clients `10.10.1.%` et à quatre permissions sur `network_lab`.

Les SG sont stateful. Le template ne restreint pas explicitement les sorties et n'ajoute pas de NACL personnalisée. Le Gateway Endpoint est associé uniquement à la table privée ; le frontend utilise sa route Internet pour installer Apache et son client MariaDB.

## Sept étapes pour apprendre

Le template actuel rassemble les étapes : un déploiement crée les ressources activées ensemble. Ce tableau explique leur progression pédagogique ; il ne fournit pas sept templates séparés.

| Étape | Travail à comprendre | Vérification |
| --- | --- | --- |
| 01 | VPC et CIDR | VPC `10.10.0.0/16`, DNS activé |
| 02 | Subnets, IGW et tables | Associations publiques/privée, AZ distinctes |
| 03 | Security Groups | Examiner les cinq flux du tableau |
| 04 | NAT optionnel | Désactivé par défaut ; route privée générale seulement si activé |
| 05 | EC2 et bastion | SSH ProxyJump et page Apache |
| 06 | S3 Gateway Endpoint et MariaDB | Installation depuis le backend privé et connexion SQL depuis le frontend |
| 07 | Automatisation Bash | Exécution puis réexécution de `setup-mariadb.sh` |

## Ce qui reste manuel

CloudFormation ne lance pas `setup-mariadb.sh`. Il faut transférer puis exécuter ce script par SSH. Il installe MariaDB, crée la base si absente et attribue les permissions. Si le compte SQL existe, son mot de passe est conservé. S'il est nouveau, un mot de passe est généré et écrit dans `/root/.config/aws-networking-lab/network-app.password` avec accès restreint.

Le script ne révoque pas d'éventuels privilèges supplémentaires déjà présents, ne configure pas TLS MariaDB, ne charge pas de tables applicatives et ne gère pas les sauvegardes. L'écriture du fichier secret suit la création du compte : si elle échoue, une réexécution ne régénère pas le mot de passe d'un compte déjà créé. Une récupération administrative peut alors être nécessaire.

## Limites

La présence de deux AZ n'apporte ni réplication ni haute disponibilité au backend unique. Le site est une page HTTP de démonstration, sans lien applicatif avec la base. SSM, IAM pour les EC2, gestion centralisée des secrets et CI/CD ne sont pas intégrés à cette version.

Références : [Gateway Endpoints et routage](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html), [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html).
