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

            <section class="block_list_section section">
                <div class="block_list_container">
                    <div class="header_content">
                        <div class="header_options_one">
                            <div class="page-name">
                                <span>Block List</span>
                            </div>
                            <div class="page-options">
                                <button class="osb_button" id="add_btn">
                                    <i class="icon-add"></i>
                                    <span>Add</span>
                                </button>
                            </div>
                        </div>
                        <div class="header_options_two">
                            <input class="osb_search" id="search-input" placeholder="Search...">
                        </div>
                    </div>
                    <div class="main_content">
                        <?php foreach ($blocked_entries as $entry): ?>
                            <div class="blocked-entry">
                                <div class="be-header-content">
                                    <div class="entry-profile">
                                        <?php echo strtoupper(substr($entry['title'], 0, 1)); ?>
                                    </div>
                                    <div class="entry-title">
                                        <?php echo htmlspecialchars($entry['title']); ?>
                                    </div>
                                </div>
                                <div class="be-options-content">
                                    <div class="label">Description:</div>
                                    <div class="description">
                                        <?php echo htmlspecialchars($entry['description']); ?>
                                    </div>
                                    <div class="label">Address:</div>
                                    <div class="address">
                                        <?php echo htmlspecialchars($entry['address']); ?>
                                    </div>
                                    <div class="label">Options:</div>
                                    <div class="option-entry-box">
                                        <button class="be-button" id="btn_edit" data-entry="<?php echo htmlspecialchars($entry['id']); ?>">
                                            <i class="icon-edit"></i>
                                            <span>Edit</span>
                                        </button>
                                        <button class="be-button" id="btn_delete" data-entry="<?php echo htmlspecialchars($entry['id']); ?>">
                                            <i class="icon-delete"></i>
                                            <span>Edit</span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </section>

            <section class="setting-section section"></section>

        </div>
    </div>
</div>

<div class="block-entry-background">
    <div class="new-entry-layout">
        <div class="nb-header-content">
            <div class="title-nbh">
                <span>New Block</span>
            </div>
            <div class="options-nbh">
                <button class="button-back-nb" id="btn_n_close">
                    <span>Back</span>
                    <i class="icon-chevron-right"></i>
                </button>
            </div>
        </div>
        <div class="form-content">
            <div class="form-label">Enter Website URL <span class="required">*</span></div>
            <div class="form-input">
                <input type="url" class="input-field" id="address-input" placeholder="e.g.: https://example.com">
            </div>
            <div class="form-label">Enter Title <span class="required">*</span></div>
            <div class="form-input">
                <input type="text" class="input-field" id="title-input" placeholder="Title">
            </div>
            <div class="form-label">Enter Description</div>
            <div class="form-input">
                <input type="text" class="input-field" id="description-input" placeholder="Description">
            </div>
        </div>
        <div class="options-content">
            <button class="button-nboc" id="btn_n_cancel">
                <span>Cancel</span>
            </button>
            <button class="button-nboc" id="btn_n_save">
                <span>Save</span>
            </button>
        </div>
    </div>
    <div class="edit-entry-layout">
        <div class="nb-header-content">
            <div class="title-nbh">
                <span>Edit Block</span>
            </div>
            <div class="options-nbh">
                <button class="button-back-nb" id="btn_e_close">
                    <span>Back</span>
                    <i class="icon-chevron-right"></i>
                </button>
            </div>
        </div>
        <div class="form-content">
            <div class="form-label">Enter Website URL <span class="required">*</span></div>
            <div class="form-input">
                <input type="url" class="input-field" id="edit-address-input" placeholder="e.g.: https://example.com">
            </div>
            <div class="form-label">Enter Title <span class="required">*</span></div>
            <div class="form-input">
                <input type="text" class="input-field" id="edit-title-input" placeholder="Title">
            </div>
            <div class="form-label">Enter Description</div>
            <div class="form-input">
                <input type="text" class="input-field" id="edit-description-input" placeholder="Description">
            </div>
        </div>
        <div class="options-content">
            <button class="button-nboc" id="btn_e_cancel">
                <span>Cancel</span>
            </button>
            <button class="button-nboc" id="btn_e_save">
                <span>Save</span>
            </button>
        </div>
    </div>
</div>

<script src="assets/js/main_script.js"></script>
<script src="assets/js/entry_handler.js"></script>
</body>
</html>
