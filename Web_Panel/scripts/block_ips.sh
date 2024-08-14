#!/bin/bash

PHP_SCRIPT="../assets/php/check_new_entries.php"
LOG_FILE="/var/log/blocked_ips.log"
BLOCKED_IP_FILE="/var/log/current_blocked_ips.txt"

block_ip() {
    local IP=$1
    if ! iptables -C INPUT -s $IP -j DROP 2>/dev/null; then
        iptables -A INPUT -s $IP -j DROP
        echo "$(date): Blocked IP: $IP" >> $LOG_FILE
    fi
}

unblock_ip() {
    local IP=$1
    if iptables -C INPUT -s $IP -j DROP 2>/dev/null; then
        iptables -D INPUT -s $IP -j DROP
        echo "$(date): Unblocked IP: $IP" >> $LOG_FILE
    fi
}

NEW_IPS=$(php $PHP_SCRIPT)
echo "$NEW_IPS" > "$BLOCKED_IP_FILE"

CURRENT_BLOCKED_IPS=$(iptables -L INPUT -v -n | grep DROP | awk '{print $4}')

IFS=$'\n' read -d '' -r -a CURRENT_IP_ARRAY <<< "$CURRENT_BLOCKED_IPS"

while IFS= read -r IP; do
    block_ip $IP
done <<< "$NEW_IPS"

for IP in "${CURRENT_IP_ARRAY[@]}"; do
    if ! grep -q "$IP" "$BLOCKED_IP_FILE"; then
        unblock_ip $IP
    fi
done

rm "$BLOCKED_IP_FILE"

sleep 2
