-----------------------------------
-- Diabolic Claw
-- Description: High single-target damage 3-hit attack. Additional Effect: Magic Defense Down.
-- Type: Physical
-- Utsusemi/Blink absorb: 3 shadows
-- Range: Melee
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    local numhits = 3
    local accmod = 1.0
    local dmgmod = 2.0 -- High damage multiplier
    local ftp = 1.0
    
    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, numhits, accmod, dmgmod, xi.mobskills.physicalTpBonus.NO_EFFECT)
    local dmg = xi.mobskills.mobFinalAdjustments(info.dmg, mob, skill, target, xi.attackType.PHYSICAL, xi.damageType.SLASHING, xi.mobskills.shadowBehavior.NUMSHADOWS_3)
    
    -- Apply Magic Defense Down additional effect
    if dmg > 0 then
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MAGIC_DEF_DOWN, 20, 0, 60)
    end
    
    target:takeDamage(dmg, mob, xi.attackType.PHYSICAL, xi.damageType.SLASHING)
    
    return dmg
end

return mobskillObject

