#!/usr/bin/env node
/**
 * Serveur Express unifié pour afficher les logs et les détails des mobs/NMs
 */
const express = require('express');
const mariadb = require('mariadb');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('static'));

// Fonction pour parser un fichier Lua et extraire les valeurs SQL
function parseLuaSettings(filePath) {
    try {
        if (!fs.existsSync(filePath)) {
            return null;
        }
        
        const content = fs.readFileSync(filePath, 'utf8');
        const config = {};
        
        // Patterns améliorés pour extraire les valeurs SQL
        // Supporte les guillemets simples, doubles, et les valeurs sans guillemets
        const patterns = {
            host: /SQL_HOST\s*=\s*(?:['"]([^'"]+)['"]|([^\s,]+))/,
            port: /SQL_PORT\s*=\s*(\d+)/,
            user: /SQL_LOGIN\s*=\s*(?:['"]([^'"]+)['"]|([^\s,]+))/,
            password: /SQL_PASSWORD\s*=\s*(?:['"]([^'"]+)['"]|([^\s,]+))/,
            database: /SQL_DATABASE\s*=\s*(?:['"]([^'"]+)['"]|([^\s,]+))/
        };
        
        // Extraire SQL_HOST
        const hostMatch = content.match(patterns.host);
        if (hostMatch) {
            config.host = hostMatch[1] || hostMatch[2];
        }
        
        // Extraire SQL_PORT
        const portMatch = content.match(patterns.port);
        if (portMatch) {
            config.port = parseInt(portMatch[1]);
        }
        
        // Extraire SQL_LOGIN
        const userMatch = content.match(patterns.user);
        if (userMatch) {
            config.user = userMatch[1] || userMatch[2];
        }
        
        // Extraire SQL_PASSWORD
        const passMatch = content.match(patterns.password);
        if (passMatch) {
            config.password = passMatch[1] || passMatch[2];
        }
        
        // Extraire SQL_DATABASE
        const dbMatch = content.match(patterns.database);
        if (dbMatch) {
            config.database = dbMatch[1] || dbMatch[2];
        }
        
        return Object.keys(config).length > 0 ? config : null;
    } catch (error) {
        console.warn(`Error parsing ${filePath}:`, error.message);
        return null;
    }
}

// Configuration de la base de données
// Priorité: settings/network.lua > settings/default/network.lua > valeurs par défaut
let dbConfig = {
    host: '127.0.0.1',
    port: 3306,
    user: 'root',
    password: '',
    database: 'xidb'
};

// Lire depuis settings/network.lua (fichier de configuration principal)
const settingsBasePath = path.join(__dirname, '..', 'settings');
const networkLuaPath = path.join(settingsBasePath, 'network.lua');
const defaultNetworkLuaPath = path.join(settingsBasePath, 'default', 'network.lua');

let luaConfig = null;

// Essayer d'abord le fichier principal settings/network.lua
if (fs.existsSync(networkLuaPath)) {
    luaConfig = parseLuaSettings(networkLuaPath);
    if (luaConfig) {
        console.log('📖 Configuration chargée depuis settings/network.lua');
    }
}

// Si le fichier principal n'existe pas ou n'a pas de config, essayer settings/default/network.lua
if (!luaConfig && fs.existsSync(defaultNetworkLuaPath)) {
    luaConfig = parseLuaSettings(defaultNetworkLuaPath);
    if (luaConfig) {
        console.log('📖 Configuration chargée depuis settings/default/network.lua');
    }
}

// Appliquer la configuration Lua si disponible
if (luaConfig) {
    if (luaConfig.host) dbConfig.host = luaConfig.host;
    if (luaConfig.port) dbConfig.port = luaConfig.port;
    if (luaConfig.user) dbConfig.user = luaConfig.user;
    if (luaConfig.password) dbConfig.password = luaConfig.password;
    if (luaConfig.database) dbConfig.database = luaConfig.database;
}

console.log(`🔌 Configuration DB: ${dbConfig.user}@${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`);

// Pool de connexions à la base de données
let pool = null;

