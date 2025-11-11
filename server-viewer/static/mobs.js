// Configuration
const MOBS_API_BASE = '/api/mobs';
let currentMobId = null;
let mobsInitialized = false;
let lastSearchResults = null;
let lastSearchQuery = null;

// Initialisation des mobs
function initializeMobs() {
    if (mobsInitialized) return;
    mobsInitialized = true;
    
    // Recherche par Enter ou bouton
    const searchInput = document.getElementById('searchInput');
    const searchBtn = document.getElementById('searchBtn');
    
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                performSearch();
            }
        });
    }
    
    if (searchBtn) {
        searchBtn.addEventListener('click', performSearch);
    }
    
    // Charger le mob depuis l'URL si présent
    loadMobFromURL();
    
    // Écouter les changements d'URL (bouton retour/avant du navigateur)
    window.addEventListener('hashchange', () => {
        if (window.location.hash.startsWith('#mobs')) {
            loadMobFromURL();
        }
    });
}

// Charger le mob depuis l'URL
function loadMobFromURL() {
    const hash = window.location.hash;
    
    // Format: #mobs/17318459 ou #mobs/pool/123
    const mobsMatch = hash.match(/^#mobs\/(\d+)$/);
    const poolMatch = hash.match(/^#mobs\/pool\/(\d+)$/);
    
    if (mobsMatch) {
        const mobId = mobsMatch[1];
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.value = mobId;
        }
        loadMobDetails(mobId);
    } else if (poolMatch) {
        const poolId = poolMatch[1];
        loadMobDetailsByPool(poolId);
    }
}

function performSearch() {
    const searchInput = document.getElementById('searchInput');
    const query = searchInput.value.trim();
    
    if (!query) {
        showError('Veuillez entrer un ID ou un nom de mob');
        return;
    }
    
    // Si c'est un nombre, chercher directement par ID
    if (/^\d+$/.test(query)) {
        // Réinitialiser les résultats de recherche pour les recherches par ID
        lastSearchResults = null;
        lastSearchQuery = null;
        loadMobDetails(query);
    } else {
        // Sinon, chercher par nom
        searchMobsByName(query);
    }
}

async function searchMobsByName(query) {
    showLoading();
    hideError();
    hideMobDetails();
    
    try {
        const response = await fetch(`${MOBS_API_BASE}/search?q=${encodeURIComponent(query)}&limit=20`);
        if (!response.ok) throw new Error('Failed to search');
        
        const results = await response.json();
        
        if (results.length === 0) {
            showError('Aucun mob trouvé avec ce nom');
            return;
        }
        
        // Si un seul résultat, charger directement
        if (results.length === 1) {
            const mob = results[0];
            if (mob.mobid) {
                loadMobDetails(mob.mobid);
            } else if (mob.poolid) {
                loadMobDetailsByPool(mob.poolid);
            } else {
                showError('Aucun ID de mob trouvé dans les résultats');
            }
            return;
        }
        
        // Afficher la liste de sélection si plusieurs résultats
        showSearchResults(results, query);
    } catch (error) {
        console.error('Error searching mobs:', error);
        showError('Erreur lors de la recherche');
    }
}

// Afficher les résultats de recherche pour sélection
function showSearchResults(results, query) {
    hideLoading();
    
    // Sauvegarder les résultats pour le bouton retour
    lastSearchResults = results;
    lastSearchQuery = query;
    
    const mobDetails = document.getElementById('mobDetails');
    const searchInput = document.getElementById('searchInput');
    
    let html = `
        <div class="search-results-container">
            <h3>Résultats de recherche pour "${escapeHtml(query)}" (${results.length} trouvé${results.length > 1 ? 's' : ''})</h3>
            <div class="search-results-list">
    `;
    
    results.forEach((mob, index) => {
        const name = mob.display_name || mob.mobname || mob.name || mob.packet_name || 'Unknown';
        const mobId = mob.mobid || 'N/A';
        const poolId = mob.poolid || '';
        
        html += `
            <div class="search-result-item" data-mobid="${mobId}" data-poolid="${poolId}">
                <div class="search-result-name">${escapeHtml(name)}</div>
                <div class="search-result-details">
                    <span class="search-result-id">ID: ${mobId}</span>
                    ${poolId ? `<span class="search-result-pool">| Pool: ${poolId}</span>` : ''}
                </div>
            </div>
        `;
    });
    
    html += `
            </div>
        </div>
    `;
    
    mobDetails.innerHTML = html;
    mobDetails.classList.remove('hidden');
    
    // Ajouter les event listeners pour la sélection
    mobDetails.querySelectorAll('.search-result-item').forEach(item => {
        item.addEventListener('click', () => {
            const mobId = item.dataset.mobid;
            const poolId = item.dataset.poolid;
            
            if (mobId && mobId !== 'N/A') {
                loadMobDetails(mobId);
            } else if (poolId) {
                loadMobDetailsByPool(poolId);
            }
        });
    });
}

async function loadMobDetails(mobId) {
    showLoading();
    hideError();
    hideMobDetails();
    
    currentMobId = mobId;
    
    // Mettre à jour l'URL sans recharger la page
    updateURLForMob(mobId);
    
    try {
        const response = await fetch(`${MOBS_API_BASE}/${mobId}`);
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('Mob non trouvé');
            }
            throw new Error('Erreur lors du chargement');
        }
        
        const mob = await response.json();
        displayMobDetails(mob);
    } catch (error) {
        console.error('Error loading mob details:', error);
        showError(error.message || 'Erreur lors du chargement des détails du mob');
        // Réinitialiser les résultats de recherche en cas d'erreur
        lastSearchResults = null;
        lastSearchQuery = null;
    }
}

