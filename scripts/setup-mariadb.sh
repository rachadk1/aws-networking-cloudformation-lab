
#!/usr/bin/env bash

set -euo pipefail

# AWS Networking Lab - MariaDB automated setup
# Run as root on Amazon Linux 2023.

DB_NAME="network_lab"
DB_USER="network_app"
DB_HOST="10.10.1.%"
SECRET_DIR="/root/.config/aws-networking-lab"

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: run this script with sudo."
    exit 1
fi

echo "[1/5] Installing MariaDB..."

dnf install -y mariadb105-server openssl

echo "[2/5] Starting MariaDB..."

systemctl enable --now mariadb

echo "[3/5] Creating database if needed..."

mariadb --protocol=socket <<SQL
CREATE DATABASE IF NOT EXISTS \`network_lab\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL

echo "[4/5] Configuring application user..."

USER_EXISTS=$(mariadb --protocol=socket -N -B -e \
    "SELECT COUNT(*) FROM mysql.global_priv
     WHERE User='network_app' AND Host='10.10.1.%';")

if [[ "$USER_EXISTS" == "0" ]]; then

    APP_PASSWORD=$(openssl rand -hex 24)

    mariadb --protocol=socket <<SQL
CREATE USER 'network_app'@'10.10.1.%'
IDENTIFIED BY '${APP_PASSWORD}';
SQL

    # Store generated password locally with root-only access.
    install -d -m 700 "$SECRET_DIR"
    umask 077
    printf '%s\n' "$APP_PASSWORD" \
      > "$SECRET_DIR/network-app.password"

    unset APP_PASSWORD

    echo "New user created."
    echo "Password stored in $SECRET_DIR/network-app.password"

else
    echo "User already exists. Existing password preserved."
fi

mariadb --protocol=socket <<SQL
GRANT SELECT, INSERT, UPDATE, DELETE
ON \`network_lab\`.*
TO 'network_app'@'10.10.1.%';
SQL

echo "[5/5] Verifying MariaDB..."

systemctl is-active --quiet mariadb

mariadb --protocol=socket -e \
    "SHOW GRANTS FOR 'network_app'@'10.10.1.%';"

echo "MariaDB setup completed successfully!"
