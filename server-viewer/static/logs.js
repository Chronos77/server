// Gestion des logs
const LOGS_API_BASE = '/api/logs';
const LOG_TYPES = ['map', 'search', 'connect', 'world'];
let isPaused = false;
let refreshInterval = null;
let refreshRate = 2000; // 2 secondes par défaut

// État des logs
const logState = {
    map: { content: '', lastUpdate: 0 },
    search: { content: '', lastUpdate: 0 },
    connect: { content: '', lastUpdate: 0 },
    world: { content: '', lastUpdate: 0 }
};

function initLogs() {
    initializeControls();
    loadAllLogs();
    startAutoRefresh();
}

function initializeControls() {
    const pauseBtn = document.getElementById('pauseBtn');
    const clearBtn = document.getElementById('clearBtn');
    const refreshRateSelect = document.getElementById('refreshRate');
    
    if (pauseBtn) pauseBtn.addEventListener('click', togglePause);
    if (clearBtn) clearBtn.addEventListener('click', clearAllLogs);
    if (refreshRateSelect) {
        refreshRateSelect.addEventListener('change', (e) => {
            refreshRate = parseInt(e.target.value);
            restartAutoRefresh();
        });
    }
}

async function loadAllLogs() {
    if (isPaused) return;
    
    // Vérifier que l'onglet logs est actif
    const logsTab = document.getElementById('logs-tab');
    if (logsTab && !logsTab.classList.contains('active')) {
        return; // Ne pas charger si l'onglet n'est pas actif
    }
    
    try {
        const response = await fetch(LOGS_API_BASE);
        if (!response.ok) throw new Error('Failed to fetch logs');
        
        const data = await response.json();
        
        LOG_TYPES.forEach(type => {
            if (data[type]) {
                updateLogPanel(type, data[type].lines);
                updateStatus(type, 'active');
            }
        });
    } catch (error) {
        console.error('Error loading logs:', error);
        LOG_TYPES.forEach(type => {
            updateStatus(type, 'error');
            showError(type, 'Erreur de chargement');
        });
    }
}

function updateLogPanel(type, lines) {
    const contentDiv = document.getElementById(`${type}-content`);
    if (!contentDiv) return;
    
    // Convertir les lignes en HTML
    const html = lines.map(line => {
        const trimmedLine = line.trim();
        if (!trimmedLine) return '';
        
        let className = 'log-line';
        if (trimmedLine.toLowerCase().includes('error') || trimmedLine.toLowerCase().includes('critical')) {
            className += ' error';
        } else if (trimmedLine.toLowerCase().includes('warn')) {
            className += ' warn';
        } else if (trimmedLine.toLowerCase().includes('info')) {
            className += ' info';
        } else if (trimmedLine.toLowerCase().includes('debug')) {
            className += ' debug';
        }
        
        return `<div class="${className}">${escapeHtml(trimmedLine)}</div>`;
    }).join('');
    
    contentDiv.innerHTML = html;
    
    // Auto-scroll vers le bas
    contentDiv.scrollTop = contentDiv.scrollHeight;
    
    logState[type].content = html;
    logState[type].lastUpdate = Date.now();
}

function updateStatus(type, status) {
    const statusEl = document.getElementById(`${type}-status`);
    if (statusEl) {
        statusEl.className = `status ${status}`;
        statusEl.textContent = status === 'active' ? '● Actif' : '● Erreur';
    }
}

function showError(type, message) {
    const contentDiv = document.getElementById(`${type}-content`);
    if (contentDiv) {
        contentDiv.innerHTML = `<div class="error-message">${escapeHtml(message)}</div>`;
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function togglePause() {
    isPaused = !isPaused;
    const pauseBtn = document.getElementById('pauseBtn');
    
    if (isPaused) {
        pauseBtn.textContent = '▶ Play';
        pauseBtn.style.background = '#10b981';
        stopAutoRefresh();
    } else {
        pauseBtn.textContent = '⏸ Pause';
        pauseBtn.style.background = '#667eea';
        loadAllLogs();
        startAutoRefresh();
    }
}

function clearAllLogs() {
    LOG_TYPES.forEach(type => {
        const contentDiv = document.getElementById(`${type}-content`);
        if (contentDiv) {
            contentDiv.innerHTML = '<div class="loading">Logs effacés</div>';
        }
        logState[type].content = '';
    });
}

function startAutoRefresh() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
    refreshInterval = setInterval(() => {
        // Vérifier que l'onglet logs est actif avant de charger
        const logsTab = document.getElementById('logs-tab');
        if (!isPaused && logsTab && logsTab.classList.contains('active')) {
            loadAllLogs();
        }
    }, refreshRate);
}

function stopAutoRefresh() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
}

function restartAutoRefresh() {
    stopAutoRefresh();
    if (!isPaused) {
        startAutoRefresh();
    }
}

// Gérer la visibilité de la page
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        stopAutoRefresh();
    } else if (!isPaused) {
        loadAllLogs();
        startAutoRefresh();
    }
});

