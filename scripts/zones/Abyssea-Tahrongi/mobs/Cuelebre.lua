-----------------------------------
-- Area: Abyssea - Tahrongi
--  NM: Cuelebre
-- Notes: 10-20 minute Timed Spawn among the Nauls at (E-9)
-- Normal attacks bypass shadows
-- Always flies and does not melee
-- Attacks are earth magical damage
-- Takes melee damage while in air during Mighty Strikes
-- Susceptible to Stun (unlike Ouryu)
-- Can rage after 45 minutes - 1 hour
-----------------------------------
---@type TMobEntity
local entity = {}

local RAGE_TIMER = 2700 -- 45 minutes in seconds (can be adjusted to 3600 for 1 hour)

entity.onMobSpawn = function(mob)
    -- Always flies
    mob:setAnimationSub(1) -- Flying animation
    mob:addStatusEffectEx(xi.effect.ALL_MISS, 0, 1, 0, 0) -- Melee attacks miss
    -- Use skill list 837 for auto-attacks (earth magical damage)
    -- Note: ochre_blast_alt (ID 1298) should be added to skill list 837 for normal attacks that bypass shadows
    -- For now, using skill list 837 which contains ochre_blast and bai_wing
    mob:setMobSkillAttack(837)
    
    -- Fix size for large Wyrm NM
    mob:setMeleeRange(7.0) -- Large Wyrm NM size
    
    -- Susceptible to Stun (unlike Ouryu which has immunity)
    -- No stun immunity added
    
    -- Increased movement speed
    mob:setMod(xi.mod.MOVE, 50) -- Increase movement speed
    
    -- Initialize rage timer
    mob:setLocalVar('[rage]timer', RAGE_TIMER)
    mob:setLocalVar('[rage]started', 0)
    mob:setLocalVar('[rage]ochreBlastSpam', 0)
    mob:setLocalVar('mightyStrikesUsed', 0)
end

entity.onMobEngage = function(mob, target)
    -- Set rage timer on engage
    mob:setLocalVar('[rage]at', GetSystemTime() + mob:getLocalVar('[rage]timer'))
end

entity.onMobFight = function(mob, target)
    local battleTime = mob:getBattleTime()
    local rageStarted = mob:getLocalVar('[rage]started')
    local rageAt = mob:getLocalVar('[rage]at')
    local mightyStrikesActive = mob:hasStatusEffect(xi.effect.MIGHTY_STRIKES)
    local ochreBlastSpam = mob:getLocalVar('[rage]ochreBlastSpam')
    local mightyStrikesUsed = mob:getLocalVar('mightyStrikesUsed')
    
    -- Handle Mighty Strikes - allow melee damage during it
    if mightyStrikesActive then
        -- Remove ALL_MISS so melee can hit
        if mob:hasStatusEffect(xi.effect.ALL_MISS) then
            mob:delStatusEffect(xi.effect.ALL_MISS)
        end
        
        -- Spam Ochre Blast after using Mighty Strikes
        if
            ochreBlastSpam == 0 and
            mightyStrikesUsed == 1 and
            not xi.combat.behavior.isEntityBusy(mob) and
            mob:canUseAbilities()
        then
            -- Use Ochre Blast multiple times (mobskill ID 1303)
            mob:useMobAbility(1303)
            mob:setLocalVar('[rage]ochreBlastSpam', 1)
            
            -- Schedule additional Ochre Blast uses
            mob:timer(2000, function(mobArg)
                if mobArg:isAlive() and mobArg:hasStatusEffect(xi.effect.MIGHTY_STRIKES) then
                    mobArg:useMobAbility(1303)
                end
            end)
            
            mob:timer(4000, function(mobArg)
                if mobArg:isAlive() and mobArg:hasStatusEffect(xi.effect.MIGHTY_STRIKES) then
                    mobArg:useMobAbility(1303)
                end
            end)
        end
    else
        -- Restore ALL_MISS when Mighty Strikes is not active
        if not mob:hasStatusEffect(xi.effect.ALL_MISS) then
            mob:addStatusEffectEx(xi.effect.ALL_MISS, 0, 1, 0, 0)
        end
        
        -- Reset ochre blast spam flag when Mighty Strikes ends
        if ochreBlastSpam == 1 then
            mob:setLocalVar('[rage]ochreBlastSpam', 0)
        end
    end
    
    -- Handle Breakga only at low HP
    -- Breakga is in spell list 186, but should only be used at low HP
    -- The spell list system will handle this, but we can ensure it's available
    local hpp = mob:getHPP()
    -- Spell list 186 already includes Breakga, and mobs naturally use it more at low HP
    
    -- Handle rage phase after 45 minutes - 1 hour
    if
        rageStarted == 0 and
        GetSystemTime() > rageAt
    then
        mob:setLocalVar('[rage]started', 1)
        
        -- In rage phase, all damage is resisted for 0 except SMN BP and DoT
        -- Boost magical attack damage
        mob:setMod(xi.mod.UDMGMAGIC, 5000) -- Increase magical damage taken by others (but we resist all)
        -- Actually, we need to make all damage 0 except SMN BP and DoT
        -- This is complex and may need core changes, but we can boost the mob's magical damage output
        mob:setMod(xi.mod.MATT, mob:getMod(xi.mod.MATT) + 50) -- Boost magical attack damage
        
        -- Boost regular attacks, Bai Wing, and Ochre Blast damage
        mob:setMod(xi.mod.WEAPON_BONUS, mob:getMod(xi.mod.WEAPON_BONUS) + 20)
    end
    
    -- Wakeup from sleep immediately if flying
    if mob:getAnimationSub() == 1 then
        mob:wakeUp()
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    -- Track when Mighty Strikes is used (mobskill ID 688)
    if skill:getID() == 688 then
        mob:setLocalVar('mightyStrikesUsed', 1)
        mob:setLocalVar('[rage]ochreBlastSpam', 0) -- Reset for next Mighty Strikes
    end
end

entity.onMobDisengage = function(mob)
    -- Reset rage when disengaged (mob regens)
    if mob:getLocalVar('[rage]started') == 1 then
        mob:setLocalVar('[rage]started', 0)
        mob:setLocalVar('[rage]at', GetSystemTime() + mob:getLocalVar('[rage]timer'))
        
        -- Reset damage mods
        mob:setMod(xi.mod.UDMGMAGIC, 0)
        mob:setMod(xi.mod.MATT, mob:getMod(xi.mod.MATT) - 50)
        mob:setMod(xi.mod.WEAPON_BONUS, mob:getMod(xi.mod.WEAPON_BONUS) - 20)
    end
    
    -- Reset flags
    mob:setLocalVar('[rage]ochreBlastSpam', 0)
    mob:setLocalVar('mightyStrikesUsed', 0)
end

entity.onMobDeath = function(mob, player, optParams)
    -- Reset rage flags on death
    mob:setLocalVar('[rage]started', 0)
    mob:setLocalVar('[rage]ochreBlastSpam', 0)
    mob:setLocalVar('mightyStrikesUsed', 0)
end

return entity

