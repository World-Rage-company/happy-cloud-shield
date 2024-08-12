<?php
session_start();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_once 'database/db.php';

    $username = isset($_POST['username']) ? trim($_POST['username']) : '';
    $password = isset($_POST['password']) ? $_POST['password'] : '';

    if (empty($username) || empty($password)) {
        echo "Please enter both username and password.";
        exit;
    }

    try {
        $conn = getDbConnection();

        $stmt = $conn->prepare('SELECT id, password, access FROM admins WHERE username = :username');
        $stmt->bindParam(':username', $username);
        $stmt->execute();

        $admin = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($admin && password_verify($password, $admin['password'])) {
            if ($admin['access']) {
                $_SESSION['admin_id'] = $admin['id'];
                echo "success";
            } else {
                echo "Your account is not active.";
            }
        } else {
            echo "Invalid username or password.";
        }
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        echo "Something went wrong. Please try again.";
    }
} else {
    echo "Invalid request method.";
}
