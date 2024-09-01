#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$(echo $VERSION_ID | awk -F. '{ printf("%d%02d", $1,$2); }')
        MIN_VERSION=2004
        if [[ "$OS" == "Ubuntu" && $VERSION -ge $MIN_VERSION ]]; then
            echo -e "${GREEN}Operating system and Ubuntu version are suitable.${NC}"
        else
            echo -e "${RED}This script only supports Ubuntu 20.04 and above.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Cannot detect the operating system.${NC}"
        exit 1
    fi
}

check_root() {
    if [ "$(id -u)" -ne "0" ]; then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi
}

check_installed() {
    if [ -d "/var/www/html/happy-cloud-shield" ]; then
        echo -e "${YELLOW}happy-cloud-shield is already installed.${NC}"
        read -p "Do you want to update it instead? (yes/no): " response
        if [[ "$response" == "yes" ]]; then
            echo -e "${YELLOW}Starting update process...${NC}"
            bash <(curl -Ls https://raw.githubusercontent.com/World-Rage-company/happy-cloud-shield/master/update.sh --ipv4)
            exit 0
        else
            echo -e "${RED}Exiting installation script.${NC}"
            exit 1
        fi
    fi
}

setup_nginx() {
    if ! command -v nginx &> /dev/null; then
        echo -e "${YELLOW}Nginx not found. Installing Nginx...${NC}"
        apt update
        apt install -y nginx
    fi

    if [ -d "/var/www/html/happy-cloud-shield" ]; then
        echo -e "${YELLOW}Directory /var/www/html/happy-cloud-shield already exists. Cleaning up...${NC}"
        rm -rf /var/www/html/happy-cloud-shield/*
    else
        mkdir -p /var/www/html/happy-cloud-shield
    fi

    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/World-Rage-company/happy-cloud-shield /tmp/happy-cloud-shield

    echo -e "${YELLOW}Copying Web_Panel contents...${NC}"
    cp -r /tmp/happy-cloud-shield/Web_Panel/* /var/www/html/happy-cloud-shield/

    rm -rf /tmp/happy-cloud-shield

    add_nginx_config
}

add_nginx_config() {
    local default_nginx_config="/etc/nginx/sites-available/default"
    local server_block
    local port

    echo -e "${YELLOW}Setting up Nginx configuration...${NC}"

    if grep -q "root /var/www/html/happy-cloud-shield;" "$default_nginx_config"; then
        echo -e "${GREEN}Nginx configuration for happy-cloud-shield already exists. Skipping...${NC}"
        return
    fi

    read -p "Enter the port number for the new nginx server (leave blank for random): " port
    if [ -z "$port" ]; then
        port=$(( ( RANDOM % 1000 )  + 9000 ))
    fi

    domain=$(hostname -I | awk '{print $1}')

    PHP_VERSION="8.1"

    nginx_config="
    server {
        listen $port;
        server_name $domain;
        root /var/www/html/happy-cloud-shield;
        index index.php index.html;

        location / {
            try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_param PHP_VALUE \"memory_limit=4096M\";
        }

        location ~ /\.ht {
            deny all;
        }
    }
    "

    echo "$nginx_config" >> "$default_nginx_config"
    systemctl restart nginx
}

setup_mysql() {
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}MySQL not found. Installing MySQL...${NC}"
        apt update
        apt install -y mysql-server
        mysql_secure_installation
    fi

    read -p "Enter MySQL root username: " mysql_user
    read -sp "Enter MySQL root password: " mysql_pass
    echo
    read -sp "Confirm MySQL root password: " mysql_pass_confirm
    echo

    while [ "$mysql_pass" != "$mysql_pass_confirm" ]; do
        echo -e "${RED}Passwords do not match. Try again.${NC}"
        read -sp "Enter MySQL root password: " mysql_pass
        echo
        read -sp "Confirm MySQL root password: " mysql_pass_confirm
        echo
    done

    mysql -u "$mysql_user" -p"$mysql_pass" -e "CREATE DATABASE IF NOT EXISTS HCS_db;"
    mysql -u "$mysql_user" -p"$mysql_pass" HCS_db <<EOF
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

    if [ -f "/var/www/html/happy-cloud-shield/assets/php/database/config.php" ]; then
        sed -i "s/DB_USER', ''/DB_USER', '$mysql_user'/; s/DB_PASS', ''/DB_PASS', '$mysql_pass'/" /var/www/html/happy-cloud-shield/assets/php/database/config.php
    fi

    admin_exists() {
        result=$(mysql -u "$mysql_user" -p"$mysql_pass" -D HCS_db -se "SELECT COUNT(*) FROM admins WHERE username='admin';")
        echo $result
    }

    if [ $(admin_exists) -eq 0 ]; then
        echo -e "${YELLOW}Admin user does not exist. Creating new admin user...${NC}"
        mysql -u "$mysql_user" -p"$mysql_pass" HCS_db <<EOF
INSERT INTO admins (username, password, role) VALUES ('admin', '$2a$12$OpVPiKsWXY4P3M0RSCOkiuBxOyCG2WIcXljN3J6aF3jKGE5N7oOBC', 'superadmin');
EOF
    else
        echo -e "${GREEN}Admin user already exists. Skipping creation.${NC}"
    fi
}

setup_manage_blocks() {
    local python_script="/var/www/html/happy-cloud-shield/scripts/manage_blocks.py"
    local venv_dir="/var/www/html/happy-cloud-shield/venv"
    local log_file="/var/log/manage_blocks.log"

    echo -e "${YELLOW}Setting up Python environment and manage_blocks.py...${NC}"

    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Python3 is not installed. Installing Python3...${NC}"
        apt update
        apt install -y python3 python3-venv python3-pip
    fi

    if [ ! -d "$venv_dir" ]; then
        echo -e "${YELLOW}Creating Python virtual environment...${NC}"
        python3 -m venv "$venv_dir"
    fi

    source "$venv_dir/bin/activate"

    if ! python -c "import mysql.connector" &> /dev/null; then
        echo -e "${YELLOW}mysql-connector-python not found. Installing...${NC}"
        pip install mysql-connector-python
    fi

    deactivate

    if [ ! -d "/var/log" ]; then
        echo -e "${YELLOW}/var/log directory does not exist. Creating...${NC}"
        mkdir -p /var/log
    fi

    touch "$log_file"
    chmod 666 "$log_file"

    cron_job="*/1 * * * * source $venv_dir/bin/activate && python $python_script >> $log_file 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -

    echo -e "${GREEN}Python environment is set up, and cron job is created to run the Python script every 5 minutes.${NC}"
}

finish() {
    local nginx_config_file="/etc/nginx/sites-available/default"
    local port
    local dashboard_link

    echo -e "************ Happy Cloud Shield ************"
    echo -e "Username: admin"
    echo -e "Password: admin"

    port=$(awk -v path="/var/www/html/happy-cloud-shield" '
        $0 ~ "root " path ";" {found=1}
        found && $0 ~ /^ *listen/ {print $2; exit}
    ' "$nginx_config_file")

    if [ -z "$port" ]; then
        echo -e "${RED}No port found for Happy Cloud Shield in Nginx configuration.${NC}"
        exit 1
    fi

    dashboard_link="http://$(hostname -I | awk '{print $1}'):${port}"

    echo -e "Dashboard Link: ${dashboard_link}"
}

check_os_version
check_root
check_installed
setup_nginx
setup_mysql
setup_manage_blocks
finish
