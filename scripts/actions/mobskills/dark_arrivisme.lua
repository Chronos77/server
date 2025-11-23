-----------------------------------
-- Dark Arrivisme
-- Description: Mid AoE damage and knockback; Dispels some buffs (approx. 3); Gives Yaanei a strong intimidation effect for a short time.
-- Type: Magical
-- Utsusemi/Blink absorb: Wipes shadows
-- Range: AoE
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Calculate mid AoE damage
    local dmgmod = 1.0
    local baseDamage = mob:getMainLvl() * 12 + math.random(200, 350)
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.DARK, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.WIPE_SHADOWS)
    
    -- Dispels some buffs (approx. 3)
    for i = 1, 3 do
        target:dispelStatusEffect(xi.effectFlag.DISPELABLE)
    end
    
    -- Apply knockback (handled by skill flag in database)
    -- The skill has knockback flag set in mob_skills.sql
    
    -- Give Yaanei a strong intimidation effect for a short time
    -- Intimidation is typically represented by increased attack/accuracy
    if not mob:hasStatusEffect(xi.effect.INTIMIDATE) then
        mob:addStatusEffect(xi.effect.INTIMIDATE, 1, 0, 30) -- 30 seconds
        -- Also add attack bonus
        mob:addMod(xi.mod.ATT, 30)
        mob:addMod(xi.mod.ACC, 30)
        
        -- Remove the mods after the effect wears off
        mob:timer(30000, function(mobArg)
            if mobArg:isAlive() then
                mobArg:delMod(xi.mod.ATT, 30)
                mobArg:delMod(xi.mod.ACC, 30)
            end
        end)
    end
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    return damage
end

return mobskillObject