async function initDatabase() {
    try {
        pool = mariadb.createPool({
            host: dbConfig.host,
            port: dbConfig.port,
            user: dbConfig.user,
            password: dbConfig.password,
            database: dbConfig.database,
            connectionLimit: 10,
            acquireTimeout: 10000, // 10 secondes pour obtenir une connexion
            timeout: 10000, // 10 secondes timeout pour les requêtes
            connectTimeout: 5000, // 5 secondes pour établir la connexion initiale
            idleTimeout: 300000, // 5 minutes avant de fermer une connexion inactive
            reconnect: true
        });
        
        // Tester la connexion immédiatement
        let testConn = null;
        try {
            testConn = await pool.getConnection();
            await testConn.query('SELECT 1');
            console.log('✅ Database connection pool created and tested');
        } catch (testError) {
            console.error('❌ Database connection test failed:', testError.message);
            pool = null;
        } finally {
            if (testConn) {
                testConn.release();
            }
        }
    } catch (error) {
        console.error('❌ Failed to create database pool:', error);
        pool = null;
        // Ne pas quitter si la DB n'est pas disponible, on peut toujours afficher les logs
    }
}

const LOG_DIR = path.join(__dirname, '..', 'log');
const LOG_FILES = {
    'map': 'map-server.log',
    'search': 'search-server.log',
    'connect': 'connect-server.log',
    'world': 'world-server.log'
};

/**
 * Lit les dernières lignes d'un fichier sans charger tout le fichier en mémoire
 * Fonctionne même pour des fichiers de plusieurs GB
 */
function getLogTail(filename, maxLines = 200) {
    const filepath = path.join(LOG_DIR, filename);
    
    if (!fs.existsSync(filepath)) {
        return [];
    }
    
    try {
        const stats = fs.statSync(filepath);
        const fileSize = stats.size;
        
        // Taille maximale à lire (2MB pour avoir assez de lignes même si elles sont longues)
        // Pour les très gros fichiers, on lit seulement la fin
        const maxBytesToRead = Math.min(2 * 1024 * 1024, fileSize);
        const startPosition = Math.max(0, fileSize - maxBytesToRead);
        
        // Lire depuis la position calculée
        const buffer = Buffer.allocUnsafe(maxBytesToRead);
        const fd = fs.openSync(filepath, 'r');
        const bytesRead = fs.readSync(fd, buffer, 0, maxBytesToRead, startPosition);
        fs.closeSync(fd);
        
        // Convertir en string et extraire les lignes
        const content = buffer.toString('utf8', 0, bytesRead);
        const allLines = content.split('\n');
        
        // Si on n'a pas lu depuis le début, on ignore la première ligne (probablement incomplète)
        const lines = startPosition > 0 ? allLines.slice(1) : allLines;
        
        // Prendre les N dernières lignes non vides
        const nonEmptyLines = lines.filter(line => line.trim() !== '');
        return nonEmptyLines.slice(-maxLines);
        
    } catch (error) {
        return [`Error reading log: ${error.message}`];
    }
}

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'static', 'index.html'));
});

app.get('/api/logs/:logType', (req, res) => {
    const { logType } = req.params;
    
    if (!LOG_FILES[logType]) {
        return res.status(404).json({ error: 'Invalid log type' });
    }
    
    const filename = LOG_FILES[logType];
    const lines = getLogTail(filename, 200);
    
    res.json({
        type: logType,
        filename: filename,
        lines: lines,
        timestamp: Date.now()
    });
});

app.get('/api/logs', (req, res) => {
    const result = {};
    
    for (const [logType, filename] of Object.entries(LOG_FILES)) {
        result[logType] = {
            filename: filename,
            lines: getLogTail(filename, 200),
            timestamp: Date.now()
        };
    }
    
    res.json(result);
});

// ==================== Routes Mobs ====================

// Recherche de mobs par nom (auto-complétion)
app.get('/api/mobs/search', async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: 'Database not available' });
    }
    
    const query = req.query.q || '';
    const limit = parseInt(req.query.limit) || 20;
    
    if (!query || query.length < 2) {
        return res.json([]);
    }
    
    let conn = null;
    try {
        conn = await pool.getConnection();
        
        // Requête simplifiée : chercher uniquement dans mob_spawn_points (plus rapide)
        // Utiliser un index sur mobname si disponible
        const searchQuery = `
            SELECT DISTINCT 
                msp.mobid,
                msp.mobname as display_name
            FROM mob_spawn_points msp
            WHERE msp.mobname LIKE ?
            AND msp.mobid IS NOT NULL
            ORDER BY msp.mobname
            LIMIT ?
        `;
        
        const searchTerm = `%${query}%`;
        const results = await conn.query(searchQuery, [searchTerm, limit]);
        
        res.json(results);
    } catch (error) {
        console.error('Error searching mobs:', error);
        res.status(500).json({ error: error.message });
    } finally {
        if (conn) {
            conn.release();
        }
    }
});

