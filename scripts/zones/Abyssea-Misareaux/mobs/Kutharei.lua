-----------------------------------
-- Area: Abyssea - Misareaux
--   NM: Kutharei
-- Notes:
-- - Family: Caturae
-- - Job: Red Mage / Black Mage
-- - Timepop: Spawns every 20-60 minutes at (G-11), behind Dilapidated Gate near Conflux #07
-- - Immune to Bind, Gravity, Sleep
-- - Susceptible to Paralyze and Slow
-- - Enhanced Movement Speed (approximately 25% faster)
-- - Heavily Resistant to Magical Damage
-- - Very resistant to Stun, but can land
-- - Paths Poorly even on Flat Terrain
-- Special Abilities:
-- - Stygian Sphere: Heals self for 1800-2000 HP
-- - Malign Invocation: Mid-high AoE damage and Amnesia
-- - Interference: AoE Dispels a large number of status effects; Either does very high damage or damage proportionate to buffs dispelled
-- - Banneret Charge: AoE attack that reduces HP to 1 and resets hate for all targets. Only used below 25%, can be used more than once. Stoneskin reduces damage. Max range ~20 yalms.
-- - Diabolic Claw: Single target 3-hit heavy physical damage absorbed by Utsusemi. Additional effect: Magic Defense Down
-- - Afflicting Gaze: Inflicts plague that reduces HP, MP, and TP (150 TP/tick) drastically over time
-- Spellcasting: Fire V, Firaga IV, Aero V, Aeroga IV, Silencega, Graviga, Addle, Dispelga
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    -- Set immunities
    mob:addImmunity(xi.immunity.BIND)
    mob:addImmunity(xi.immunity.GRAVITY)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    
    -- Susceptible to Paralyze and Slow (no immunities set for these)
    
    -- Very resistant to Stun, but can land (high resistance, not immunity)
    mob:setMod(xi.mod.STUNRES, 90) -- 90% resistance, adjust as needed
    
    -- Heavily Resistant to Magical Damage
    -- UDMGMAGIC: positive values reduce magical damage taken
    -- 5000 = 50% reduction, adjust as needed for "heavily resistant"
    mob:setMod(xi.mod.UDMGMAGIC, 5000)
    
    -- Enhanced Movement Speed (approximately 25% faster)
    mob:setMobMod(xi.mobMod.RUN_SPEED_MULT, 125) -- 125% = 25% faster
    
    -- Paths Poorly even on Flat Terrain
    -- This is typically handled by pathing AI, but we can set careful pathing to false
    mob:setMobMod(xi.mobMod.CAREFUL_PATHING, 0)
end

entity.onMobSpawn = function(mob)
    -- Initialize spell list (157: Fire V, Firaga IV, Aero V, Aeroga IV, Silencega, Graviga, Addle, Dispelga)
    mob:setMobMod(xi.mobMod.SPELL_LIST, 157)
    
    -- Initialize skill list (899: Diabolic Claw, Afflicting Gaze, Stygian Sphere, Malign Invocation, Banneret Charge, Interference)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 899)
    
    -- Initialize Banneret Charge tracking (only used below 25% HP, can be used multiple times)
    mob:setLocalVar('[banneretCharge]timer', 0)
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local banneretChargeTimer = mob:getLocalVar('[banneretCharge]timer')
    
    -- Banneret Charge can be used below 25% HP and can be used more than once
    -- Reset timer if HP goes above 25% or if timer has expired
    if hpp > 25 then
        mob:setLocalVar('[banneretCharge]timer', 0)
    elseif GetSystemTime() > banneretChargeTimer and banneretChargeTimer > 0 then
        -- Timer expired, reset to allow reuse
        mob:setLocalVar('[banneretCharge]timer', 0)
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    local banneretCharge = 2636
    
    -- Track Banneret Charge usage (can be used multiple times below 25% HP)
    if skillID == banneretCharge then
        -- Reset timer to allow multiple uses
        mob:setLocalVar('[banneretCharge]timer', GetSystemTime() + 30) -- 30 second cooldown between uses
    end
end

entity.onMobMobskillChoose = function(mob, target)
    local hpp = mob:getHPP()
    local banneretCharge = 2636
    local banneretChargeTimer = mob:getLocalVar('[banneretCharge]timer')
    
    -- Banneret Charge: Only used below 25% HP, can be used more than once
    -- Check if timer has expired to allow reuse
    if hpp <= 25 then
        if GetSystemTime() > banneretChargeTimer then
            -- Timer expired, can use again
            mob:setLocalVar('[banneretCharge]timer', 0)
        end
    end
    
    return 0
end

entity.onMobDisengage = function(mob)
    -- Reset tracking variables
    mob:setLocalVar('[banneretCharge]timer', 0)
end

entity.onMobDeath = function(mob, player, optParams)
    -- Grant title: Kutharei Unhorser
    player:addTitle(xi.title.KUTHAREI_UNHORSER)
    
    -- Give Abyssea drops
    xi.abyssea.giveNMDrops(mob, player, zones[xi.zone.ABYSSEA_MISAREAUX])
end

entity.onMobDespawn = function(mob)
    -- Timepop: respawns every 20-60 minutes
    xi.mob.updateNMSpawnPoint(mob)
    mob:setRespawnTime(math.random(1200, 3600)) -- 20 to 60 minutes
end

return entity



