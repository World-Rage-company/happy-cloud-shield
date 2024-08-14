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
    local existing_port
    local port

    echo -e "${YELLOW}Setting up Nginx configuration...${NC}"
    if [ -d "/var/www/html/happy-cloud-shield" ]; then
        server_block=$(awk -v RS="" "/root \/var\/www\/html\/happy-cloud-shield;/ {print; exit}" "$default_nginx_config")
        if [ -n "$server_block" ]; then
            existing_port=$(echo "$server_block" | grep -oP '(?<=listen )\d+')
            echo -e "${GREEN}Found existing server block with port: $existing_port${NC}"
            port=$existing_port
            return
        else
            echo -e "${RED}No existing server block found for /var/www/html/happy-cloud-shield. Adding new configuration.${NC}"
        fi
    fi

    read -p "Enter the port number for the new nginx server (leave blank for random): " port
    if [ -z "$port" ]; then
        port=$(( ( RANDOM % 1000 )  + 9000 ))
    fi

    read -p "Do you want to use SSL for this server? (y/n): " use_ssl
    if [[ "$use_ssl" =~ ^[Yy]$ ]]; then
        read -p "Enter your domain name (e.g., example.com): " domain
        certbot --nginx -d "$domain" -d "www.$domain"
        nginx_config="
        server {
            listen $port ssl;
            server_name $domain www.$domain;
            root /var/www/html/happy-cloud-shield;
            index index.php index.html;

            ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

            location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
            }

            location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
                fastcgi_param PHP_VALUE \"memory_limit=4096M\";
            }

            location ~ /\.ht {
                deny all;
            }
        }
        "
    else
        if hostname -I > /dev/null 2>&1; then
            server_ip=$(hostname -I | awk '{print $1}')
            domain=$server_ip
        else
            domain=$(hostname)
        fi
        echo -e "${YELLOW}No SSL configuration found. Using IP address as server name.${NC}"
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
                fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
                fastcgi_param PHP_VALUE \"memory_limit=4096M\";
            }

            location ~ /\.ht {
                deny all;
            }
        }
        "
    fi

    echo "$nginx_config" | tee /etc/nginx/sites-available/happy-cloud-shield > /dev/null
    ln -s /etc/nginx/sites-available/happy-cloud-shield /etc/nginx/sites-enabled/
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

    sed -i "s/DB_USER', ''/DB_USER', '$mysql_user'/; s/DB_PASS', ''/DB_PASS', '$mysql_pass'/" /var/www/html/happy-cloud-shield/assets/php/database/config.php

    mysql -u "$mysql_user" -p"$mysql_pass" HCS_db <<EOF
INSERT INTO admins (username, password) VALUES ('admin', '$2a$12$OpVPiKsWXY4P3M0RSCOkiuBxOyCG2WIcXljN3J6aF3jKGE5N7oOBC');
EOF
}

finish() {
    echo -e "************ Happy Cloud Shield ************"
    echo -e "Username: admin"
    echo -e "Password: admin"
    echo -e "Dashboard Link: http://$(hostname -I | awk '{print $1}'):$(grep -oP 'listen \K\d+' /etc/nginx/sites-available/happy-cloud-shield)"
}

check_os_version
check_root
setup_nginx
setup_mysql
finish
