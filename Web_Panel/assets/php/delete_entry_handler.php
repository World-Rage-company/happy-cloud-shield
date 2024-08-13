<?php
require "database/db.php";

session_start();
if (!isset($_SESSION['admin_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized access.']);
    exit();
}

if (isset($_POST['entry_id'])) {
    $entryId = intval($_POST['entry_id']);

    try {
        $pdo = getDbConnection();
        $stmt = $pdo->prepare("DELETE FROM blocked_entries WHERE id = :id");
        $stmt->bindParam(':id', $entryId, PDO::PARAM_INT);

        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Entry deleted successfully.']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to delete entry.']);
        }
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request.']);
}
