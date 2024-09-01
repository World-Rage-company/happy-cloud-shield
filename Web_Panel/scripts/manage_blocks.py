import mysql.connector
import subprocess
import re
import configparser

CONFIG_FILE = '/var/www/html/happy-cloud-shield/assets/php/database/config.php'

def parse_php_config(filename):
    config = {}
    with open(filename, 'r') as file:
        content = file.read()
        for match in re.finditer(r"define\('(\w+)'\s*,\s*'([^']+)'\)", content):
            key, value = match.groups()
            config[key] = value
    return config

def fetch_blocked_ips(config):
    conn = mysql.connector.connect(
        host=config['DB_HOST'],
        user=config['DB_USER'],
        password=config['DB_PASS'],
        database=config['DB_NAME']
    )
    cursor = conn.cursor()
    cursor.execute("SELECT address FROM blocked_entries")
    ips = [row[0] for row in cursor.fetchall()]
    cursor.close()
    conn.close()
    return set(ips)

def fetch_current_blocked_ips():
    result = subprocess.run(['sudo', 'iptables', '-L', 'INPUT', '-v', '-n'], capture_output=True, text=True)
    lines = result.stdout.splitlines()
    blocked_ips = set()
    for line in lines:
        if 'DROP' in line:
            parts = line.split()
            for part in parts:
                if part.count('.') == 3:
                    blocked_ips.add(part)
    return blocked_ips

def update_blocks(blocked_ips, current_blocked_ips):
    ips_to_block = blocked_ips - current_blocked_ips
    ips_to_unblock = current_blocked_ips - blocked_ips

    for ip in ips_to_block:
        result = subprocess.run(['sudo', 'iptables', '-A', 'INPUT', '-s', ip, '-j', 'DROP'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"Blocked {ip}")
        else:
            print(f"Failed to block {ip}: {result.stderr}")

    for ip in ips_to_unblock:
        result = subprocess.run(['sudo', 'iptables', '-D', 'INPUT', '-s', ip, '-j', 'DROP'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"Unblocked {ip}")
        else:
            print(f"Failed to unblock {ip}: {result.stderr}")

def main():
    config = parse_php_config(CONFIG_FILE)
    blocked_ips = fetch_blocked_ips(config)
    current_blocked_ips = fetch_current_blocked_ips()
    update_blocks(blocked_ips, current_blocked_ips)

if __name__ == "__main__":
    main()
