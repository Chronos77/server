-----------------------------------
-- Proboscis
-- Steals MP and dispels one beneficial status effect from targets in front.
-- Type: Magical
-- Utsusemi/Blink absorb: ignore shadow
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Calculate potential MP drain (can drain up to 1000+ MP)
    local maxDrain = math.floor(mob:getWeaponDmg() * 2.5) -- Base calculation, can be adjusted
    maxDrain = math.min(maxDrain, target:getMP()) -- Can't drain more than target has
    
    -- Dispel one beneficial status effect
    target:dispelStatusEffect()
    
    -- If target has no MP or is undead, deal no damage
    if target:isUndead() or maxDrain <= 0 then
        skill:setMsg(xi.msg.basic.SKILL_NO_EFFECT)
        return 0
    end
    
    -- Drain MP first, then use drained amount as damage
    local mpDrained = math.min(maxDrain, target:getMP())
    target:delMP(mpDrained)
    mob:addMP(mpDrained)
    
    -- Damage dealt is equal to MP drained
    local damage = mpDrained
    
    -- Apply magical adjustments (but damage is based on MP drained, not weapon damage)
    damage = xi.mobskills.mobFinalAdjustments(damage, mob, skill, target, xi.attackType.MAGICAL, xi.damageType.DARK, xi.mobskills.shadowBehavior.IGNORE_SHADOWS)
    
    skill:setMsg(xi.msg.basic.SKILL_DRAIN_MP)
    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.DARK)
    
    return damage
end

return mobskillObject
