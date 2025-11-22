-----------------------------------
-- Afflicting Gaze
-- Description: Gaze attack that inflicts Bind and Plague.
-- Type: Gaze
-- Utsusemi/Blink absorb: Ignores shadows
-- Range: Single gaze
-- Notes: Buff ~30 seconds, Bind and Plague
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Apply Bind first
    local bindEffect = xi.mobskills.mobGazeMove(mob, target, xi.effect.BIND, 1, 0, 30)
    
    -- Apply Plague
    local plagueEffect = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PLAGUE, 5, 3, 60)
    
    -- Set message based on what happened
    if bindEffect ~= xi.msg.basic.SKILL_NO_EFFECT then
        skill:setMsg(bindEffect)
    elseif plagueEffect ~= xi.msg.basic.SKILL_NO_EFFECT then
        skill:setMsg(plagueEffect)
    else
        skill:setMsg(xi.msg.basic.SKILL_NO_EFFECT)
    end
    
    return xi.effect.BIND
end

return mobskillObject

