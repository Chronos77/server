-----------------------------------
-- Stygian Sphere
-- Description: Heals itself for 1800-2000 HP and puts a magic shield up around him.
-- Type: Healing/Buff
-- Utsusemi/Blink absorb: N/A
-- Range: Self
-- Notes: The shield increases Magic Attack Bonus and grants Magic Shield. Only magic damage can remove it.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    -- Heal for 1800-2000 HP
    local healAmount = math.random(1800, 2000)
    mob:addHP(healAmount)
    skill:setMsg(xi.msg.basic.SELF_HEAL)
    
    -- Add Magic Shield effect (power 1 = 100% UDMGMAGIC reduction)
    -- This makes it so only magic damage can remove it
    mob:addStatusEffectEx(xi.effect.MAGIC_SHIELD, 1, 1, 0, 0)
    
    -- Increase Magic Attack Bonus (as per wiki notes)
    mob:addMod(xi.mod.MATT, 50) -- Adjust value as needed
    
    -- Track that Stygian Sphere is active (for removal on magic damage)
    mob:setLocalVar('[stygianSphere]active', 1)
    
    return healAmount
end

return mobskillObject

