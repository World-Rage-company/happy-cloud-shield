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
        echo -e "${YELLOW}Directory /var/www/html/happy-cloud-shield exists. Preparing to update...${NC}"
    else
        echo -e "${RED}happy-cloud-shield is not installed. Exiting update script.${NC}"
        exit 1
    fi
}

update_application() {
    echo -e "${YELLOW}Cleaning up existing installation...${NC}"
    rm -rf /var/www/html/happy-cloud-shield/*

    echo -e "${YELLOW}Cloning latest version from GitHub...${NC}"
    git clone https://github.com/World-Rage-company/happy-cloud-shield /tmp/happy-cloud-shield

    echo -e "${YELLOW}Copying Web_Panel contents...${NC}"
    cp -r /tmp/happy-cloud-shield/Web_Panel/* /var/www/html/happy-cloud-shield/

    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -rf /tmp/happy-cloud-shield

    echo -e "${GREEN}Update completed successfully.${NC}"
}

configure_database() {
    echo -e "${YELLOW}Configuring database connection...${NC}"

    read -p "Enter MySQL username: " mysql_user
    read -sp "Enter MySQL password: " mysql_pass
    echo

    config_file="/var/www/html/happy-cloud-shield/assets/php/database/config.php"

    if [ -f "$config_file" ]; then
        echo -e "${YELLOW}Updating $config_file with provided credentials...${NC}"
        sed -i "s/DB_USER', ''/DB_USER', '$mysql_user'/; s/DB_PASS', ''/DB_PASS', '$mysql_pass'/" "$config_file"
        echo -e "${GREEN}Configuration updated successfully.${NC}"
    else
        echo -e "${RED}$config_file not found. Exiting...${NC}"
        exit 1
    fi
}

setup_cron_job() {
    local python_script="/var/www/html/happy-cloud-shield/scripts/manage_blocks.py"
    local venv_dir="/var/www/html/happy-cloud-shield/venv"
    local log_file="/var/log/manage_blocks.log"
    local cron_job="*/5 * * * * source $venv_dir/bin/activate && python $python_script >> $log_file 2>&1"
    local cron_file="/tmp/crontab.new"

    echo -e "${YELLOW}Setting up cron job for manage_blocks.py...${NC}"

    if crontab -l 2>/dev/null | grep -q "$python_script"; then
        echo -e "${GREEN}Cron job for manage_blocks.py already exists.${NC}"
    else
        (crontab -l 2>/dev/null; echo "$cron_job") > "$cron_file"
        crontab "$cron_file"
        rm "$cron_file"
        echo -e "${GREEN}Cron job added successfully.${NC}"
    fi
}

check_os_version
check_root
check_installed
update_application
configure_database
setup_cron_job
