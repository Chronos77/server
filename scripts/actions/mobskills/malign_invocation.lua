-----------------------------------
-- Malign Invocation
-- Description: Mid-high AoE damage with Additional Effect: Amnesia.
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
    -- Calculate mid-high AoE damage (element varies, using dark as default)
    local dmgmod = 1.0
    local baseDamage = mob:getMainLvl() * 15 + math.random(200, 400) -- Adjust formula as needed
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.DARK, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.IGNORE_SHADOWS)
    
    -- Apply Amnesia additional effect
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.AMNESIA, 1, 0, 60)
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    return damage
end

return mobskillObject

