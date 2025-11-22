// Configuration
const ITEMS_API_BASE = '/api/items';
let currentItemId = null;
let itemsInitialized = false;
let itemLastSearchResults = null;
let itemLastSearchQuery = null;

// Initialisation des items
function initializeItems() {
    if (itemsInitialized) return;
    itemsInitialized = true;
    
    // Recherche par Enter ou bouton
    const searchInput = document.getElementById('itemSearchInput');
    const searchBtn = document.getElementById('itemSearchBtn');
    
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                performItemSearch();
            }
        });
    }
    
    if (searchBtn) {
        searchBtn.addEventListener('click', performItemSearch);
    }
    
    // Charger l'item depuis l'URL si présent
    loadItemFromURL();
    
    // Écouter les changements d'URL (bouton retour/avant du navigateur)
    window.addEventListener('hashchange', () => {
        if (window.location.hash.startsWith('#items')) {
            loadItemFromURL();
        }
    });
}

// Charger l'item depuis l'URL
function loadItemFromURL() {
    const hash = window.location.hash;
    
    // Format: #items/4096
    const itemsMatch = hash.match(/^#items\/(\d+)$/);
    
    if (itemsMatch) {
        const itemId = itemsMatch[1];
        const searchInput = document.getElementById('itemSearchInput');
        if (searchInput) {
            searchInput.value = itemId;
        }
        loadItemDetails(itemId);
    }
}

function performItemSearch() {
    const searchInput = document.getElementById('itemSearchInput');
    const query = searchInput.value.trim();
    
    if (!query) {
        showItemError('Veuillez entrer un ID ou un nom d\'item');
        return;
    }
    
    // Si c'est un nombre, chercher directement par ID
    if (/^\d+$/.test(query)) {
        // Réinitialiser les résultats de recherche pour les recherches par ID
        itemLastSearchResults = null;
        itemLastSearchQuery = null;
        loadItemDetails(query);
    } else {
        // Sinon, chercher par nom
        searchItemsByName(query);
    }
}

async function searchItemsByName(query) {
    showItemLoading();
    hideItemError();
    hideItemDetails();
    
    try {
        const response = await fetch(`${ITEMS_API_BASE}/search?q=${encodeURIComponent(query)}&limit=20`);
        if (!response.ok) throw new Error('Failed to search');
        
        const results = await response.json();
        
        if (results.length === 0) {
            showItemError('Aucun item trouvé avec ce nom');
            return;
        }
        
        // Si un seul résultat, charger directement
        if (results.length === 1) {
            const item = results[0];
            if (item.itemid) {
                loadItemDetails(item.itemid);
            } else {
                showItemError('Aucun ID d\'item trouvé dans les résultats');
            }
            return;
        }
        
        // Afficher la liste de sélection si plusieurs résultats
        showItemSearchResults(results, query);
    } catch (error) {
        console.error('Error searching items:', error);
        showItemError('Erreur lors de la recherche');
    }
}

// Afficher les résultats de recherche pour sélection
function showItemSearchResults(results, query) {
    hideItemLoading();
    
    // Sauvegarder les résultats pour le bouton retour
    itemLastSearchResults = results;
    itemLastSearchQuery = query;
    
    const itemDetails = document.getElementById('itemDetails');
    
    let html = `
        <div class="search-results-container">
            <h3>Résultats de recherche pour "${escapeHtml(query)}" (${results.length} trouvé${results.length > 1 ? 's' : ''})</h3>
            <div class="search-results-list">
    `;
    
    results.forEach((item, index) => {
        const name = item.name || 'Unknown';
        const itemId = item.itemid || 'N/A';
        const type = getItemTypeName(item.type);
        
        html += `
            <div class="search-result-item" data-itemid="${itemId}">
                <div class="search-result-name">${escapeHtml(name)}</div>
                <div class="search-result-details">
                    <span class="search-result-id">ID: ${itemId}</span>
                    <span class="search-result-pool">| Type: ${type}</span>
                </div>
            </div>
        `;
    });
    
    html += `
            </div>
        </div>
    `;
    
    itemDetails.innerHTML = html;
    itemDetails.classList.remove('hidden');
    
    // Ajouter les event listeners pour la sélection
    itemDetails.querySelectorAll('.search-result-item').forEach(item => {
        item.addEventListener('click', () => {
            const itemId = item.dataset.itemid;
            
            if (itemId && itemId !== 'N/A') {
                loadItemDetails(itemId);
            }
        });
    });
}

async function loadItemDetails(itemId) {
    showItemLoading();
    hideItemError();
    hideItemDetails();
    
    currentItemId = itemId;
    
    // Mettre à jour l'URL sans recharger la page
    updateURLForItem(itemId);
    
    try {
        const response = await fetch(`${ITEMS_API_BASE}/${itemId}`);
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('Item non trouvé');
            }
            throw new Error('Erreur lors du chargement');
        }
        
        const item = await response.json();
        displayItemDetails(item);
    } catch (error) {
        console.error('Error loading item details:', error);
        showItemError(error.message || 'Erreur lors du chargement des détails de l\'item');
        // Réinitialiser les résultats de recherche en cas d'erreur
        itemLastSearchResults = null;
        itemLastSearchQuery = null;
    }
}

