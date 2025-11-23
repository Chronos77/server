-----------------------------------
-- Area: Abyssea - Attohwa
--   NM: Itzpapalotl
-- Notes:
-- - Job: Black Mage
-- - Family: Wamoura
-- - Weak to: Water
-- - High Defense
-- - Resistant to HP-based moves (Spirits Within)
-- - Vulnerable to Gravity, Bind, and Stun
-- - Will eventually build resistance to Gravity
-- - Links with Gullycampa (Wamoura family, sublink 6)
-- - Has slight Regen (Status Effect)
-- - Gains Blaze Spikes while casting/using TP moves (50-200 damage depending on fire resistances)
-- - Casts Firaga IV
-- - Uses standard Wamoura TP move set
-- Abilities:
-- - Fire Break: ~2500 Fire damage. Reduced with Shell & Fire Resist
-- - Exuviation: Erases Debuffs and heals. Amount of HP recovered varies by amount of debuffs erased. If no Debuffs are Present Exuviation Heals 0 HP.
-- - Erratic Flutter: AoE Damage + Self Haste (like Hundred Fists)
-- - Magma Fan: AoE Cone Based Fire Damage (500-800 Damage)
-- - Erosion Dust: AoE 200-300 damage, Additional Effect Dia
-- - Proboscis: AoE Cone Based Attack that Drains MP. Damage Dealt is equal to MP Drained. If no MP is Drained Proboscis Deals no Damage. Can Drain up to 1000+ MP.
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    -- High Defense
    mob:setMod(xi.mod.DEF, mob:getMod(xi.mod.DEF) + 50) -- Adjust as needed
    
    -- Resistant to HP-based moves (Spirits Within)
    -- This is handled by the mob's resistance to percentage-based damage
    mob:setMod(xi.mod.UDMGPHYS, -100) -- Reduce percentage-based physical damage
    
    -- Vulnerable to Gravity, Bind, and Stun (no immunities set)
    -- Will eventually build resistance to Gravity (handled dynamically)
    
    -- Weak to Water elemental magic
    mob:setMod(xi.mod.WATER_MEVA, -25) -- Weakness to water
    
    -- Slight Regen (Status Effect)
    mob:addStatusEffect(xi.effect.REGEN, 5, 3, 0) -- 5 HP/tick, permanent
    
    -- Links with Gullycampa (Wamoura family, sublink 6)
    mob:setMobMod(xi.mobMod.SUBLINK, xi.mobSublink.WAMOURA_WAMOURACAMPA)
end

entity.onMobSpawn = function(mob)
    -- Initialize spell list (236 - Firaga IV)
    mob:setMobMod(xi.mobMod.SPELL_LIST, 236)
    
    -- Initialize skill list (864)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 864)
    
    -- Initialize tracking variables
    mob:setLocalVar('[gravityResist]count', 0)
    mob:setLocalVar('[blazeSpikes]active', 0)
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local battleTime = mob:getBattleTime()
    
    -- Build resistance to Gravity over time
    local gravityResistCount = mob:getLocalVar('[gravityResist]count')
    if gravityResistCount < 10 then
        -- Gradually increase resistance to Gravity
        local currentResist = mob:getMod(xi.mod.SLOWRES)
        if currentResist < 80 then
            mob:setMod(xi.mod.SLOWRES, currentResist + 1)
        end
    end
    
    -- Maintain slight Regen
    if not mob:hasStatusEffect(xi.effect.REGEN) then
        mob:addStatusEffect(xi.effect.REGEN, 5, 3, 0)
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    
    -- Gains Blaze Spikes while casting/using TP moves
    -- Blaze Spikes: 50-200 damage depending on fire resistances
    if not mob:hasStatusEffect(xi.effect.BLAZE_SPIKES) then
        local blazePower = math.random(50, 200)
        mob:addStatusEffect(xi.effect.BLAZE_SPIKES, blazePower, 0, 180) -- 3 minutes duration
        mob:setLocalVar('[blazeSpikes]active', 1)
    end
end

entity.onSpellPrecast = function(mob, spell)
    -- Gains Blaze Spikes while casting
    if not mob:hasStatusEffect(xi.effect.BLAZE_SPIKES) then
        local blazePower = math.random(50, 200)
        mob:addStatusEffect(xi.effect.BLAZE_SPIKES, blazePower, 0, 180) -- 3 minutes duration
        mob:setLocalVar('[blazeSpikes]active', 1)
    end
end

entity.onMobStatusEffectGain = function(mob, effect)
    -- Track Gravity applications to build resistance
    if effect:getType() == xi.effect.WEIGHT then
        local gravityResistCount = mob:getLocalVar('[gravityResist]count')
        mob:setLocalVar('[gravityResist]count', gravityResistCount + 1)
        
        -- Increase resistance slightly each time Gravity is applied
        local currentResist = mob:getMod(xi.mod.SLOWRES)
        if currentResist < 80 then
            mob:setMod(xi.mod.SLOWRES, currentResist + 5)
        end
    end
end

entity.onMobDeath = function(mob, player, optParams)
    player:addTitle(xi.title.ITZPAPALOTL_DECLAWER)
    
    -- Reset local variables
    mob:setLocalVar('[gravityResist]count', 0)
    mob:setLocalVar('[blazeSpikes]active', 0)
end

return entity

