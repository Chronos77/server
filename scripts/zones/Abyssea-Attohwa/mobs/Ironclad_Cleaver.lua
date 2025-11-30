-----------------------------------
-- Area: Abyssea - Attohwa
--   NM: Ironclad Cleaver
-- Notes:
-- - Family: Iron Giants
-- - Initially spawns as a pile of junk, but will aggro unwary passersby
-- - Cannot be targeted until it is active
-- - Susceptible to Lightning and Water damage
-- - Resistant to Bind, Gravity, Paralyze, and Slow
-- - High Magic Defense: Extreme resistance to elemental magic, except Lightning and Water
-- - Normal attacks are considered Job Abilities, and are cone AoE (approx. 300+ dmg)
--   Each attack will inflict either Knockback, Amnesia, or Stun
--   Absorbed by 1-4 shadows
--   Overhead slash attack inflicts Stun
--   Left to right slash attack causes Knockback
--   Stomp attack inflicts Amnesia
--   "!!" weaknesses cannot be triggered while the NM is executing these attacks
-- Abilities:
-- - Seismic Impact: AoE Earth damage + Slow + Terror effect
--   Slow overwrites and blocks Haste. Ignores but does not wipe shadows.
--   If executed, resets the hate of the player with hate a few seconds following this move.
--   This will occur even if the person with hate is not struck by this attack, as long as at least one other player was hit.
-- - Turbine Cyclone: AoE physical damage + dispels all buffs except Reraise, cruor buffs and atmas
--   Absorbed by 1-3 shadows
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    -- Susceptible to Lightning and Water damage
    mob:setMod(xi.mod.THUNDER_MEVA, -25)
    mob:setMod(xi.mod.WATER_MEVA, -25)
    
    -- Resistant to Bind, Gravity, Paralyze, and Slow
    mob:setMod(xi.mod.BINDRES, 100)
    mob:setMod(xi.mod.GRAVITYRES, 100)
    mob:setMod(xi.mod.PARALYZERES, 100)
    mob:setMod(xi.mod.SLOWRES, 100)
    
    -- High Magic Defense: Extreme resistance to elemental magic, except Lightning and Water
    mob:setMod(xi.mod.FIRE_MEVA, 50)
    mob:setMod(xi.mod.ICE_MEVA, 50)
    mob:setMod(xi.mod.WIND_MEVA, 50)
    mob:setMod(xi.mod.EARTH_MEVA, 50)
    mob:setMod(xi.mod.DARK_MEVA, 50)
    mob:setMod(xi.mod.LIGHT_MEVA, 50)
    
    -- Normal attacks are cone AoE (handled by skill list)
    -- Attacks absorbed by 1-4 shadows (configured in skill list 863)
end

entity.onMobSpawn = function(mob)
    -- Initialize skill list (863 - Ironclad Cleaver)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 863)
    
    -- Initially spawns as a pile of junk (cannot be targeted but can aggro)
    mob:setUntargetable(true)
    mob:setMobMod(xi.mobMod.NO_MOVE, 1)
    mob:setAggressive(true) -- Can aggro players even when untargetable
    
    -- Initialize tracking variables
    mob:setLocalVar('[seismicImpact]hateReset', 0)
    mob:setLocalVar('[active]', 0)
end

entity.onMobEngage = function(mob, target)
    -- Activate when engaged (becomes targetable and can move)
    if mob:getLocalVar('[active]') == 0 then
        mob:setUntargetable(false)
        mob:setMobMod(xi.mobMod.NO_MOVE, 0)
        mob:setLocalVar('[active]', 1)
    end
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local seismicHateReset = mob:getLocalVar('[seismicImpact]hateReset')
    
    -- Handle Seismic Impact hate reset (a few seconds after the move)
    if seismicHateReset > 0 and GetSystemTime() > seismicHateReset then
        local hateList = mob:getEnmityList()
        if #hateList > 0 then
            -- Reset hate of the player with highest hate
            local topHate = hateList[1]
            if topHate and topHate.entity and topHate.entity:isPC() then
                mob:resetEnmity(topHate.entity)
            end
        end
        mob:setLocalVar('[seismicImpact]hateReset', 0)
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    
    -- Seismic Impact: Sets up hate reset timer
    if skillID == 2620 then -- Seismic Impact
        -- Set timer to reset hate a few seconds after the move
        mob:setLocalVar('[seismicImpact]hateReset', GetSystemTime() + 3)
    end
    
    -- Normal attacks are cone AoE with different effects:
    -- Overhead slash: Stun
    -- Left to right slash: Knockback
    -- Stomp: Amnesia
    -- These are handled by the skill list and mob AI
end

entity.onMobDeath = function(mob, player, optParams)
    player:addTitle(xi.title.CLEAVER_DISMANTLER)
    
    -- Reset local variables
    mob:setLocalVar('[seismicImpact]hateReset', 0)
    mob:setLocalVar('[active]', 0)
end

return entity

