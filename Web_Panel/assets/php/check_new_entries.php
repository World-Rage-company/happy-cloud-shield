<?php
require 'database/config.php';

$conn = getDbConnection();

$query = "SELECT address FROM blocked_entries";
$result = $conn->query($query);

$ips = [];
while ($row = $result->fetch_assoc()) {
    $ips[] = $row['address'];
}

$conn->query("UPDATE blocked_entries SET blocked = 0 WHERE blocked = 1 AND address NOT IN (SELECT address FROM blocked_entries)");

$conn->close();

echo implode("\n", $ips);
