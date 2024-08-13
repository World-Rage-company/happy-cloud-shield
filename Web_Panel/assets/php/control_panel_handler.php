<?php
require "database/db.php";

if (!isset($_SESSION['admin_id'])) {
    header("Location: accounts/login.php");
    exit();
}

$admin_id = $_SESSION['admin_id'];

try {
    $pdo = getDbConnection();

    $stmt = $pdo->prepare("SELECT role FROM admins WHERE id = :admin_id LIMIT 1");
    $stmt->execute(['admin_id' => $admin_id]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($admin) {
        $role = $admin['role'];

        if ($role === 'superadmin') {
            $stmt = $pdo->prepare("SELECT * FROM blocked_entries");
        } else {
            $stmt = $pdo->prepare("SELECT * FROM blocked_entries WHERE created_by = :admin_id");
            $stmt->bindParam(':admin_id', $admin_id, PDO::PARAM_INT);
        }

        $stmt->execute();
        $blocked_entries = $stmt->fetchAll(PDO::FETCH_ASSOC);

    } else {
        header("Location: accounts/login.php");
        exit();
    }
} catch (PDOException $e) {
    echo "An error occurred: " . $e->getMessage();
    exit();
}
