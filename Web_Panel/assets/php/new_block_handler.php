<?php
require "database/db.php";

session_start();

if (!isset($_SESSION['admin_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized access.']);
    exit();
}

try {
    $pdo = getDbConnection();

    $address = trim($_POST['address']);
    $title = trim($_POST['title']);
    $description = trim($_POST['description']);
    $createdBy = $_SESSION['admin_id'];

    if (empty($address) || empty($title)) {
        echo json_encode(['success' => false, 'message' => 'Address and Title are required.']);
        exit();
    }

    $stmt = $pdo->prepare("INSERT INTO blocked_entries (title, description, address, created_by) VALUES (?, ?, ?, ?)");
    $result = $stmt->execute([$title, $description, $address, $createdBy]);

    if ($result) {
        exec("/bin/bash /var/www/html/happy-cloud-shield/scripts/manage_blocks.sh > /dev/null 2>/dev/null &");

        echo json_encode(['success' => true, 'message' => 'Block added successfully.']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to add block.']);
    }
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
