const buttons = document.querySelectorAll('.nav-button');
const sections = {
    'home_section': document.querySelector('.home_section'),
    'block_list_section': document.querySelector('.block_list_section'),
    'setting-section': document.querySelector('.setting-section')
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
    url.searchParams.set(key, value);
    history.pushState(null, '', url.href);
}

function showMessage(type, message) {
    const messageContainer = document.querySelector('.message-container');
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

function handlePageLoad() {
    const url = new URL(window.location.href);
    const sectionMap = {
        '/home': 'home_section',
        '/block-list': 'block_list_section',
        '/settings': 'setting-section'
    };

    const sectionId = url.searchParams.get('section');
    const currentPath = url.pathname;
    const mappedSectionId = sectionMap[currentPath] || 'home_section';

    if (!sectionId || !sections[sectionId]) {
        updateUrlParameter('section', mappedSectionId);
    }

    hideAllSections();
    showSectionById(sectionId || mappedSectionId);

    buttons.forEach(button => {
        const sectionIdForButton = button.id.replace('home', 'home_section')
            .replace('block-list', 'block_list_section')
            .replace('settings', 'setting-section');

        if (sectionIdForButton === (sectionId || mappedSectionId)) {
            button.classList.add('active');
        } else {
            button.classList.remove('active');
        }
    });
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
        hideAllSections();
        showSectionById(sectionId);

        buttons.forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');
    });
});

document.addEventListener('DOMContentLoaded', handlePageLoad);
window.addEventListener('popstate', handlePageLoad);

document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('search-input');
    const blockedEntries = document.querySelectorAll('.blocked-entry');

    searchInput.addEventListener('input', function() {
        const query = searchInput.value.toLowerCase();
        blockedEntries.forEach(entry => {
            const title = entry.querySelector('.entry-title').textContent.toLowerCase();
            if (title.includes(query)) {
                entry.style.display = '';
            } else {
                entry.style.display = 'none';
            }
        });
    });
});