// Mettre à jour l'URL pour l'item
function updateURLForItem(itemId) {
    const newHash = `#items/${itemId}`;
    if (window.location.hash !== newHash) {
        window.history.pushState(null, '', newHash);
    }
}

function displayItemDetails(item) {
    hideItemLoading();
    
    const itemDetails = document.getElementById('itemDetails');
    
    const itemName = item.name || 'Unknown';
    
    // Bouton retour si on a des résultats de recherche précédents
    const backButton = itemLastSearchResults && itemLastSearchResults.length > 1 ? `
        <button class="btn-back" onclick="goBackToItemSearchResults()">
            ← Retour à la recherche
        </button>
    ` : '';
    
    let html = `
        ${backButton}
        <div class="mob-header">
            <div class="mob-title">
                <span>${escapeHtml(itemName)}</span>
                <span class="mob-id">ID: ${item.itemid}</span>
            </div>
            <div class="mob-subtitle">Type: ${getItemTypeName(item.type)}</div>
        </div>
        
        <div class="details-grid">
            ${createSection('📊 Informations Générales', [
                ['Item ID', item.itemid],
                ['Sub ID', item.subid],
                ['Nom', item.name],
                ['Nom de tri', item.sortname],
                ['Type', getItemTypeName(item.type)],
                ['Stack Size', item.stackSize],
                ['Flags', formatFlags(item.flags)],
                ['Auction House', item.aH !== null && item.aH !== undefined ? item.aH : 'N/A'],
                ['Prix de vente de base', item.BaseSell ? formatNumber(item.BaseSell) : '0']
            ])}
    `;
    
    // Informations supplémentaires selon le type
    if (item.usable) {
        html += createSection('💊 Utilisable', [
            ['Cibles valides', item.usable.validTargets],
            ['Activation', item.usable.activation],
            ['Animation', item.usable.animation],
            ['Temps d\'animation', item.usable.animationTime],
            ['Charges max', item.usable.maxCharges],
            ['Délai d\'utilisation', item.usable.useDelay],
            ['Délai de réutilisation', item.usable.reuseDelay],
            ['Zone d\'effet', item.usable.aoe ? 'Oui' : 'Non']
        ]);
    }
    
    if (item.equipment) {
        html += createSection('🛡️ Équipement', [
            ['Niveau', item.equipment.level],
            ['Item Level', item.equipment.ilevel],
            ['Jobs', formatJobs(item.equipment.jobs)],
            ['Model ID', item.equipment.MId],
            ['Taille de bouclier', item.equipment.shieldSize],
            ['Type de script', item.equipment.scriptType],
            ['Slot', item.equipment.slot],
            ['R-Slot', item.equipment.rslot],
            ['SU Level', item.equipment.su_level],
            ['R-Slot Look', item.equipment.rslotlook]
        ]);
    }
    
    if (item.weapon) {
        html += createSection('⚔️ Arme', [
            ['Compétence', item.weapon.skill],
            ['Sous-compétence', item.weapon.subskill],
            ['Item Level Skill', item.weapon.ilvl_skill],
            ['Item Level Parry', item.weapon.ilvl_parry],
            ['Item Level M.Acc', item.weapon.ilvl_macc],
            ['Délai', item.weapon.delay],
            ['Dégâts', item.weapon.dmg],
            ['Type de dégâts', item.weapon.dmgType],
            ['Précision', item.weapon.hit],
            ['Points de déverrouillage', item.weapon.unlock_points]
        ]);
    }
    
    if (item.furnishing) {
        html += createSection('🏠 Mobilier', [
            ['Stockage', item.furnishing.storage],
            ['Mog Enhancement', item.furnishing.moghancement],
            ['Élément', item.furnishing.element],
            ['Aura', item.furnishing.aura]
        ]);
    }
    
    if (item.puppet) {
        html += createSection('🎭 Puppet', [
            ['Slot', item.puppet.slot],
            ['Élément', item.puppet.element]
        ]);
    }
    
    html += `
        </div>
    `;
    
    itemDetails.innerHTML = html;
    itemDetails.classList.remove('hidden');
}

