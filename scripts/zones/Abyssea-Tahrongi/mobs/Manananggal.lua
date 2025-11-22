-----------------------------------
-- Area: Abyssea - Tahrongi
--   NM: Manananggal
-- Notes:
-- - Only aggros players with low HP
-- - Becomes invisible when no one on enmity list
-- - When knife is unsheathed: very high damage (2000-4000, crits up to 6000+), very slow attack speed (999 delay?), fast movement
-- - When weapon is sheathed: low delay, reduced damage
-- - Can Triple Attack
-- - Susceptible to Slow, Paralyze, Addle
-- - Immune to Bind and Gravity
-- - Uses Blood Weapon multiple times
-- - Can cast: Absorb-DEX, Absorb-VIT, Drain, Absorb-TP, Bio II, Blizzard II
-- - Uses: Animating Wail (AoE Haste), Fortifying Wail (AoE Protect), Hex Palm (cone drain, wipes shadows)
-----------------------------------
mixins = { require('scripts/mixins/families/qutrub') }
-----------------------------------
---@type TMobEntity
local entity = {}

-- Weapon state constants
local WEAPON_UNSHEATHED = 0  -- High damage, slow delay, fast movement
local WEAPON_SHEATHED = 1    -- Low damage, fast delay

-- Low HP threshold for aggro (percentage)
local LOW_HP_THRESHOLD = 50  -- Adjust as needed based on testing

-- Helper function to update weapon state (damage, delay, movement speed)
local function updateWeaponState(mob, state)
    if state == WEAPON_UNSHEATHED then
        -- Knife unsheathed: very high damage, very slow delay (999 delay), fast movement
        mob:setDelay(9990) -- 999 delay in centiseconds (999 * 10 = 9990)
        -- Store base damage to restore later
        local baseDamage = mob:getLocalVar('[weapon]baseDamage')
        if baseDamage == 0 then
            baseDamage = mob:getDamage() -- Get current damage as base
            mob:setLocalVar('[weapon]baseDamage', baseDamage)
        end
        mob:setDamage(baseDamage * 5) -- 5x damage multiplier (2000-4000 damage range)
        mob:setMod(xi.mod.RUN_SPEED_MULT, 150) -- Fast movement (150% = 1.5x speed)
    else
        -- Weapon sheathed: low delay, reduced damage
        mob:setDelay(2000) -- Fast delay (200 centiseconds = 2.0 seconds)
        local baseDamage = mob:getLocalVar('[weapon]baseDamage')
        if baseDamage == 0 then
            baseDamage = mob:getDamage()
            mob:setLocalVar('[weapon]baseDamage', baseDamage)
        end
        mob:setDamage(baseDamage) -- Normal damage
        mob:setMod(xi.mod.RUN_SPEED_MULT, 100) -- Normal movement speed
    end
end

entity.onMobInitialize = function(mob)
    -- Set immunities
    mob:addImmunity(xi.immunity.BIND)
    mob:addImmunity(xi.immunity.GRAVITY)
    
    -- Susceptible to Slow, Paralyze, Addle (no immunities set for these)
end

entity.onMobSpawn = function(mob)
    -- Start invisible
    mob:setStatus(xi.status.INVISIBLE)
    mob:hideName(true)
    mob:hideHP(true)
    mob:setUntargetable(true)
    
    -- Initialize weapon state (start with knife unsheathed)
    mob:setAnimationSub(WEAPON_UNSHEATHED)
    mob:setLocalVar('[weapon]state', WEAPON_UNSHEATHED)
    mob:setLocalVar('[weapon]baseDamage', 0) -- Will be set on first update
    
    -- Set initial weapon stats for unsheathed state
    -- Delay will be set after weapon is initialized by the system
    mob:timer(100, function(mobArg)
        updateWeaponState(mobArg, WEAPON_UNSHEATHED)
    end)
    
    -- Initialize Blood Weapon timer
    mob:setLocalVar('[bloodWeapon]timer', GetSystemTime() + 30) -- First use 30 seconds after spawn
    
    -- Triple Attack capability
    mob:setMod(xi.mod.TRIPLE_ATTACK, 5) -- 5% base chance, can be adjusted
end

entity.onMobEngage = function(mob, target)
    -- Check if target has low HP (only aggro low HP players)
    if target and target:isPC() then
        local targetHPP = target:getHPP()
        if targetHPP > LOW_HP_THRESHOLD then
            -- Player doesn't have low HP, disengage and become invisible again
            mob:disengage()
            mob:setStatus(xi.status.INVISIBLE)
            mob:hideName(true)
            mob:hideHP(true)
            mob:setUntargetable(true)
            return
        end
    end
    
    -- Become visible when engaging
    mob:setStatus(xi.status.NORMAL)
    mob:hideName(false)
    mob:hideHP(false)
    mob:setUntargetable(false)
    
    -- Set Blood Weapon timer on engage
    mob:setLocalVar('[bloodWeapon]timer', GetSystemTime() + 15) -- First use 15 seconds after engaging
end

entity.onMobFight = function(mob, target)
    local battleTime = mob:getBattleTime()
    local weaponState = mob:getLocalVar('[weapon]state')
    local bloodWeaponTimer = mob:getLocalVar('[bloodWeapon]timer')
    
    -- Handle Blood Weapon usage (multiple times)
    if GetSystemTime() > bloodWeaponTimer and not mob:hasStatusEffect(xi.effect.BLOOD_WEAPON) then
        if not xi.combat.behavior.isEntityBusy(mob) and mob:canUseAbilities() then
            mob:useMobAbility(xi.jsa.BLOOD_WEAPON)
            -- Next Blood Weapon in 40-60 seconds (randomized)
            mob:setLocalVar('[bloodWeapon]timer', GetSystemTime() + math.random(40, 60))
        end
    end
    
    -- Handle weapon state changes (can toggle between sheathed/unsheathed)
    -- This could be based on HP thresholds, time, or other conditions
    -- For now, we'll keep it simple and let it toggle occasionally
    if battleTime % 30 == 0 and math.random(1, 100) <= 10 then -- 10% chance every 30 seconds
        local newState = (weaponState == WEAPON_UNSHEATHED) and WEAPON_SHEATHED or WEAPON_UNSHEATHED
        mob:setAnimationSub(newState)
        mob:setLocalVar('[weapon]state', newState)
        updateWeaponState(mob, newState)
    end
end

entity.onMobDisengage = function(mob)
    -- Become invisible again if no one on enmity list
    local enmityList = mob:getEnmityList()
    if #enmityList == 0 then
        mob:setStatus(xi.status.INVISIBLE)
        mob:hideName(true)
        mob:hideHP(true)
        mob:setUntargetable(true)
    end
    
    -- Reset weapon state to unsheathed
    mob:setAnimationSub(WEAPON_UNSHEATHED)
    mob:setLocalVar('[weapon]state', WEAPON_UNSHEATHED)
    updateWeaponState(mob, WEAPON_UNSHEATHED)
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    
    -- Hex Palm can only be used when weapon is sheathed (animationSub 1 or 3)
    -- This is handled in the mobskill check, but we can ensure state here if needed
end

entity.onMobDeath = function(mob, player, optParams)
    -- Reset any local variables if needed
    mob:setLocalVar('[weapon]state', 0)
    mob:setLocalVar('[bloodWeapon]timer', 0)
end

return entity
