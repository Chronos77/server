-----------------------------------
-- Besieger's Bane
-- Description: AoE damage with Additional Effects: Bio (15HP/tic), Terror (10-15sec), and Zombie.
-- Type: Magical
-- Utsusemi/Blink absorb: Wipes shadows
-- Range: AoE (bigger range than other abilities/spells)
-- Notes: Used under 25% HP only. Has a chance to fully reset enmity on affected players.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    -- Only usable under 25% HP
    if mob:getHPP() > 25 then
        return 1
    end
    
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Calculate AoE damage
    local dmgmod = 1.0
    local baseDamage = mob:getMainLvl() * 15 + math.random(200, 400)
    local damage = xi.mobskills.mobMagicalMove(mob, target, skill, baseDamage, xi.element.DARK, dmgmod, xi.mobskills.magicalTpBonus.NO_EFFECT, 1)
    
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.WIPE_SHADOWS)
    
    -- Apply Bio (15HP/tic)
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIO, 15, 3, 60)
    
    -- Apply Terror (10-15 seconds)
    local terrorDuration = math.random(10, 15)
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, terrorDuration)
    
    -- Apply Zombie (CURSE_II)
    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.CURSE_II, 1, 0, 300)
    
    -- Chance to fully reset enmity on affected players
    if math.random(100) <= 30 then -- 30% chance
        target:setCE(0)
        target:setVE(0)
    end
    
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    return damage
end

return mobskillObject

