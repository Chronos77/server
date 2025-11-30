-----------------------------------
-- Area: Abyssea - Misareaux
--   NM: Ironclad Severer
-- Notes:
-- - Family: Iron Giants
-- - Timepop: Spawns every 15-20 minutes behind Dilapidated Gate (F-7, Conflux #6) in inactive state
-- - HP: ~57,250
-- - When approached and aggroed, rises from ground and becomes targettable
-- - Often spawns fully assembled and quickly becomes aggressive
-- - Immune to Gravity, Bind, Sleep
-- - Susceptible to Stun
-- - Weak to: Water, Lightning
-- - Resistant to: Fire, Ice
-- - Standard attacks inflict knockback, amnesia, or stun
-- - Melee attacks can take 2-4 shadows
-- - Below certain % HP: gains regain or high store TP, can WS twice in a row
-- - Rages after 45+ min: magic resisted more, evasion boost, attacks become stronger
-- Special Abilities:
-- - Ballistic Kick: Conal attack that reduces HP to critical and inflicts 30-sec Encumberance + moderate knockback and hate reset. Long distance (20-30yalm), but can be outran. May attempt to use this move more than once in a row, possibly as HP decreases. Damage based on max HP, not current HP. Damage can be reduced by -PDT gear.
-- - Scapula Beam: AoE Damage + multiple stat downs. Wipes shadows, but much smaller area of effect than Ballistic Kick and much easier to outrun.
-----------------------------------
---@type TMobEntity
local entity = {}

local RAGE_TIMER = 2700 -- 45 minutes in seconds

entity.onMobInitialize = function(mob)
    -- Set immunities
    mob:addImmunity(xi.immunity.BIND)
    mob:addImmunity(xi.immunity.GRAVITY)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    
    -- Susceptible to Stun (no immunity set)
    
    -- Elemental resistances
    -- Weak to Water and Lightning
    mob:setMod(xi.mod.WATER_SDT, -2000) -- Negative = takes more damage
    mob:setMod(xi.mod.THUNDER_SDT, -2000)
    
    -- Resistant to Fire and Ice
    mob:setMod(xi.mod.FIRE_SDT, 2000) -- Positive = takes less damage
    mob:setMod(xi.mod.ICE_SDT, 2000)
    
    -- Standard attacks can take 2-4 shadows
    mob:setMobMod(xi.mobMod.SHADOW_ABSORB, 4) -- Can take up to 4 shadows
end

entity.onMobSpawn = function(mob)
    -- Initialize skill list (896: Ballistic Kick, Scapula Beam)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 896)
    
    -- Set aggressive and detection flags
    -- A, T(H) = Aggressive, True-hearing
    mob:setAggressive(true)
    mob:setTrueDetection(true) -- True-hearing (T(H)) - ignores Sneak
    mob:setMobMod(xi.mobMod.DETECTION, xi.detects.HEARING) -- Detect by hearing
    mob:setMobMod(xi.mobMod.SOUND_RANGE, 12) -- Sound detection range (adjust as needed)
    
    -- Initialize tracking variables
    mob:setLocalVar('[rage]timer', RAGE_TIMER)
    mob:setLocalVar('[rage]started', 0)
    mob:setLocalVar('[ballisticKick]count', 0)
    mob:setLocalVar('[ballisticKick]timer', 0)
    mob:setLocalVar('[wsChain]count', 0)
    mob:setLocalVar('[wsChain]timer', 0)
    mob:setLocalVar('[lowHP]triggered', 0)
    
    -- Spawns in inactive state (will rise when aggroed)
    -- This is typically handled by spawn animation, but we can set it here if needed
end

