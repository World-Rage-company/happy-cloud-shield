<?php
require "database/db.php";

session_start();
if (!isset($_SESSION['admin_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized access.']);
    exit();
}

if (isset($_POST['entry_id']) && isset($_POST['address']) && isset($_POST['title'])) {
    $entryId = intval($_POST['entry_id']);
    $address = trim($_POST['address']);
    $title = trim($_POST['title']);
    $description = isset($_POST['description']) ? trim($_POST['description']) : null;

    if (empty($address) || empty($title)) {
        echo json_encode(['success' => false, 'message' => 'Title and Address are required.']);
        exit();
    }

    try {
        $pdo = getDbConnection();
        $stmt = $pdo->prepare("UPDATE blocked_entries SET title = :title, description = :description, address = :address WHERE id = :id");
        $stmt->bindParam(':title', $title, PDO::PARAM_STR);
        $stmt->bindParam(':description', $description, PDO::PARAM_STR);
        $stmt->bindParam(':address', $address, PDO::PARAM_STR);
        $stmt->bindParam(':id', $entryId, PDO::PARAM_INT);

        if ($stmt->execute()) {
            exec("/bin/bash /var/www/html/happy-cloud-shield/scripts/manage_blocks.sh > /dev/null 2>/dev/null &");
            
            echo json_encode(['success' => true, 'message' => 'Entry updated successfully.']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to update entry.']);
        }
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request.']);
}