// Mettre à jour l'URL pour le mob
function updateURLForMob(mobId) {
    const newHash = `#mobs/${mobId}`;
    if (window.location.hash !== newHash) {
        window.history.pushState(null, '', newHash);
    }
}

async function loadMobDetailsByPool(poolId) {
    showLoading();
    hideError();
    hideMobDetails();
    
    // Mettre à jour l'URL pour le pool
    const newHash = `#mobs/pool/${poolId}`;
    if (window.location.hash !== newHash) {
        window.history.pushState(null, '', newHash);
    }
    
    try {
        const response = await fetch(`${MOBS_API_BASE}/pool/${poolId}`);
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('Pool non trouvé');
            }
            throw new Error('Erreur lors du chargement');
        }
        
        const mob = await response.json();
        // Si on a un mobid après la redirection, mettre à jour l'URL
        if (mob.mobid) {
            updateURLForMob(mob.mobid);
            currentMobId = mob.mobid;
        }
        displayMobDetails(mob);
    } catch (error) {
        console.error('Error loading mob details by pool:', error);
        showError(error.message || 'Erreur lors du chargement des détails du mob');
    }
}

function displayMobDetails(mob) {
    hideLoading();
    
    const mobDetails = document.getElementById('mobDetails');
    
    const mobName = mob.mobname || mob.name || mob.packet_name || 'Unknown';
    const zoneName = mob.zone_name || `Zone ${mob.zone_id || 'N/A'}`;
    
    // Bouton retour si on a des résultats de recherche précédents
    const backButton = lastSearchResults && lastSearchResults.length > 1 ? `
        <button class="btn-back" onclick="goBackToSearchResults()">
            ← Retour à la recherche
        </button>
    ` : '';
    
    let html = `
        ${backButton}
        <div class="mob-header">
            <div class="mob-title">
                <span>${escapeHtml(mobName)}</span>
                <span class="mob-id">ID: ${mob.mobid}</span>
            </div>
            <div class="mob-subtitle">${escapeHtml(zoneName)} | Pool ID: ${mob.poolid || 'N/A'}</div>
        </div>
        
        <div class="details-grid">
            ${createSection('📊 Informations Générales', [
                ['Zone', zoneName],
                ['Pool ID', mob.poolid],
                ['Family ID', mob.familyid],
                ['Super Family ID', mob.superFamilyID],
                ['Ecosystem', mob.ecosystemID],
                ['Mob Type', mob.mobType],
                ['Allegiance', mob.allegiance],
                ['Name Visibility', mob.namevis],
                ['Aggro', mob.aggro ? 'Oui' : 'Non'],
                ['True Detection', mob.true_detection ? 'Oui' : 'Non'],
                ['Charmable', mob.charmable ? 'Oui' : 'Non']
            ])}
            
            ${createSection('💪 Statistiques de Base', [
                ['HP', formatNumber(mob.HP)],
                ['MP', formatNumber(mob.MP)],
                ['HP Scale', mob.hp_scale],
                ['MP Scale', mob.mp_scale],
                ['Min Level', mob.minLevel],
                ['Max Level', mob.maxLevel],
                ['Speed', mob.speed],
                ['Radius', mob.mobradius]
            ])}
            
            ${createSection('⚔️ Combat', [
                ['Main Job', getJobName(mob.mJob)],
                ['Sub Job', getJobName(mob.sJob)],
                ['Combat Skill', mob.cmbSkill],
                ['Combat Damage Mult', mob.cmbDmgMult],
                ['Combat Delay', mob.cmbDelay],
                ['Behavior', mob.behavior],
                ['Links', mob.links],
                ['Roam Flag', mob.roamflag],
                ['Immunity', mob.immunity]
            ])}
            
            ${createStatsSection('📈 Attributs', [
                ['STR', mob.STR],
                ['DEX', mob.DEX],
                ['VIT', mob.VIT],
                ['AGI', mob.AGI],
                ['INT', mob.INT],
                ['MND', mob.MND],
                ['CHR', mob.CHR]
            ])}
            
            ${createStatsSection('🛡️ Défenses', [
                ['DEF', mob.DEF],
                ['ATT', mob.ATT],
                ['ACC', mob.ACC],
                ['EVA', mob.EVA]
            ])}
            
            ${createResistancesSection('🔥 Résistances Élémentaires', [
                ['Fire', mob.fire_res_rank],
                ['Ice', mob.ice_res_rank],
                ['Wind', mob.wind_res_rank],
                ['Earth', mob.earth_res_rank],
                ['Lightning', mob.lightning_res_rank],
                ['Water', mob.water_res_rank],
                ['Light', mob.light_res_rank],
                ['Dark', mob.dark_res_rank]
            ])}
            
            ${createResistancesSection('⚡ Résistances aux Status', [
                ['Paralyze', mob.paralyze_res_rank],
                ['Bind', mob.bind_res_rank],
                ['Silence', mob.silence_res_rank],
                ['Slow', mob.slow_res_rank],
                ['Poison', mob.poison_res_rank],
                ['Light Sleep', mob.light_sleep_res_rank],
                ['Dark Sleep', mob.dark_sleep_res_rank],
                ['Blind', mob.blind_res_rank]
            ])}
            
            ${createSDTSection('⚔️ SDT (Shield Defense Type)', [
                ['Slash', mob.slash_sdt],
                ['Pierce', mob.pierce_sdt],
                ['H2H', mob.h2h_sdt],
                ['Impact', mob.impact_sdt],
                ['Magic', mob.magical_sdt],
                ['Fire', mob.fire_sdt],
                ['Ice', mob.ice_sdt],
                ['Wind', mob.wind_sdt],
                ['Earth', mob.earth_sdt],
                ['Lightning', mob.lightning_sdt],
                ['Water', mob.water_sdt],
                ['Light', mob.light_sdt],
                ['Dark', mob.dark_sdt]
            ])}
            
            ${createSection('📍 Spawn', [
                ['Respawn Time', mob.respawntime ? `${mob.respawntime}s` : 'N/A'],
                ['Spawn Type', mob.spawntype],
                ['Position', mob.pos_x && mob.pos_y && mob.pos_z 
                    ? `(${mob.pos_x.toFixed(2)}, ${mob.pos_y.toFixed(2)}, ${mob.pos_z.toFixed(2)})`
                    : 'N/A'],
                ['Rotation', mob.pos_rot !== null && mob.pos_rot !== undefined ? `${mob.pos_rot}°` : 'N/A'],
                ['Element', mob.Element],
                ['Entity Flags', mob.entityFlags],
                ['Animation Sub', mob.animationsub],
                ['Name Prefix', mob.name_prefix || 'N/A']
            ])}
            
            ${createDropsSection('💎 Drops', mob.drops || [])}
            
            ${mob.spawnPoints && mob.spawnPoints.length > 0 ? createSpawnPointsSection('📍 Points de Spawn', mob.spawnPoints) : ''}
            
            ${mob.mods && mob.mods.length > 0 ? createModsSection('🔧 Mods du Mob', mob.mods) : ''}
            
            ${mob.familyMods && mob.familyMods.length > 0 ? createModsSection('🔧 Mods de la Famille', mob.familyMods) : ''}
        </div>
    `;
    
    mobDetails.innerHTML = html;
    mobDetails.classList.remove('hidden');
}

