#!/bin/bash

CONFIG_FILE="../assets/php/database/config.php"
BLOCKED_FILE="data/blocked_addresses.txt"
LOG_FILE="data/blocked_log.txt"

DB_HOST=$(grep "define('DB_HOST'" $CONFIG_FILE | cut -d"'" -f4)
DB_USER=$(grep "define('DB_USER'" $CONFIG_FILE | cut -d"'" -f4)
DB_PASS=$(grep "define('DB_PASS'" $CONFIG_FILE | cut -d"'" -f4)
DB_NAME=$(grep "define('DB_NAME'" $CONFIG_FILE | cut -d"'" -f4)

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT address FROM blocked_entries" -B -N > $BLOCKED_FILE

if [ -f "$BLOCKED_FILE" ]; then
    while IFS= read -r address
    do
        if ! grep -q "$address" "$LOG_FILE"; then
            sudo iptables -A INPUT -s "$address" -j DROP
            echo "Blocked $address"
            echo "$address" >> $LOG_FILE
        fi
    done < "$BLOCKED_FILE"
fi

while IFS= read -r address
do
    if ! grep -q "$address" "$BLOCKED_FILE"; then
        sudo iptables -D INPUT -s "$address" -j DROP
        echo "Unblocked $address"
        sed -i "/$address/d" $LOG_FILE
    fi
done < "$LOG_FILE"
