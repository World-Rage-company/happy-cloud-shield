#!/bin/bash

if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Please install Nginx."
    exit 1
fi

INSTALL_PATH="/var/www/html/happy-cloud-shield"
GITHUB_REPO="https://github.com/World-Rage-company/happy-cloud-shield"

if [ -d "$INSTALL_PATH" ]; then
    echo "Directory $INSTALL_PATH already exists. Cleaning up..."
    rm -rf "$INSTALL_PATH"
fi

echo "Cloning the repository..."
git clone "$GITHUB_REPO" "$INSTALL_PATH"

if ! command -v mysql &> /dev/null; then
    echo "MySQL is not installed. Please install MySQL."
    exit 1
fi

read -p "MySQL username: " MYSQL_USER
read -sp "MySQL password: " MYSQL_PASS
echo
read -p "Do you want to confirm the database name (default: HCS_db)? " DB_NAME
DB_NAME="${DB_NAME:-HCS_db}"

echo "Creating database and tables..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$DB_NAME" <<-EOF
CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('superadmin', 'admin') DEFAULT 'admin',
    access BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blocked_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    address VARCHAR(255) NOT NULL,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE SET NULL
);
EOF

echo "Generating bcrypt hashed password for the admin user..."
HASHED_PASS=$(openssl passwd -6 "admin")

echo "Inserting admin user into the database..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$DB_NAME" <<-EOF
INSERT INTO admins (username, password, role) VALUES ('admin', '$HASHED_PASS', 'superadmin');
EOF

CONFIG_FILE="$INSTALL_PATH/assets/php/database/config.php"
echo "Configuring config.php..."
sed -i "s/define('DB_USER', '');/define('DB_USER', '$MYSQL_USER');/" "$CONFIG_FILE"
sed -i "s/define('DB_PASS', '');/define('DB_PASS', '$MYSQL_PASS');/" "$CONFIG_FILE"
sed -i "s/define('DB_NAME', '');/define('DB_NAME', '$DB_NAME');/" "$CONFIG_FILE"

CRON_FILE="/etc/cron.d/block_ips_cron"
echo "Setting up cron job..."
cat <<EOF > "$CRON_FILE"
* * * * * root /bin/bash $INSTALL_PATH/scripts/block_ips.sh
EOF

chmod +x "$INSTALL_PATH/scripts/block_ips.sh"
chmod +x "$INSTALL_PATH/install.sh"

echo "Installation and configuration complete."