// Fonction globale pour revenir aux résultats de recherche
function goBackToSearchResults() {
    if (lastSearchResults && lastSearchQuery) {
        showSearchResults(lastSearchResults, lastSearchQuery);
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

function createStatsSection(title, stats) {
    return `
        <div class="detail-section">
            <h3>${title}</h3>
            <div class="stats-grid">
                ${stats.map(([label, value]) => `
                    <div class="stat-item">
                        <div class="stat-label">${label}</div>
                        <div class="stat-value">${value !== null && value !== undefined ? value : 'N/A'}</div>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

function createResistancesSection(title, resistances) {
    return `
        <div class="detail-section">
            <h3>${title}</h3>
            <div class="resistances-grid">
                ${resistances.map(([label, value]) => {
                    const val = value !== null && value !== undefined ? value : 0;
                    const className = val > 0 ? 'high' : val < 0 ? 'low' : '';
                    return `
                        <div class="resistance-item">
                            <div class="resistance-label">${label}</div>
                            <div class="resistance-value ${className}">${val}</div>
                        </div>
                    `;
                }).join('')}
            </div>
        </div>
    `;
}

function createSDTSection(title, sdts) {
    return `
        <div class="detail-section">
            <h3>${title}</h3>
            <div class="resistances-grid">
                ${sdts.map(([label, value]) => {
                    const val = value !== null && value !== undefined ? value : 100;
                    const className = val < 100 ? 'high' : val > 100 ? 'low' : '';
                    return `
                        <div class="resistance-item">
                            <div class="resistance-label">${label}</div>
                            <div class="resistance-value ${className}">${val}%</div>
                        </div>
                    `;
                }).join('')}
            </div>
        </div>
    `;
}

function createDropsSection(title, drops) {
    // Si pas de drops, afficher un message
    if (!drops || drops.length === 0) {
        return `
            <div class="detail-section" style="grid-column: 1 / -1;">
                <h3>${title}</h3>
                <div class="drops-list">
                    <div class="drop-item no-drops">
                        <span class="drop-item-name">Aucun drop disponible</span>
                    </div>
                </div>
            </div>
        `;
    }
    
    // Grouper les drops par groupId
    const grouped = {};
    const ungrouped = [];
    
    drops.forEach(drop => {
        if (drop.groupId) {
            if (!grouped[drop.groupId]) {
                grouped[drop.groupId] = [];
            }
            grouped[drop.groupId].push(drop);
        } else {
            ungrouped.push(drop);
        }
    });
    
    let html = `
        <div class="detail-section" style="grid-column: 1 / -1;">
            <h3>${title}</h3>
            <div class="drops-list">
    `;
    
    // Afficher les groupes
    Object.keys(grouped).sort().forEach(groupId => {
        const group = grouped[groupId];
        const groupRate = group[0].groupRate || 0;
        html += `
            <div style="margin-bottom: 15px;">
                <div style="font-weight: 600; color: #667eea; margin-bottom: 8px;">
                    Groupe ${groupId} (Taux: ${(groupRate / 10).toFixed(1)}%)
                </div>
        `;
        group.forEach(drop => {
            const itemName = drop.item_name || `Item ${drop.itemId}`;
            const rate = drop.itemRate ? (drop.itemRate / 10).toFixed(1) : '0.0';
            html += `
                <div class="drop-item">
                    <span class="drop-item-name">${escapeHtml(itemName)} (ID: ${drop.itemId})</span>
                    <span class="drop-item-rate">${rate}%</span>
                </div>
            `;
        });
        html += `</div>`;
    });
    
    // Afficher les drops non groupés
    ungrouped.forEach(drop => {
        const itemName = drop.item_name || `Item ${drop.itemId}`;
        const rate = drop.itemRate ? (drop.itemRate / 10).toFixed(1) : '0.0';
        html += `
            <div class="drop-item">
                <span class="drop-item-name">${escapeHtml(itemName)} (ID: ${drop.itemId})</span>
                <span class="drop-item-rate">${rate}%</span>
            </div>
        `;
    });
    
    html += `
            </div>
        </div>
    `;
    
    return html;
}

function createSpawnPointsSection(title, spawnPoints) {
    return `
        <div class="detail-section" style="grid-column: 1 / -1;">
            <h3>${title}</h3>
            <div class="spawn-points-list">
                ${spawnPoints.map((spawn, index) => `
                    <div class="spawn-point">
                        <strong>Point ${index + 1}:</strong> 
                        (${spawn.pos_x.toFixed(2)}, ${spawn.pos_y.toFixed(2)}, ${spawn.pos_z.toFixed(2)}) 
                        Rot: ${spawn.pos_rot}°
                        ${spawn.spawnset ? `| Spawnset: ${spawn.spawnset}` : ''}
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

function createModsSection(title, mods) {
    return `
        <div class="detail-section">
            <h3>${title}</h3>
            ${mods.map(mod => `
                <div class="detail-row">
                    <span class="detail-label">Mod ${mod.modid}</span>
                    <span class="detail-value">${mod.value}</span>
                </div>
            `).join('')}
        </div>
    `;
}

function getJobName(jobId) {
    const jobs = {
        0: 'NONE', 1: 'WAR', 2: 'MNK', 3: 'WHM', 4: 'BLM', 5: 'RDM',
        6: 'THF', 7: 'PLD', 8: 'DRK', 9: 'BST', 10: 'BRD', 11: 'RNG',
        12: 'SAM', 13: 'NIN', 14: 'DRG', 15: 'SMN', 16: 'BLU',
        17: 'COR', 18: 'PUP', 19: 'DNC', 20: 'SCH', 21: 'GEO', 22: 'RUN'
    };
    return jobs[jobId] || `Job ${jobId}`;
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

function showLoading() {
    document.getElementById('loading').classList.remove('hidden');
}

function hideLoading() {
    document.getElementById('loading').classList.add('hidden');
}

function showError(message) {
    const errorDiv = document.getElementById('error');
    errorDiv.textContent = message;
    errorDiv.classList.remove('hidden');
}

function hideError() {
    document.getElementById('error').classList.add('hidden');
}

function hideMobDetails() {
    document.getElementById('mobDetails').classList.add('hidden');
}

