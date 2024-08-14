document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('btn_n_save').addEventListener('click', function() {
        const address = document.getElementById('address-input').value.trim();
        const title = document.getElementById('title-input').value.trim();
        const description = document.getElementById('description-input').value.trim();

        if (!address || !title) {
            showMessage('error', 'Please fill in all required fields.');
            setTimeout(hideMessages, 3000);
            return;
        }

        const data = new URLSearchParams();
        data.append('address', address);
        data.append('title', title);
        data.append('description', description);

        fetch('assets/php/new_block_handler.php', {
            method: 'POST',
            body: data,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        })
            .then(response => response.json())
            .then(result => {
                if (result.success) {
                    showMessage('success', result.message);
                    setTimeout(() => {
                        const url = new URL(window.location.href);
                        url.searchParams.delete('showBlockEntry');
                        history.pushState(null, '', url.href);

                        setTimeout(() => {
                            location.reload();
                        }, 2000);
                    }, 3000);
                } else {
                    showMessage('error', result.message);
                    setTimeout(hideMessages, 3000);
                }
            })
            .catch(error => {
                showMessage('error', 'An error occurred: ' + error.message);
                setTimeout(hideMessages, 3000);
            });
    });

    document.getElementById('btn_e_save').addEventListener('click', function() {
        const urlParams = new URLSearchParams(window.location.search);
        const entryId = urlParams.get('entryId');

        const address = document.getElementById('edit-address-input').value.trim();
        const title = document.getElementById('edit-title-input').value.trim();
        const description = document.getElementById('edit-description-input').value.trim();

        if (!address || !title) {
            showMessage('error', 'Please fill in all required fields.');
            setTimeout(hideMessages, 3000);
            return;
        }

        const data = new URLSearchParams();
        data.append('entry_id', entryId);
        data.append('address', address);
        data.append('title', title);
        data.append('description', description);

        fetch('assets/php/edit_block_handler.php', {
            method: 'POST',
            body: data,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        })
            .then(response => response.json())
            .then(result => {
                if (result.success) {
                    showMessage('success', result.message);
                    setTimeout(() => {
                        const url = new URL(window.location.href);
                        url.searchParams.delete('showBlockEntry');
                        url.searchParams.delete('entryId');
                        history.pushState(null, '', url.href);
                        location.reload();
                    }, 2000);
                } else {
                    showMessage('error', result.message);
                    setTimeout(hideMessages, 3000);
                }
            })
            .catch(error => {
                showMessage('error', 'An error occurred: ' + error.message);
                setTimeout(hideMessages, 3000);
            });
    });

    document.querySelectorAll('#btn_delete').forEach(button => {
        button.addEventListener('click', function() {
            const entryId = this.getAttribute('data-entry');

            if (entryId) {
                fetch('assets/php/delete_entry_handler.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body: `entry_id=${entryId}`
                })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            showMessage('success', data.message);
                            setTimeout(() => {
                                location.reload();
                            }, 2000);
                        } else {
                            showMessage('error', data.message);
                            setTimeout(hideMessages, 3000);
                        }
                    })
                    .catch(error => {
                        showMessage('error', 'Error occurred while deleting the entry.');
                        setTimeout(hideMessages, 3000);
                    });
            }
        });
    });

    function showMessage(type, message) {
        const errorMessage = document.getElementById('error-message');
        const successMessage = document.getElementById('success-message');

        if (type === 'error') {
            errorMessage.textContent = message;
            errorMessage.style.display = 'block';
            successMessage.style.display = 'none';
        } else if (type === 'success') {
            successMessage.textContent = message;
            successMessage.style.display = 'block';
            errorMessage.style.display = 'none';
        }
    }

    function hideMessages() {
        const errorMessage = document.getElementById('error-message');
        const successMessage = document.getElementById('success-message');

        errorMessage.style.display = 'none';
        successMessage.style.display = 'none';
    }
});
