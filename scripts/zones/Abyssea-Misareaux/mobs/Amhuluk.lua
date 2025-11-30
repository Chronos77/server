-----------------------------------
-- Area: Abyssea - Misareaux
--   NM: Amhuluk
-- Notes:
-- - Family: Amphipteres
-- - HP: 60,000~62,000 (DB: 70,000)
-- - MP: 0
-- - Has Regain
-- - Highly resistant to most Enfeebling Magic; Blind, Poison, Paralyze and Addle seem to be the only effective Enfeebles
-- - May often use 2 TP abilities back-to-back when it has TP, including Vermillion Wind 2x in a row
-- - Reaving Wind: TP reset move. Once he starts using Reaving Wind he will not stop using it until the person with hate is within range for one of his other tp attacks.
--   Thus, it is possible to "lock" him into Reaving Wind spam mode until he dies as long as the kiter is far enough away and continues to hold hate.
-- Special Abilities:
-- - Calamitous Wind: AoE Wind magical damage plus knockback and full dispel
-- - Vermillion Wind: Powerful area of effect wind based attack, usually inflicting 1500-2500 damage
-- - Storm Wing: Area of effect attack that inflicts a large amount of damage and Silence
-- - Reaving Wind: TP reset move
-----------------------------------
mixins = { require('scripts/mixins/families/amphiptere') }
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    -- Has Regain
    mob:setMod(xi.mod.REGAIN, 30) -- Adjust value as needed based on testing
    
    -- Highly resistant to most Enfeebling Magic
    -- Only Blind, Poison, Paralyze and Addle are effective
    -- Set high resistance to other enfeebles
    mob:setMod(xi.mod.BINDRES, 100)
    mob:setMod(xi.mod.GRAVITYRES, 100)
    mob:setMod(xi.mod.SLEEPRES, 100)
    mob:setMod(xi.mod.STUNRES, 100)
    mob:setMod(xi.mod.SILENCERES, 100)
    mob:setMod(xi.mod.CHARMRES, 100)
    mob:setMod(xi.mod.PETRIFYRES, 100)
    
    -- Effective enfeebles (no immunities set for these)
    -- Blind, Poison, Paralyze, Addle
end

entity.onMobSpawn = function(mob)
    -- Initialize spell list (231: Aeroga IV, Tornado, Drain, Silencega, Graviga)
    mob:setMobMod(xi.mobMod.SPELL_LIST, 231)
    
    -- Initialize skill list (884)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 884)
    
    -- Track for back-to-back TP moves
    mob:setLocalVar('[tpChain]count', 0)
    mob:setLocalVar('[tpChain]timer', 0)
end

entity.onMobFight = function(mob, target)
    -- May often use 2 TP abilities back-to-back when it has TP
    -- This is handled by the mob skill system, but we track it here
    local tpChainCount = mob:getLocalVar('[tpChain]count')
    local tpChainTimer = mob:getLocalVar('[tpChain]timer')
    
    -- Reset chain timer if expired
    if tpChainTimer > 0 and GetSystemTime() > tpChainTimer then
        mob:setLocalVar('[tpChain]count', 0)
        mob:setLocalVar('[tpChain]timer', 0)
    end
    
    -- Reaving Wind lock behavior: If using Reaving Wind and target is far away, continue using it
    -- This is handled by the mob skill selection logic and distance checks
    local distance = mob:checkDistance(target)
    local reavingWindActive = mob:getLocalVar('[reavingWind]active')
    
    if reavingWindActive == 1 and distance > 15 then
        -- Target is far away, continue using Reaving Wind
        -- This is handled by the mob skill system
    elseif reavingWindActive == 1 and distance <= 15 then
        -- Target is in range, can use other TP moves
        mob:setLocalVar('[reavingWind]active', 0)
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    local reavingWind = 2431
    local vermillionWind = 2642
    
    -- Track Reaving Wind usage
    if skillID == reavingWind then
        mob:setLocalVar('[reavingWind]active', 1)
        
        -- Check if target is far away - if so, will continue using Reaving Wind
        local distance = mob:checkDistance(target)
        if distance > 15 then
            -- Target is far, will continue using Reaving Wind
            mob:setTP(1000) -- Give TP to continue using it
        end
    end
    
    -- Handle back-to-back TP moves (especially Vermillion Wind 2x in a row)
    if mob:getTP() >= 1000 then
        local chainChance = 50 -- 50% chance to chain another TP move
        if math.random(100) <= chainChance then
            mob:setLocalVar('[tpChain]count', mob:getLocalVar('[tpChain]count') + 1)
            mob:setLocalVar('[tpChain]timer', GetSystemTime() + 3) -- 3 second window
            
            -- If Vermillion Wind was used, higher chance to use it again
            if skillID == vermillionWind then
                mob:setTP(1000) -- Give TP to use again
            end
        end
    end
end

entity.onMobMobskillChoose = function(mob, target)
    local reavingWind = 2431
    local reavingWindActive = mob:getLocalVar('[reavingWind]active')
    local distance = mob:checkDistance(target)
    
    -- If Reaving Wind is active and target is far away, force Reaving Wind
    if reavingWindActive == 1 and distance > 15 then
        return reavingWind
    end
    
    -- Otherwise, let the normal skill selection happen
    return 0
end

entity.onMobDisengage = function(mob)
    -- Reset tracking variables
    mob:setLocalVar('[tpChain]count', 0)
    mob:setLocalVar('[tpChain]timer', 0)
    mob:setLocalVar('[reavingWind]active', 0)
end

entity.onMobDeath = function(mob, player, optParams)
    player:addTitle(xi.title.AMHULUK_INUNDATER)
    
    -- Reset local variables
    mob:setLocalVar('[tpChain]count', 0)
    mob:setLocalVar('[tpChain]timer', 0)
    mob:setLocalVar('[reavingWind]active', 0)
end

return entity



