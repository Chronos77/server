-----------------------------------
-- Area: Abyssea - Attohwa
--   NM: Ulhuadshi
-- Notes:
-- - Family: Sandworms
-- - Weak to: Wind
-- - Strong to: Earth
-- - Susceptible to Paralyze, Addle, Poison
-- - Paralyze II is very effective
-- - Vulnerable to Defense Down effects
-- - Temporarily absorbs all damage during and shortly after using TP moves (5-10 seconds)
--   Note: Unlike Glavoid, Ulhuadshi does NOT absorb magic damage while casting a spell
-- - Rages after 60 minutes - will absorb all forms of damage at this time
-- - Casts Slowga, Stonega IV, Stoneja
-- - Stonega IV and Stoneja can deal massive damage during Psyche Suction
-- Abilities:
-- - Dustvoid: AoE damage + Silence
-- - Slavernous Gale: AoE damage + Blind
-- - Aeolian Void: AoE damage + Dispel
-- - Desiccation: Resets all job ability timers (unless already on cooldown)
-- - Psyche Suction: Drains TP from players, mob gains TP and damage boost
-----------------------------------
---@type TMobEntity
local entity = {}

local RAGE_TIMER = 3600 -- 60 minutes in seconds

entity.onMobInitialize = function(mob)
    -- Weak to Wind
    mob:setMod(xi.mod.WIND_MEVA, -25)
    
    -- Strong to Earth
    mob:setMod(xi.mod.EARTH_MEVA, 25)
    
    -- Susceptible to Paralyze, Addle, Poison (no immunities set)
    -- Paralyze II is very effective (low resistance)
    mob:setMod(xi.mod.PARALYZERES, -20) -- Negative means more susceptible
    
    -- Vulnerable to Defense Down effects
    mob:setMod(xi.mod.DEFDOWNRES, -20)
end

entity.onMobSpawn = function(mob)
    -- Initialize spell list (229 - Slowga, Stonega IV, Stoneja)
    mob:setMobMod(xi.mobMod.SPELL_LIST, 229)
    
    -- Initialize skill list (878)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 878)
    
    -- Initialize tracking variables
    mob:setLocalVar('[rage]timer', RAGE_TIMER)
    mob:setLocalVar('[rage]started', 0)
    mob:setLocalVar('[tpAbsorb]active', 0)
    mob:setLocalVar('[tpAbsorb]endTime', 0)
end

entity.onMobEngage = function(mob, target)
    -- Set rage timer on engage
    mob:setLocalVar('[rage]at', GetSystemTime() + mob:getLocalVar('[rage]timer'))
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local battleTime = mob:getBattleTime()
    local rageStarted = mob:getLocalVar('[rage]started')
    local rageAt = mob:getLocalVar('[rage]at')
    local tpAbsorbActive = mob:getLocalVar('[tpAbsorb]active')
    local tpAbsorbEndTime = mob:getLocalVar('[tpAbsorb]endTime')
    
    -- Handle damage absorption during and after TP moves (5-10 seconds)
    if tpAbsorbActive == 1 then
        if GetSystemTime() < tpAbsorbEndTime then
            -- Still absorbing damage
            if not mob:hasStatusEffect(xi.effect.INVINCIBLE) then
                mob:addStatusEffect(xi.effect.INVINCIBLE, 1, 0, 0) -- Permanent until timer expires
            end
        else
            -- Timer expired, remove absorption
            if mob:hasStatusEffect(xi.effect.INVINCIBLE) then
                mob:delStatusEffect(xi.effect.INVINCIBLE)
            end
            mob:setLocalVar('[tpAbsorb]active', 0)
        end
    end
    
    -- Handle rage phase after 60 minutes
    if
        rageStarted == 0 and
        GetSystemTime() > rageAt
    then
        mob:setLocalVar('[rage]started', 1)
        
        -- In rage phase, absorb all forms of damage
        if not mob:hasStatusEffect(xi.effect.INVINCIBLE) then
            mob:addStatusEffect(xi.effect.INVINCIBLE, 1, 0, 0) -- Permanent until death/disengage
        end
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    
    -- Temporarily absorb all damage during and after TP moves (5-10 seconds)
    -- Note: Unlike Glavoid, Ulhuadshi does NOT absorb magic damage while casting
    local absorbDuration = math.random(5, 10) -- 5-10 seconds
    mob:setLocalVar('[tpAbsorb]active', 1)
    mob:setLocalVar('[tpAbsorb]endTime', GetSystemTime() + absorbDuration)
    
    -- Add invincible effect
    if not mob:hasStatusEffect(xi.effect.INVINCIBLE) then
        mob:addStatusEffect(xi.effect.INVINCIBLE, 1, 0, 0)
    end
end

entity.onMobDisengage = function(mob)
    -- Reset rage when disengaged
    if mob:getLocalVar('[rage]started') == 1 then
        mob:setLocalVar('[rage]started', 0)
        mob:setLocalVar('[rage]at', GetSystemTime() + mob:getLocalVar('[rage]timer'))
        
        -- Remove invincible if not in TP absorb phase
        if mob:getLocalVar('[tpAbsorb]active') == 0 then
            if mob:hasStatusEffect(xi.effect.INVINCIBLE) then
                mob:delStatusEffect(xi.effect.INVINCIBLE)
            end
        end
    end
    
    -- Reset TP absorb
    mob:setLocalVar('[tpAbsorb]active', 0)
    mob:setLocalVar('[tpAbsorb]endTime', 0)
end

entity.onMobDeath = function(mob, player, optParams)
    player:addTitle(xi.title.ULHUADSHI_DESICCATOR)
    
    -- Reset local variables
    mob:setLocalVar('[rage]started', 0)
    mob:setLocalVar('[tpAbsorb]active', 0)
    mob:setLocalVar('[tpAbsorb]endTime', 0)
end

return entity

