document.addEventListener('DOMContentLoaded', function() {
    const changeButton = document.getElementById('ss_btn_change_u_p');
    const errorMessage = document.getElementById('error-message');
    const successMessage = document.getElementById('success-message');

    changeButton.addEventListener('click', function() {
        const currentPassword = document.getElementById('current-password-input').value.trim();
        const newUsername = document.getElementById('new-username-input').value.trim();
        const newPassword = document.getElementById('new-password-input').value.trim();
        const confirmNewPassword = document.getElementById('confirm-new-password-input').value.trim();

        if (newPassword !== confirmNewPassword) {
            displayMessage(errorMessage, 'Passwords do not match.');
            return;
        }

        const xhr = new XMLHttpRequest();
        xhr.open('POST', 'assets/php/user_settings_update_handler.php', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    const response = JSON.parse(xhr.responseText);
                    if (response.success) {
                        displayMessage(successMessage, response.message);
                        setTimeout(() => {
                            window.location.reload();
                        }, 3000);
                    } else {
                        displayMessage(errorMessage, response.message);
                    }
                } else {
                    displayMessage(errorMessage, 'An error occurred.');
                }
            }
        };

        xhr.send(`current_password=${encodeURIComponent(currentPassword)}&new_username=${encodeURIComponent(newUsername)}&new_password=${encodeURIComponent(newPassword)}&confirm_new_password=${encodeURIComponent(confirmNewPassword)}`);
    });

    function displayMessage(element, message) {
        element.textContent = message;
        element.style.display = 'block';
        setTimeout(() => {
            element.style.display = 'none';
        }, 3000);
    }
});
