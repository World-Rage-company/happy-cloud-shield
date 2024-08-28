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

check_os_version
check_root
check_installed
update_application
