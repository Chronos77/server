-----------------------------------
-- Area: Abyssea - Attohwa
--   NM: Yaanei
-- Notes:
-- - Job: Black Mage / Monk
-- - Family: Caturae
-- - Weak to: Wind, Fire
-- - Moves at 12% enhanced speed
-- - Possesses high defense
-- - Susceptible to Paralyze, but highly resistant
-- - Extremely resistant to Head Butt
-- - Possesses unusually wide aggro range
-- - Draw In: Used separately on each player on hate list, followed immediately by Besieger's Bane
--   Players standing more than 20 yalms away may not be drawn in
-- - Besieger's Bane: AoE Bio, Terror (10-15sec), and Zombie, used under 25% HP only
--   Will use Besieger's Bane back-to-back until it has affected every player with hate
--   Has a chance to fully reset enmity on affected players
--   Has bigger range than other abilities/spells
-- - Stygian Sphere: Cures itself for 1800-2000 HP and removes negative status effects
-- - Stygian Cyclone: Low AoE damage and Silence; ignores shadows
-- - Malign Invocation: Mid-high AoE damage and Amnesia
-- - Dark Arrivisme: Mid AoE damage and knockback; Dispels some buffs (approx. 3); Gives Yaanei strong intimidation effect
-- - Interference: AoE Dispels a large number of status effects; Either does very high damage or damage proportionate to buffs dispelled
-- - Deathly Diminuendo: AoE damage with Additional Effects: Curse and Bio (15HP/tic)
-- - Hellish Crescendo: AoE damage with Additional Effect: Paralysis
-- - Spell list 156: Stone V, Thunder V, Stonega IV, Thundaga IV, Break, Sleepga II, Slowga, Breakga
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    -- Enhanced movement speed (12%)
    mob:setMobMod(xi.mobMod.RUN_SPEED_MULT, 112)
    
    -- High defense
    mob:setMod(xi.mod.DEF, mob:getMod(xi.mod.DEF) + 50) -- Adjust as needed
    
    -- Susceptible to Paralyze, but highly resistant
    -- Set high resistance but not immunity
    mob:setMod(xi.mod.PARALYZERES, 80) -- High resistance, adjust as needed
    
    -- Extremely resistant to Head Butt (stun)
    mob:setMod(xi.mod.STUNRES, 95) -- Very high resistance to stun
    
    -- Wide aggro range
    mob:setMobMod(xi.mobMod.SIGHT_RANGE, 20) -- Adjust as needed for wide range
end

entity.onMobSpawn = function(mob)
    -- Initialize spell list (156)
    mob:setMobMod(xi.mobMod.SPELL_LIST, 156)
    
    -- Initialize skill list (882)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 882)
    
    -- Initialize tracking variables
    mob:setLocalVar('[stygianSphere]active', 0)
    mob:setLocalVar('[besiegerBane]used', 0)
    mob:setLocalVar('[besiegerBane]targets', 0)
    mob:setLocalVar('[drawIn]next', 0)
end

entity.onMobFight = function(mob, target)
    local hpp = mob:getHPP()
    local battleTime = mob:getBattleTime()
    
    -- Handle Draw In + Besieger's Bane combo under 25% HP
    if hpp < 25 then
        local drawInNext = mob:getLocalVar('[drawIn]next')
        local besiegerBaneUsed = mob:getLocalVar('[besiegerBane]used')
        
        -- Draw In each player on hate list, then use Besieger's Bane
        if drawInNext == 0 and besiegerBaneUsed == 0 then
            -- Get all players on hate list
            local hateList = mob:getEnmityList()
            local playersToDrawIn = {}
            
            for _, entityEntry in pairs(hateList) do
                local entity = entityEntry.entity
                if entity and entity:isPC() and entity:isAlive() then
                    local distance = mob:checkDistance(entity)
                    -- Only draw in players within 20 yalms
                    if distance <= 20 then
                        table.insert(playersToDrawIn, entity)
                    end
                end
            end
            
            -- Draw in each player, then use Besieger's Bane
            if #playersToDrawIn > 0 then
                mob:setLocalVar('[drawIn]next', GetSystemTime() + 1)
                mob:setLocalVar('[besiegerBane]targets', #playersToDrawIn)
                
                -- Draw in first player
                local firstPlayer = playersToDrawIn[1]
                if firstPlayer then
                    mob:drawIn(firstPlayer, 0, 0)
                end
                
                -- Schedule Besieger's Bane after draw in
                mob:timer(2000, function(mobArg)
                    if mobArg:isAlive() and mobArg:getHPP() < 25 then
                        mobArg:useMobAbility(2637) -- Besieger's Bane
                        mobArg:setLocalVar('[besiegerBane]used', 1)
                    end
                end)
            end
        end
        
        -- Continue using Besieger's Bane back-to-back until all players with hate are affected
        if besiegerBaneUsed == 1 then
            local besiegerBaneTargets = mob:getLocalVar('[besiegerBane]targets')
            if besiegerBaneTargets > 1 then
                -- Use Besieger's Bane again after a short delay
                mob:timer(3000, function(mobArg)
                    if mobArg:isAlive() and mobArg:getHPP() < 25 then
                        mobArg:useMobAbility(2637) -- Besieger's Bane
                        mobArg:setLocalVar('[besiegerBane]targets', besiegerBaneTargets - 1)
                        if besiegerBaneTargets - 1 <= 1 then
                            mobArg:setLocalVar('[besiegerBane]used', 0)
                            mobArg:setLocalVar('[drawIn]next', 0)
                        end
                    end
                end)
            else
                -- Reset for next cycle
                mob:setLocalVar('[besiegerBane]used', 0)
                mob:setLocalVar('[drawIn]next', 0)
            end
        end
    else
        -- Reset flags when HP is above 25%
        mob:setLocalVar('[besiegerBane]used', 0)
        mob:setLocalVar('[drawIn]next', 0)
        mob:setLocalVar('[besiegerBane]targets', 0)
    end
    
    -- Check if Stygian Sphere shield is active
    local stygianActive = mob:getLocalVar('[stygianSphere]active')
    if stygianActive == 1 then
        -- Shield is handled by the mob skill itself
    end
end

entity.onMobWeaponSkill = function(target, mob, skill)
    local skillID = skill:getID()
    
    -- Track Stygian Sphere usage
    if skillID == 2571 then -- Stygian Sphere
        mob:setLocalVar('[stygianSphere]active', 1)
    end
    
    -- Track Besieger's Bane usage
    if skillID == 2637 then -- Besieger's Bane
        -- Already handled in onMobFight
    end
end

entity.onMobMagicHit = function(mob, target, spell, damage)
    -- Check if magic damage should remove Stygian Sphere shield
    local stygianActive = mob:getLocalVar('[stygianSphere]active')
    if stygianActive == 1 and damage > 0 then
        -- Magic damage removes the shield
        if mob:hasStatusEffect(xi.effect.MAGIC_SHIELD) then
            mob:delStatusEffect(xi.effect.MAGIC_SHIELD)
            -- Remove the MATT bonus that was added by Stygian Sphere
            mob:delMod(xi.mod.MATT, 50)
            mob:setLocalVar('[stygianSphere]active', 0)
        end
    end
    
    return damage
end

entity.onMobDeath = function(mob, player, optParams)
    player:addTitle(xi.title.YAANEI_CRASHER)
    
    -- Reset local variables
    mob:setLocalVar('[stygianSphere]active', 0)
    mob:setLocalVar('[besiegerBane]used', 0)
    mob:setLocalVar('[besiegerBane]targets', 0)
    mob:setLocalVar('[drawIn]next', 0)
end

return entity

