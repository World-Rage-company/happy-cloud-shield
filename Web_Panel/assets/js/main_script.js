const buttons = document.querySelectorAll('.nav-button');
const sections = {
    'home_section': document.querySelector('.home_section'),
    'block_list_section': document.querySelector('.block_list_section'),
    'setting-section': document.querySelector('.setting-section'),
    'block_entry_background': document.querySelector('.block-entry-background')
};

function hideAllSections() {
    Object.values(sections).forEach(section => {
        if (section) {
            section.classList.remove('active');
        }
    });
}

function showSectionById(sectionId) {
    const section = sections[sectionId];
    if (section) {
        section.classList.add('active');
    }
}

function updateUrlParameter(key, value) {
    const url = new URL(window.location.href);
    if (value === null) {
        url.searchParams.delete(key);
    } else {
        url.searchParams.set(key, value);
    }
    history.pushState(null, '', url.href);
}

function showMessage(type, message) {
    const errorMessage = document.getElementById('error-message');
    const successMessage = document.getElementById('success-message');

    if (type === 'error') {
        errorMessage.textContent = message;
        errorMessage.style.display = 'block';
        successMessage.style.display = 'none';

        setTimeout(() => {
            errorMessage.style.display = 'none';
        }, 3000);
    } else if (type === 'success') {
        successMessage.textContent = message;
        successMessage.style.display = 'block';
        errorMessage.style.display = 'none';

        setTimeout(() => {
            successMessage.style.display = 'none';
        }, 3000);
    }
}

function handlePageLoad() {
    const url = new URL(window.location.href);
    const sectionMap = {
        '/home': 'home_section',
        '/block-list': 'block_list_section',
        '/settings': 'setting-section'
    };

    const sectionId = url.searchParams.get('section');
    const entryId = url.searchParams.get('entryId');
    const showBlockEntry = url.searchParams.get('showBlockEntry') === 'true';
    const currentPath = url.pathname;
    const mappedSectionId = sectionMap[currentPath] || 'home_section';

    const activeSectionId = sectionId && sections[sectionId] ? sectionId : mappedSectionId;

    hideAllSections();
    showSectionById(activeSectionId);

    buttons.forEach(button => {
        const sectionIdForButton = button.id.replace('home', 'home_section')
            .replace('block-list', 'block_list_section')
            .replace('settings', 'setting-section');

        if (sectionIdForButton === activeSectionId) {
            button.classList.add('active');
        } else {
            button.classList.remove('active');
        }
    });

    const blockEntryBackground = sections['block_entry_background'];
    if (blockEntryBackground) {
        blockEntryBackground.style.display = showBlockEntry ? 'block' : 'none';
    }

    if (showBlockEntry && activeSectionId === 'block_list_section') {
        document.querySelector('.new-entry-layout').classList.remove('active');
        fetchEntryData(entryId);
    } else {
        document.querySelector('.new-entry-layout').classList.remove('active');
        document.querySelector('.edit-entry-layout').classList.remove('active');
    }

    if (entryId && activeSectionId === 'block_list_section') {
        fetchEntryData(entryId);
    }
}

function fetchEntryData(entryId) {
    const layout = sections['block_entry_background'];
    const editEntryLayout = document.querySelector('.edit-entry-layout');

    if (layout && editEntryLayout) {
        layout.style.display = 'block';
        editEntryLayout.classList.add('active');

        if (entryId) {
            fetch(`assets/php/get_entry_data.php?id=${entryId}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.entry) {
                        document.getElementById('edit-title-input').value = data.entry.title || '';
                        document.getElementById('edit-address-input').value = data.entry.address || '';
                        document.getElementById('edit-description-input').value = data.entry.description || '';
                        document.getElementById('btn_e_save').setAttribute('data-entry', entryId);
                    } else {
                        showMessage('error', 'Invalid response format');
                    }
                })
                .catch(error => {
                    showMessage('error', 'An error occurred while fetching entry data: ' + error.message);
                });
        } else {
            document.getElementById('edit-title-input').value = '';
            document.getElementById('edit-address-input').value = '';
            document.getElementById('edit-description-input').value = '';
        }
    }
}

buttons.forEach(button => {
    button.addEventListener('click', async () => {
        if (button.id === 'logout') {
            try {
                const response = await fetch('assets/php/logout.php', { method: 'POST' });
                if (response.ok) {
                    window.location.href = 'accounts/login.php';
                } else {
                    const errorText = await response.text();
                    showMessage('error', 'Logout failed: ' + errorText);
                }
            } catch (error) {
                showMessage('error', 'An error occurred: ' + error.message);
            }
            return;
        }

        const sectionId = button.id.replace('home', 'home_section')
            .replace('block-list', 'block_list_section')
            .replace('settings', 'setting-section');

        updateUrlParameter('section', sectionId);
        updateUrlParameter('entryId', null);
        updateUrlParameter('showBlockEntry', 'false');
        hideAllSections();
        showSectionById(sectionId);

        buttons.forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');
    });
});

document.getElementById('add_btn').addEventListener('click', function() {
    const layout = sections['block_entry_background'];
    const newEntryLayout = document.querySelector('.new-entry-layout');
    if (layout) {
        layout.style.display = 'block';
        newEntryLayout.classList.add('active');
        updateUrlParameter('showBlockEntry', 'true');
        updateUrlParameter('entryId', null);
    }
});

document.querySelectorAll('.be-button#btn_edit').forEach(button => {
    button.addEventListener('click', function() {
        const entryId = button.getAttribute('data-entry');
        const layout = sections['block_entry_background'];
        const editEntryLayout = document.querySelector('.edit-entry-layout');

        if (layout && editEntryLayout) {
            layout.style.display = 'block';
            editEntryLayout.classList.add('active');
            updateUrlParameter('showBlockEntry', 'true');
            updateUrlParameter('entryId', entryId);
            fetchEntryData(entryId);
        }
    });
});

function hideBlockEntryBackground() {
    const blockEntryBackground = sections['block_entry_background'];
    const inputFields = document.querySelectorAll('.block-entry-background .input-field');

    if (blockEntryBackground) {
        blockEntryBackground.style.display = 'none';
        document.querySelectorAll('.new-entry-layout, .edit-entry-layout').forEach(layout => {
            layout.classList.remove('active');
        });

        const url = new URL(window.location.href);
        url.searchParams.delete('showBlockEntry');
        url.searchParams.delete('entryId');
        history.pushState(null, '', url.href);

        inputFields.forEach(input => {
            input.value = '';
        });
    }
}

document.getElementById('btn_n_close').addEventListener('click', hideBlockEntryBackground);
document.getElementById('btn_n_cancel').addEventListener('click', hideBlockEntryBackground);
document.getElementById('btn_e_close').addEventListener('click', hideBlockEntryBackground);
document.getElementById('btn_e_cancel').addEventListener('click', hideBlockEntryBackground);

document.addEventListener('DOMContentLoaded', handlePageLoad);
window.addEventListener('popstate', handlePageLoad);
