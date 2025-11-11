// Gestion des onglets et initialisation
document.addEventListener('DOMContentLoaded', () => {
    initializeTabs();
    
    // Initialiser les logs si on est sur l'onglet logs
    const hash = window.location.hash || '#logs';
    if (hash === '#logs' || hash === '') {
        // Attendre un peu pour que les éléments soient disponibles
        setTimeout(() => {
            if (typeof initLogs === 'function') {
                initLogs();
            }
        }, 100);
    } else if (hash.startsWith('#mobs')) {
        // Activer l'onglet mobs
        const mobsTab = document.querySelector('.tab-btn[data-tab="mobs"]');
        const logsTab = document.querySelector('.tab-btn[data-tab="logs"]');
        if (mobsTab && logsTab) {
            logsTab.classList.remove('active');
            mobsTab.classList.add('active');
            document.getElementById('logs-tab')?.classList.remove('active');
            document.getElementById('mobs-tab')?.classList.add('active');
        }
        setTimeout(() => {
            if (typeof initMobs === 'function') {
                initMobs();
            }
        }, 100);
    }
});

function initializeTabs() {
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetTab = button.dataset.tab;
            
            // Mettre à jour les boutons
            tabButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            
            // Mettre à jour le contenu
            tabContents.forEach(content => {
                content.classList.remove('active');
                if (content.id === `${targetTab}-tab`) {
                    content.classList.add('active');
                }
            });
            
            // Mettre à jour l'URL
            window.location.hash = targetTab;
            
            // Initialiser le module correspondant
            if (targetTab === 'logs') {
                if (typeof initLogs === 'function') {
                    initLogs();
                }
            } else if (targetTab === 'mobs') {
                if (typeof initMobs === 'function') {
                    initMobs();
                }
            }
        });
    });
    
    // Gérer le hash au chargement
    window.addEventListener('hashchange', () => {
        const hash = window.location.hash || '#logs';
        const targetTab = hash.substring(1);
        
        tabButtons.forEach(btn => {
            if (btn.dataset.tab === targetTab) {
                btn.click();
            }
        });
    });
    
    // S'assurer que l'onglet par défaut est initialisé
    const initialHash = window.location.hash || '#logs';
    const initialTab = initialHash.substring(1);
    if (initialTab === 'logs' && typeof initLogs === 'function') {
        setTimeout(() => initLogs(), 200);
    } else if (initialTab === 'mobs' && typeof initMobs === 'function') {
        setTimeout(() => initMobs(), 200);
    }
}

// Fonction pour initialiser les mobs (sera définie dans mobs.js)
function initMobs() {
    if (typeof initializeMobs === 'function') {
        initializeMobs();
    }
}