// Fonction globale pour revenir aux résultats de recherche
function goBackToItemSearchResults() {
    if (itemLastSearchResults && itemLastSearchQuery) {
        showItemSearchResults(itemLastSearchResults, itemLastSearchQuery);
    }
}

function createSection(title, items) {
    return `
        <div class="detail-section">
            <h3>${title}</h3>
            ${items.map(([label, value]) => `
                <div class="detail-row">
                    <span class="detail-label">${label}</span>
                    <span class="detail-value">${value !== null && value !== undefined ? escapeHtml(String(value)) : 'N/A'}</span>
                </div>
            `).join('')}
        </div>
    `;
}

function getItemTypeName(type) {
    const types = {
        0: 'Basic',
        1: 'General',
        2: 'Usable',
        4: 'Puppet',
        8: 'Equipment',
        16: 'Weapon',
        32: 'Currency',
        64: 'Furnishing',
        128: 'Linkshell'
    };
    return types[type] || `Type ${type}`;
}

function formatFlags(flags) {
    if (flags === null || flags === undefined) return 'N/A';
    const flagNames = [];
    if (flags & 0x0001) flagNames.push('Wallhanging');
    if (flags & 0x0004) flagNames.push('Mystery Box');
    if (flags & 0x0008) flagNames.push('Mog Garden');
    if (flags & 0x0010) flagNames.push('Mail2Account');
    if (flags & 0x0020) flagNames.push('Inscribable');
    if (flags & 0x0040) flagNames.push('No Auction');
    if (flags & 0x0080) flagNames.push('Scroll');
    if (flags & 0x0100) flagNames.push('Linkshell');
    if (flags & 0x0200) flagNames.push('Can Use');
    if (flags & 0x0400) flagNames.push('Can Trade NPC');
    if (flags & 0x0800) flagNames.push('Can Equip');
    if (flags & 0x1000) flagNames.push('No Sale');
    if (flags & 0x2000) flagNames.push('No Delivery');
    if (flags & 0x4000) flagNames.push('EX');
    if (flags & 0x8000) flagNames.push('Rare');
    return flagNames.length > 0 ? flagNames.join(', ') : 'None';
}

function formatJobs(jobs) {
    if (jobs === null || jobs === undefined) return 'N/A';
    const jobNames = [];
    if (jobs & 0x0001) jobNames.push('WAR');
    if (jobs & 0x0002) jobNames.push('MNK');
    if (jobs & 0x0004) jobNames.push('WHM');
    if (jobs & 0x0008) jobNames.push('BLM');
    if (jobs & 0x0010) jobNames.push('RDM');
    if (jobs & 0x0020) jobNames.push('THF');
    if (jobs & 0x0040) jobNames.push('PLD');
    if (jobs & 0x0080) jobNames.push('DRK');
    if (jobs & 0x0100) jobNames.push('BST');
    if (jobs & 0x0200) jobNames.push('BRD');
    if (jobs & 0x0400) jobNames.push('RNG');
    if (jobs & 0x0800) jobNames.push('SAM');
    if (jobs & 0x1000) jobNames.push('NIN');
    if (jobs & 0x2000) jobNames.push('DRG');
    if (jobs & 0x4000) jobNames.push('SMN');
    if (jobs & 0x8000) jobNames.push('BLU');
    if (jobs & 0x10000) jobNames.push('COR');
    if (jobs & 0x20000) jobNames.push('PUP');
    if (jobs & 0x40000) jobNames.push('DNC');
    if (jobs & 0x80000) jobNames.push('SCH');
    if (jobs & 0x100000) jobNames.push('GEO');
    if (jobs & 0x200000) jobNames.push('RUN');
    return jobNames.length > 0 ? jobNames.join(', ') : 'None';
}

function formatNumber(num) {
    if (num === null || num === undefined) return 'N/A';
    return num.toLocaleString('fr-FR');
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function showItemLoading() {
    document.getElementById('itemLoading').classList.remove('hidden');
}

function hideItemLoading() {
    document.getElementById('itemLoading').classList.add('hidden');
}

function showItemError(message) {
    const errorDiv = document.getElementById('itemError');
    errorDiv.textContent = message;
    errorDiv.classList.remove('hidden');
}

function hideItemError() {
    document.getElementById('itemError').classList.add('hidden');
}

function hideItemDetails() {
    document.getElementById('itemDetails').classList.add('hidden');
}


