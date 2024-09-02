#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

remove_nginx_config() {
    local default_nginx_config="/etc/nginx/sites-available/default"
    echo -e "${YELLOW}Removing Nginx configuration for happy-cloud-shield...${NC}"

    if grep -q "root /var/www/html/happy-cloud-shield;" "$default_nginx_config"; then
        sed -i '/root \/var\/www\/html\/happy-cloud-shield;/d' "$default_nginx_config"
        sed -i '/listen [0-9]*;/d' "$default_nginx_config"
        systemctl restart nginx
    else
        echo -e "${GREEN}Nginx configuration for happy-cloud-shield not found. Skipping...${NC}"
    fi
}

remove_mysql() {
    echo -e "${YELLOW}Removing MySQL database and user...${NC}"

    read -p "Enter MySQL root username: " mysql_user
    read -sp "Enter MySQL root password: " mysql_pass
    echo

    mysql -u "$mysql_user" -p"$mysql_pass" -e "DROP DATABASE IF EXISTS HCS_db;"
    mysql -u "$mysql_user" -p"$mysql_pass" -e "DROP USER IF EXISTS '$mysql_user'@'localhost';"
}

remove_python() {
    local venv_dir="/var/www/html/happy-cloud-shield/venv"
    local python_script="/var/www/html/happy-cloud-shield/scripts/manage_blocks.py"
    local log_file="/var/log/manage_blocks.log"

    echo -e "${YELLOW}Removing Python virtual environment and cron job...${NC}"

    if [ -d "$venv_dir" ]; then
        rm -rf "$venv_dir"
    fi

    if [ -f "$log_file" ]; then
        rm "$log_file"
    fi

    (crontab -l 2>/dev/null | grep -v "$python_script") | crontab -
}

remove_app_files() {
    echo -e "${YELLOW}Removing application files...${NC}"

    if [ -d "/var/www/html/happy-cloud-shield" ]; then
        rm -rf /var/www/html/happy-cloud-shield
    fi
}

main() {
    remove_nginx_config
    remove_mysql
    remove_python
    remove_app_files

    echo -e "${GREEN}Uninstallation completed successfully.${NC}"
}

main
