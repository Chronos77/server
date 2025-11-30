-----------------------------------
-- Area: Abyssea - Tahrongi
--   NM: Iratham
-- Notes:
-- - Immune to Bind, Gravity, Sleep
-- - Susceptible to Paralyze, Slow, Addle
-- - Enhanced movement speed (+25% approx)
-- - Double Attack
-- - Appears to gain a high degree of Store TP as HP declines
-- - At lower HP, uses 2 or more abilities back-to-back
-- - Spell list changes based on HP:
--   * 50-100%: Fire-based spells (Flare, Firaga III, Firaga IV, Sleepga II)
--   * Under 50%: Ice-based spells (Freeze II, Blizzaga IV, Sleepga II)
--   * Under 20%: Ice-based spells + Comet (Freeze II, Blizzaga IV, Comet, Sleepga II)
-- - Stygian Sphere: Heals 1800-2000 HP and grants Magic Shield (only magic damage can remove it)
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    -- Set immunities
    mob:addImmunity(xi.immunity.BIND)
    mob:addImmunity(xi.immunity.GRAVITY)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    
    -- Susceptible to Paralyze, Slow, Addle (no immunities set for these)
    
    -- Enhanced movement speed (+25%)
    mob:setMobMod(xi.mobMod.RUN_SPEED_MULT, 125)
    
    -- Double Attack
    mob:setMod(xi.mod.DOUBLE_ATTACK, 10) -- 10% base chance, adjust as needed
end

entity.onMobSpawn = function(mob)
    -- Initialize spell list (50-100% HP: fire-based)
    mob:setMobMod(xi.mobMod.SPELL_LIST, 153)
    
    -- Initialize Stygian Sphere tracking
    mob:setLocalVar('[stygianSphere]active', 0)
    
    -- Initialize ability chain tracking for low HP behavior
    mob:setLocalVar('[abilityChain]count', 0)
    mob:setLocalVar('[abilityChain]timer', 0)
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local battleTime = mob:getBattleTime()
    
    -- Spell list management based on HP
    if hpp < 20 then
        mob:setMobMod(xi.mobMod.SPELL_LIST, 155) -- Under 20%: Ice + Comet
    elseif hpp < 50 then
        mob:setMobMod(xi.mobMod.SPELL_LIST, 154) -- Under 50%: Ice-based only
    else
        mob:setMobMod(xi.mobMod.SPELL_LIST, 153) -- 50-100%: Fire-based
    end
    
    -- Store TP increases as HP declines
    -- At 100% HP: normal Store TP
    -- At 50% HP: +50 Store TP
    -- At 0% HP: +100 Store TP (linear scaling)
    local storeTPBonus = math.floor((100 - hpp) * 1.0) -- 1 Store TP per 1% HP lost
    mob:setMod(xi.mod.STORETP, storeTPBonus)
    
    -- At lower HP, uses 2 or more abilities back-to-back
    -- This is handled by the mob skill system, but we can track it here
    if hpp < 30 then
        local abilityChainCount = mob:getLocalVar('[abilityChain]count')
        local abilityChainTimer = mob:getLocalVar('[abilityChain]timer')
        
        -- After using an ability, set a flag to use another one quickly
        if abilityChainTimer > 0 and GetSystemTime() > abilityChainTimer then
            mob:setLocalVar('[abilityChain]count', 0)
            mob:setLocalVar('[abilityChain]timer', 0)
        end
    end
    
    -- Check if Stygian Sphere shield is active and should be removed by magic damage
    -- This is handled in the mob skill, but we track it here
    local stygianActive = mob:getLocalVar('[stygianSphere]active')
    if stygianActive == 1 then
        -- The shield should only be removed by magic damage
        -- This is handled by the Magic Shield effect itself
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    local hpp = mob:getHPP()
    
    -- Track Stygian Sphere usage
    if skillID == 2571 then -- Stygian Sphere
        mob:setLocalVar('[stygianSphere]active', 1)
        -- The skill itself handles the heal and shield
    end
    
    -- At lower HP, chain abilities together
    if hpp < 30 then
        local chainCount = mob:getLocalVar('[abilityChain]count')
        if chainCount < 2 then
            -- Queue another ability use soon
            mob:setLocalVar('[abilityChain]count', chainCount + 1)
            mob:setLocalVar('[abilityChain]timer', GetSystemTime() + 3) -- 3 seconds between chained abilities
        end
    end
end

entity.onMobMagicHit = function(mob, target, spell, damage)
    -- Check if magic damage should remove Stygian Sphere shield
    -- According to wiki: "Only magic damage can remove it"
    local stygianActive = mob:getLocalVar('[stygianSphere]active')
    if stygianActive == 1 and damage > 0 then
        -- Magic damage removes the shield
        if mob:hasStatusEffect(xi.effect.MAGIC_SHIELD) then
            mob:delStatusEffect(xi.effect.MAGIC_SHIELD)
            -- Remove the MATT bonus that was added by Stygian Sphere
            local currentMATT = mob:getMod(xi.mod.MATT)
            mob:delMod(xi.mod.MATT, 50)
            mob:setLocalVar('[stygianSphere]active', 0)
        end
    end
    
    return damage
end

entity.onMobDeath = function(mob, player, optParams)
    player:addTitle(xi.title.IRATHAM_CAPTURER)
    
    -- Reset local variables
    mob:setLocalVar('[stygianSphere]active', 0)
    mob:setLocalVar('[abilityChain]count', 0)
    mob:setLocalVar('[abilityChain]timer', 0)
end

return entity
