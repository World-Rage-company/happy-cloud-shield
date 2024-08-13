<?php
session_start();
if (!isset($_SESSION['admin_id'])) {
    header("Location: accounts/login.php");
    exit();
} else {
    require "assets/php/control_panel_handler.php";
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Happy Cloud Shield</title>
    <link rel="icon" href="assets/images/clogo.png" type="image/png">
    <link rel="stylesheet" href="assets/css/main_style.css">
</head>
<body>

<div class="message-container">
    <div id="error-message" class="error-message"></div>
    <div id="success-message" class="success-message"></div>
</div>

<div class="cloud-layout">
    <div class="cloud-header">
        <div class="box-option-one-header">
            <div class="cloud-logo">
                <img src="assets/images/clogo.png" alt="Happy cloud shield Logo">
            </div>
            <div class="cloud-name">
                <span>Happy cloud shield</span>
            </div>
        </div>
    </div>

    <div class="cloud-content">
        <div class="cloud-nav">
            <div class="nav-item">
                <button class="nav-button" id="home">
                    <i class="icon-home"></i>
                    <span>Home</span>
                </button>
            </div>
            <div class="nav-item">
                <button class="nav-button" id="block-list">
                    <i class="icon-block-list"></i>
                    <span>Block List</span>
                </button>
            </div>
            <div class="nav-item">
                <button class="nav-button" id="settings">
                    <i class="icon-settings"></i>
                    <span>Setting</span>
                </button>
            </div>
            <div class="nav-item">
                <button class="nav-button" id="logout">
                    <i class="icon-logout"></i>
                    <span>Logout</span>
                </button>
            </div>
        </div>

        <div class="main-container">
            <section class="home_section section"></section>
            <section class="block_list_section section"></section>
            <section class="setting-section section"></section>
        </div>
    </div>
</div>

<script src="assets/js/main_script.js"></script>
</body>
</html>
