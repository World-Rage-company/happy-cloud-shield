<?php
session_start();
header('Content-Type: application/json');

if (!isset($_SESSION['admin_id'])) {
    echo json_encode(['success' => false, 'message' => 'Not authenticated']);
    exit();
}

require_once 'database/db.php';

$entryId = isset($_GET['id']) ? intval($_GET['id']) : 0;

if ($entryId <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid entry ID']);
    exit();
}

try {
    $conn = getDbConnection();

    $sql = "SELECT title, address, description FROM blocked_entries WHERE id = :id";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':id', $entryId, PDO::PARAM_INT);
    $stmt->execute();

    $data = ['success' => false, 'entry' => null];
    if ($stmt->rowCount() === 1) {
        $entry = $stmt->fetch();
        $data = [
            'success' => true,
            'entry' => $entry
        ];
    }

    echo json_encode($data);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
