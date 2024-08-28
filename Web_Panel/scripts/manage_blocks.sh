#!/bin/bash

CONFIG_FILE="/var/www/html/happy-cloud-shield/assets/php/database/config.php"
DB_HOST=$(grep "define('DB_HOST'" $CONFIG_FILE | cut -d"'" -f4)
DB_USER=$(grep "define('DB_USER'" $CONFIG_FILE | cut -d"'" -f4)
DB_PASS=$(grep "define('DB_PASS'" $CONFIG_FILE | cut -d"'" -f4)
DB_NAME=$(grep "define('DB_NAME'" $CONFIG_FILE | cut -d"'" -f4)

TEMP_BLOCKED_LIST_FILE=$(mktemp)

if ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT 1" >/dev/null 2>&1; then
    echo "Failed to connect to database. Exiting."
    exit 1
fi

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT address FROM blocked_entries" -B -N | sort -u > $TEMP_BLOCKED_LIST_FILE

block_ip() {
    local ip="$1"
    if ! sudo iptables -L INPUT -v -n | awk '/DROP/ {print $8}' | grep -q "$ip"; then
        sudo iptables -A INPUT -s "$ip" -j DROP
        sudo iptables -A FORWARD -s "$ip" -j DROP
        sudo iptables -A OUTPUT -d "$ip" -j DROP
        echo "Blocked $ip"
    else
        echo "IP $ip is already blocked"
    fi
}

unblock_ip() {
    local ip="$1"
    if sudo iptables -L INPUT -v -n | awk '/DROP/ {print $8}' | grep -q "$ip"; then
        sudo iptables -D INPUT -s "$ip" -j DROP
        sudo iptables -D FORWARD -s "$ip" -j DROP
        sudo iptables -D OUTPUT -d "$ip" -j DROP
        echo "Unblocked $ip"
    else
        echo "IP $ip is not blocked"
    fi
}

while IFS= read -r address; do
    if [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        block_ip "$address"
    else
        ip_addresses=$(dig +short "$address")
        if [ -z "$ip_addresses" ]; then
            echo "No IP found for address $address"
        else
            for ip in $ip_addresses; do
                block_ip "$ip"
            done
        fi
    fi
done < "$TEMP_BLOCKED_LIST_FILE"

BLOCKED_IPS=$(sudo iptables -L INPUT -v -n | awk '/DROP/ {print $8}')
for ip in $BLOCKED_IPS; do
    if ! grep -q "$ip" "$TEMP_BLOCKED_LIST_FILE"; then
        unblock_ip "$ip"
    fi
done

rm "$TEMP_BLOCKED_LIST_FILE"