// Récupérer les détails complets d'un mob par ID
app.get('/api/mobs/:mobId', async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: 'Database not available' });
    }
    
    const mobId = parseInt(req.params.mobId);
    
    if (isNaN(mobId)) {
        return res.status(400).json({ error: 'Invalid mob ID' });
    }
    
    let conn = null;
    try {
        conn = await pool.getConnection();
        
        const mobQuery = `
            SELECT 
                msp.mobname,
                mp.packet_name,
                msp.mobid,
                msp.pos_rot,
                msp.pos_x,
                msp.pos_y,
                msp.pos_z,
                mg.respawntime,
                mg.spawntype,
                mg.dropid,
                mg.HP,
                mg.MP,
                mg.minLevel,
                mg.maxLevel,
                mp.modelid,
                mp.mJob,
                mp.sJob,
                mp.cmbSkill,
                mp.cmbDmgMult,
                mp.cmbDelay,
                mp.behavior,
                mp.links,
                mp.mobType,
                mp.immunity,
                mfs.ecosystemID,
                mfs.mobradius,
                mfs.speed,
                mfs.STR,
                mfs.DEX,
                mfs.VIT,
                mfs.AGI,
                mfs.INT,
                mfs.MND,
                mfs.CHR,
                mfs.EVA,
                mfs.DEF,
                mfs.ATT,
                mfs.ACC,
                mr.slash_sdt,
                mr.pierce_sdt,
                mr.h2h_sdt,
                mr.impact_sdt,
                mr.magical_sdt,
                mr.fire_sdt,
                mr.ice_sdt,
                mr.wind_sdt,
                mr.earth_sdt,
                mr.lightning_sdt,
                mr.water_sdt,
                mr.light_sdt,
                mr.dark_sdt,
                mr.fire_res_rank,
                mr.ice_res_rank,
                mr.wind_res_rank,
                mr.earth_res_rank,
                mr.lightning_res_rank,
                mr.water_res_rank,
                mr.light_res_rank,
                mr.dark_res_rank,
                mr.paralyze_res_rank,
                mr.bind_res_rank,
                mr.silence_res_rank,
                mr.slow_res_rank,
                mr.poison_res_rank,
                mr.light_sleep_res_rank,
                mr.dark_sleep_res_rank,
                mr.blind_res_rank,
                mfs.Element,
                mp.familyid,
                mfs.superFamilyID,
                mp.name_prefix,
                mp.entityFlags,
                mp.animationsub,
                (mfs.HP / 100) as hp_scale,
                (mfs.MP / 100) as mp_scale,
                mp.spellList,
                mg.poolid,
                mg.allegiance,
                mp.namevis,
                mp.aggro,
                mp.roamflag,
                mp.skill_list_id,
                mp.true_detection,
                mfs.detects,
                mfs.charmable,
                zs.name as zone_name,
                zs.zoneid as zone_id
            FROM mob_spawn_points msp
            INNER JOIN mob_groups mg ON msp.groupid = mg.groupid
            INNER JOIN mob_pools mp ON mg.poolid = mp.poolid
            INNER JOIN mob_resistances mr ON mp.resist_id = mr.resist_id
            INNER JOIN mob_family_system mfs ON mp.familyid = mfs.familyID
            INNER JOIN zone_settings zs ON zs.zoneid = ((msp.mobid >> 12) & 0xFFF)
            WHERE msp.mobid = ?
            LIMIT 1
        `;
        
        const mobResults = await conn.query(mobQuery, [mobId]);
        
        if (mobResults.length === 0) {
            return res.status(404).json({ error: 'Mob not found' });
        }
        
        const mob = mobResults[0];
        
        // Calculer la zone depuis le mobid (comme dans le code source)
        const calculatedZoneId = ((mobId >> 12) & 0xFFF);
        
        // Récupérer le dropid depuis mob_groups en cherchant avec le nom du mob et la zone calculée
        let dropid = null;
        if (mob.mobname) {
            const dropIdQuery = `
                SELECT mg.dropid
                FROM mob_groups mg
                INNER JOIN mob_spawn_points msp ON mg.groupid = msp.groupid
                WHERE msp.mobname = ? 
                AND mg.zoneid = ?
                AND mg.dropid > 0
                LIMIT 1
            `;
            const dropIdResults = await conn.query(dropIdQuery, [mob.mobname, calculatedZoneId]);
            if (dropIdResults.length > 0) {
                dropid = dropIdResults[0].dropid;
            }
        }
        
        // Si pas trouvé avec le nom, chercher par mobid et zone
        if (!dropid) {
            const dropIdQuery = `
                SELECT mg.dropid
                FROM mob_groups mg
                INNER JOIN mob_spawn_points msp ON mg.groupid = msp.groupid
                WHERE msp.mobid = ? 
                AND mg.zoneid = ?
                AND mg.dropid > 0
                LIMIT 1
            `;
            const dropIdResults = await conn.query(dropIdQuery, [mobId, calculatedZoneId]);
            if (dropIdResults.length > 0) {
                dropid = dropIdResults[0].dropid;
            }
        }
        
        // Récupérer les drops pour ce dropid
        let drops = [];
        if (dropid) {
            try {
                const dropQuery = `
                    SELECT 
                        mdl.itemId,
                        mdl.dropType,
                        mdl.itemRate,
                        mdl.groupId,
                        mdl.groupRate,
                        mdl.dropId,
                        it.name as item_name
                    FROM mob_droplist mdl
                    LEFT JOIN item_basic it ON mdl.itemId = it.itemid
                    WHERE mdl.dropId = ?
                    ORDER BY mdl.groupId, mdl.itemId
                `;
                drops = await conn.query(dropQuery, [dropid]);
            } catch (dropError) {
                console.error('Error fetching drops:', dropError);
                drops = [];
            }
        }
        
        // Récupérer les spawn points
        const spawnQuery = `
            SELECT 
                pos_x,
                pos_y,
                pos_z,
                pos_rot,
                spawnset
            FROM mob_spawn_points
            WHERE mobid = ?
        `;
        const spawnPoints = await conn.query(spawnQuery, [mobId]);
        
        // Récupérer les mods du mob
        const modsQuery = `
            SELECT 
                modid,
                value
            FROM mob_pool_mods
            WHERE poolid = ?
        `;
        const mods = await conn.query(modsQuery, [mob.poolid]);
        
        // Récupérer les mods de la famille
        const familyModsQuery = `
            SELECT 
                modid,
                value
            FROM mob_family_mods
            WHERE familyid = ?
        `;
        const familyMods = await conn.query(familyModsQuery, [mob.familyid]);
        
        res.json({
            ...mob,
            drops: drops,
            spawnPoints: spawnPoints,
            mods: mods,
            familyMods: familyMods
        });
    } catch (error) {
        console.error('Error fetching mob details:', error);
        res.status(500).json({ error: error.message });
    } finally {
        if (conn) {
            conn.release();
        }
    }
});

