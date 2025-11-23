-----------------------------------
-- Slavernous Gale
-- Description: AoE damage with Additional Effect: Blind
-- Type: Magical
-- Utsusemi/Blink absorb: Ignores shadows
-- Range: AoE
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Calculate AoE damage
    local dmgmod = 1.0
    local baseDamage = mob:getMainLvl() * 12 + math.random(200, 350)
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.WIND, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.WIND, xi.mobskills.shadowBehavior.IGNORE_SHADOWS)
    
    -- Apply Blind additional effect
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BLINDNESS, 20, 0, 60)
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.WIND)
    
    return damage
end

return mobskillObject

