<?php
require "database/db.php";

session_start();

if (!isset($_SESSION['admin_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized access.']);
    exit();
}

$response = ['success' => false, 'message' => ''];

$currentPassword = $_POST['current_password'] ?? '';
$newUsername = $_POST['new_username'] ?? '';
$newPassword = $_POST['new_password'] ?? '';
$confirmNewPassword = $_POST['confirm_new_password'] ?? '';

if (empty($currentPassword) || empty($newUsername) || empty($newPassword) || empty($confirmNewPassword)) {
    $response['message'] = 'All fields are required.';
    echo json_encode($response);
    exit();
}

if ($newPassword !== $confirmNewPassword) {
    $response['message'] = 'New passwords do not match.';
    echo json_encode($response);
    exit();
}

$conn = getDbConnection();

try {
    $conn->beginTransaction();

    $adminId = $_SESSION['admin_id'];
    $stmt = $conn->prepare("SELECT password FROM admins WHERE id = :id");
    $stmt->execute(['id' => $adminId]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($currentPassword, $user['password'])) {
        $response['message'] = 'Current password is incorrect.';
        echo json_encode($response);
        exit();
    }

    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);

    $stmt = $conn->prepare("
        UPDATE admins 
        SET username = :username, password = :password, updated_at = NOW() 
        WHERE id = :id
    ");

    $result = $stmt->execute([
        'username' => $newUsername,
        'password' => $hashedPassword,
        'id' => $adminId
    ]);

    if ($result) {
        $response['success'] = true;
        $response['message'] = 'Settings updated successfully!';
    } else {
        $response['message'] = 'Failed to update settings.';
    }

    $conn->commit();
} catch (PDOException $e) {
    $conn->rollBack();
    $response['message'] = 'Database error: ' . $e->getMessage();
}

echo json_encode($response);