// Récupérer les détails complets d'un mob par poolid
app.get('/api/mobs/pool/:poolId', async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: 'Database not available' });
    }
    
    const poolId = parseInt(req.params.poolId);
    
    if (isNaN(poolId)) {
        return res.status(400).json({ error: 'Invalid pool ID' });
    }
    
    let conn = null;
    try {
        conn = await pool.getConnection();
        
        const mobIdQuery = `
            SELECT mobid FROM mob_groups WHERE poolid = ? LIMIT 1
        `;
        const mobIdResults = await conn.query(mobIdQuery, [poolId]);
        
        if (mobIdResults.length === 0) {
            return res.status(404).json({ error: 'Pool not found' });
        }
        
        res.redirect(`/api/mobs/${mobIdResults[0].mobid}`);
    } catch (error) {
        console.error('Error fetching mob by pool:', error);
        res.status(500).json({ error: error.message });
    } finally {
        if (conn) {
            conn.release();
        }
    }
});

// ==================== Routes Items ====================

// Recherche d'items par nom (auto-complétion)
app.get('/api/items/search', async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: 'Database not available' });
    }
    
    const query = req.query.q || '';
    const limit = parseInt(req.query.limit) || 20;
    
    if (!query || query.length < 2) {
        return res.json([]);
    }
    
    let conn = null;
    try {
        conn = await pool.getConnection();
        
        const searchQuery = `
            SELECT 
                itemid,
                name,
                type,
                stackSize,
                flags,
                aH,
                BaseSell
            FROM item_basic
            WHERE name LIKE ?
            ORDER BY name
            LIMIT ?
        `;
        
        const searchTerm = `%${query}%`;
        const results = await conn.query(searchQuery, [searchTerm, limit]);
        
        res.json(results);
    } catch (error) {
        console.error('Error searching items:', error);
        res.status(500).json({ error: error.message });
    } finally {
        if (conn) {
            conn.release();
        }
    }
});

