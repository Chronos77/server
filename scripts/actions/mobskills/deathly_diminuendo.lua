-----------------------------------
-- Deathly Diminuendo
-- Description: AoE damage with Additional Effects: Bio and Curse.
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
    local baseDamage = mob:getMainLvl() * 12 + math.random(150, 300) -- Adjust formula as needed
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.DARK, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.IGNORE_SHADOWS)
    
    -- Apply Bio additional effect
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIO, 5, 3, 60)
    
    -- Apply Curse additional effect
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.CURSE_I, 25, 0, 300)
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    return damage
end

return mobskillObject

