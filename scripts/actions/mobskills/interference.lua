-----------------------------------
-- Interference
-- Description: AoE Dispels a large number of status effects; Either does very high damage or does damage proportionate to the number of buffs dispelled.
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
    -- Dispels a large number of status effects
    local dispelCount = target:dispelAllStatusEffect(xi.effectFlag.DISPELABLE)
    
    -- Either does very high damage or does damage proportionate to the number of buffs dispelled
    local dmgmod = 1.0
    local baseDamage
    
    if dispelCount > 0 then
        -- Damage proportionate to number of buffs dispelled
        baseDamage = mob:getMainLvl() * 10 + (dispelCount * 50) + math.random(100, 200)
    else
        -- Very high damage if no buffs to dispel
        baseDamage = mob:getMainLvl() * 20 + math.random(400, 600)
    end
    
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.DARK, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.WIPE_SHADOWS)
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    if dispelCount > 0 then
        skill:setMsg(xi.msg.basic.DISAPPEAR_NUM)
    end
    
    return damage
end

return mobskillObject