// Récupérer les détails complets d'un item par ID
app.get('/api/items/:itemId', async (req, res) => {
    if (!pool) {
        return res.status(503).json({ error: 'Database not available' });
    }
    
    const itemId = parseInt(req.params.itemId);
    
    if (isNaN(itemId)) {
        return res.status(400).json({ error: 'Invalid item ID' });
    }
    
    let conn = null;
    try {
        conn = await pool.getConnection();
        
        // Récupérer les informations de base
        const itemQuery = `
            SELECT 
                ib.itemid,
                ib.subid,
                ib.name,
                ib.sortname,
                ib.type,
                ib.stackSize,
                ib.flags,
                ib.aH,
                ib.BaseSell
            FROM item_basic ib
            WHERE ib.itemid = ?
            LIMIT 1
        `;
        
        const itemResults = await conn.query(itemQuery, [itemId]);
        
        if (itemResults.length === 0) {
            return res.status(404).json({ error: 'Item not found' });
        }
        
        const item = itemResults[0];
        
        // Récupérer les informations supplémentaires selon le type
        let usable = null;
        let equipment = null;
        let weapon = null;
        let furnishing = null;
        let puppet = null;
        
        // Item usable
        try {
            const usableQuery = `
                SELECT 
                    validTargets,
                    activation,
                    animation,
                    animationTime,
                    maxCharges,
                    useDelay,
                    reuseDelay,
                    aoe
                FROM item_usable
                WHERE itemid = ?
            `;
            const usableResults = await conn.query(usableQuery, [itemId]);
            if (usableResults.length > 0) {
                usable = usableResults[0];
            }
        } catch (e) {
            // Table might not exist or item not usable
        }
        
        // Item equipment
        try {
            const equipQuery = `
                SELECT 
                    level,
                    ilevel,
                    jobs,
                    MId,
                    shieldSize,
                    scriptType,
                    slot,
                    rslot,
                    su_level,
                    rslotlook
                FROM item_equipment
                WHERE itemid = ?
            `;
            const equipResults = await conn.query(equipQuery, [itemId]);
            if (equipResults.length > 0) {
                equipment = equipResults[0];
            }
        } catch (e) {
            // Table might not exist or item not equipment
        }
        
        // Item weapon
        try {
            const weaponQuery = `
                SELECT 
                    skill,
                    subskill,
                    ilvl_skill,
                    ilvl_parry,
                    ilvl_macc,
                    delay,
                    dmg,
                    dmgType,
                    hit,
                    unlock_points
                FROM item_weapon
                WHERE itemid = ?
            `;
            const weaponResults = await conn.query(weaponQuery, [itemId]);
            if (weaponResults.length > 0) {
                weapon = weaponResults[0];
            }
        } catch (e) {
            // Table might not exist or item not weapon
        }
        
        // Item furnishing
        try {
            const furnishingQuery = `
                SELECT 
                    storage,
                    moghancement,
                    element,
                    aura
                FROM item_furnishing
                WHERE itemid = ?
            `;
            const furnishingResults = await conn.query(furnishingQuery, [itemId]);
            if (furnishingResults.length > 0) {
                furnishing = furnishingResults[0];
            }
        } catch (e) {
            // Table might not exist or item not furnishing
        }
        
        // Item puppet
        try {
            const puppetQuery = `
                SELECT 
                    slot,
                    element
                FROM item_puppet
                WHERE itemid = ?
            `;
            const puppetResults = await conn.query(puppetQuery, [itemId]);
            if (puppetResults.length > 0) {
                puppet = puppetResults[0];
            }
        } catch (e) {
            // Table might not exist or item not puppet
        }
        
        res.json({
            ...item,
            usable: usable,
            equipment: equipment,
            weapon: weapon,
            furnishing: furnishing,
            puppet: puppet
        });
    } catch (error) {
        console.error('Error fetching item details:', error);
        res.status(500).json({ error: error.message });
    } finally {
        if (conn) {
            conn.release();
        }
    }
});

const port = process.env.PORT || 5000;

console.log(`Log directory: ${LOG_DIR}`);
console.log(`Available logs: ${Object.values(LOG_FILES).join(', ')}`);
console.log(`Starting unified server viewer on http://0.0.0.0:${port}`);

// Initialiser la base de données au démarrage
initDatabase().then(() => {
    app.listen(port, '0.0.0.0', () => {
        console.log(`✅ Unified server viewer running on port ${port}`);
        console.log(`   - Logs viewer: http://localhost:${port}/#logs`);
        console.log(`   - Mobs viewer: http://localhost:${port}/#mobs`);
        console.log(`   - Items viewer: http://localhost:${port}/#items`);
    });
}).catch(error => {
    console.warn('⚠️  Database initialization failed, continuing with logs only');
    app.listen(port, '0.0.0.0', () => {
        console.log(`✅ Server viewer running on port ${port} (logs only - database unavailable)`);
    });
});

