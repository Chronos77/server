-----------------------------------
-- Shadow Wreck
-- Description: High (1500-2700) AoE Dark damage.
-- Type: Magical (Dark)
-- Utsusemi/Blink absorb: Wipes shadows
-- Range: AoE
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Calculate damage: 1500-2700 base, scales with level
    local dmgmod = 1.0
    local baseDamage = math.random(1500, 2700)
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.DARK, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.WIPE_SHADOWS)
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    return damage
end

return mobskillObject