entity.onMobEngage = function(mob, target)
    -- Set rage timer on engage
    mob:setLocalVar('[rage]at', GetSystemTime() + mob:getLocalVar('[rage]timer'))
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local currentTime = GetSystemTime()
    local rageAt = mob:getLocalVar('[rage]at')
    local rageStarted = mob:getLocalVar('[rage]started')
    local ballisticKickTimer = mob:getLocalVar('[ballisticKick]timer')
    local wsChainTimer = mob:getLocalVar('[wsChain]timer')
    
    -- Rage after 45+ minutes
    if rageAt > 0 and currentTime >= rageAt and rageStarted == 0 then
        mob:setLocalVar('[rage]started', 1)
        
        -- Magic resisted more
        mob:addMod(xi.mod.UDMGMAGIC, 2000) -- Additional magic resistance
        
        -- Evasion boost
        mob:addMod(xi.mod.EVA, 50) -- Adjust value as needed
        
        -- Attacks become stronger
        mob:addMod(xi.mod.ATT, 50) -- Adjust value as needed
        
        -- Message to players about rage (handled by zone text)
        local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
        mob:messageText(mob, ID.text.BOUNDLESS_RAGE, false)
    end
    
    -- Below certain % HP: gains regain or high store TP, can WS twice in a row
    -- Trigger at around 30% HP
    if hpp <= 30 and mob:getLocalVar('[lowHP]triggered') == 0 then
        mob:setLocalVar('[lowHP]triggered', 1)
        
        -- Either regain or high store TP (random)
        if math.random(100) <= 50 then
            -- Gain Regain
            mob:setMod(xi.mod.REGAIN, 50) -- Adjust value as needed
        else
            -- High Store TP
            mob:setMod(xi.mod.STORETP, 100) -- Adjust value as needed
        end
        
        -- Enable WS chaining (can WS twice in a row)
        mob:setLocalVar('[wsChain]enabled', 1)
    end
    
    -- Reset Ballistic Kick chain timer if expired
    if ballisticKickTimer > 0 and currentTime > ballisticKickTimer then
        mob:setLocalVar('[ballisticKick]count', 0)
        mob:setLocalVar('[ballisticKick]timer', 0)
    end
    
    -- Reset WS chain timer if expired
    if wsChainTimer > 0 and currentTime > wsChainTimer then
        mob:setLocalVar('[wsChain]count', 0)
        mob:setLocalVar('[wsChain]timer', 0)
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    local ballisticKick = 2623
    local wsChainEnabled = mob:getLocalVar('[wsChain]enabled')
    local wsChainCount = mob:getLocalVar('[wsChain]count')
    
    -- Track Ballistic Kick usage (can be used multiple times in a row)
    if skillID == ballisticKick then
        local count = mob:getLocalVar('[ballisticKick]count')
        mob:setLocalVar('[ballisticKick]count', count + 1)
        
        -- Set timer to allow chaining (short window)
        mob:setLocalVar('[ballisticKick]timer', GetSystemTime() + 5) -- 5 second window for chaining
        
        -- May attempt to use more than once in a row, especially as HP decreases
        local hpp = mob:getHPP()
        if hpp <= 50 and count < 2 then
            -- Give TP to allow immediate reuse
            mob:setTP(1000)
        end
    end
    
    -- WS chaining (can WS twice in a row when low HP)
    if wsChainEnabled == 1 and wsChainCount < 1 then
        mob:setLocalVar('[wsChain]count', wsChainCount + 1)
        mob:setLocalVar('[wsChain]timer', GetSystemTime() + 3) -- 3 second window
        
        -- Give TP to allow second WS
        mob:setTP(1000)
    end
end

entity.onMobMobskillChoose = function(mob, target)
    local ballisticKick = 2623
    local ballisticKickCount = mob:getLocalVar('[ballisticKick]count')
    local ballisticKickTimer = mob:getLocalVar('[ballisticKick]timer')
    local hpp = mob:getHPP()
    local currentTime = GetSystemTime()
    
    -- Ballistic Kick can be used multiple times in a row, especially as HP decreases
    if hpp <= 50 and ballisticKickCount > 0 and currentTime <= ballisticKickTimer then
        -- Higher chance to use Ballistic Kick again if recently used
        if math.random(100) <= 60 then -- 60% chance to chain
            return ballisticKick
        end
    end
    
    return 0
end

entity.onMobDisengage = function(mob)
    -- Reset tracking variables
    mob:setLocalVar('[ballisticKick]count', 0)
    mob:setLocalVar('[ballisticKick]timer', 0)
    mob:setLocalVar('[wsChain]count', 0)
    mob:setLocalVar('[wsChain]timer', 0)
    mob:setLocalVar('[wsChain]enabled', 0)
    mob:setLocalVar('[lowHP]triggered', 0)
    
    -- Reset rage mods if engaged again
    if mob:getLocalVar('[rage]started') == 1 then
        mob:delMod(xi.mod.UDMGMAGIC, 2000)
        mob:delMod(xi.mod.EVA, 50)
        mob:delMod(xi.mod.ATT, 50)
    end
end

entity.onMobDeath = function(mob, player, optParams)
    -- Grant title: Severer Dismantler
    player:addTitle(xi.title.SEVERER_DISMANTLER)
    
    -- Give Abyssea drops
    xi.abyssea.giveNMDrops(mob, player, zones[xi.zone.ABYSSEA_MISAREAUX])
end

entity.onMobDespawn = function(mob)
    -- Timepop: respawns every 15-20 minutes
    xi.mob.updateNMSpawnPoint(mob)
    mob:setRespawnTime(math.random(900, 1200)) -- 15 to 20 minutes
end

return entity

