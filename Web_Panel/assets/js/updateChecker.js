const currentVersion = "1.0.0";
const repoUrl = "https://api.github.com/repos/World-Rage-company/happy-cloud-shield/releases/latest";

async function checkForUpdates() {
    try {
        const response = await fetch(repoUrl);
        if (!response.ok) throw new Error("Error fetching release data");
        const latestRelease = await response.json();

        const latestVersion = normalizeVersion(latestRelease.tag_name);
        const releaseDate = new Date(latestRelease.published_at).toLocaleDateString();

        if (isNewerVersion(latestVersion, currentVersion)) {
            document.querySelector(".up-details span:nth-child(1)").textContent = `New Update v${latestVersion}`;
            document.querySelector(".up-details span:nth-child(2)").textContent = releaseDate;

            document.querySelector(".home-message-container").style.display = "flex";
        }
    } catch (error) {
        console.error("Failed to check for updates:", error);
    }
}

function normalizeVersion(version) {
    return version.replace(/-/g, '.').replace(/^v/, '');
}

function isNewerVersion(latestVersion, currentVersion) {
    const latest = latestVersion.split('.').map(Number);
    const current = currentVersion.split('.').map(Number);

    for (let i = 0; i < latest.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
    }

    return false;
}

checkForUpdates();
