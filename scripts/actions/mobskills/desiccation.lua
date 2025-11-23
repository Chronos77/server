-----------------------------------
-- Desiccation
-- Description: Resets all job ability timers (unless already on cooldown)
-- Type: Enfeebling
-- Utsusemi/Blink absorb: Wipes shadows
-- Range: AoE
-- Notes: If you have 40 seconds left on Counterstance recast and get hit with Desiccation, the recast timer will not be reset to the full 5 minutes.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(target, mob, skill)
    if target:isPC() then
        -- Reset all job ability timers
        -- Only reset if the ability is not already on cooldown (has time remaining)
        local jobAbilities = {
            xi.jobAbility.MIGHTY_STRIKES,
            xi.jobAbility.HUNDRED_FISTS,
            xi.jobAbility.BENEDICTION,
            xi.jobAbility.MANAFONT,
            xi.jobAbility.CHAINSPELL,
            xi.jobAbility.PERFECT_DODGE,
            xi.jobAbility.INVINCIBLE,
            xi.jobAbility.BLOOD_WEAPON,
            xi.jobAbility.FAMILIAR,
            xi.jobAbility.SOUL_VOICE,
            xi.jobAbility.EES_KINDRED,
            xi.jobAbility.MEIKYO_SHISUI,
            xi.jobAbility.MIJIN_GAKURE,
            xi.jobAbility.CALL_WYVERN,
            xi.jobAbility.ASTRAL_FLOW,
            xi.jobAbility.AZURE_LORE,
            xi.jobAbility.WILD_CARD,
            xi.jobAbility.OVERDRIVE,
            xi.jobAbility.TRANCE,
            xi.jobAbility.SEKKANOKI,
            xi.jobAbility.ELEMENTAL_SFORZO,
            xi.jobAbility.SUBLIMATION,
            xi.jobAbility.CONVERGENCE,
            xi.jobAbility.DIFFUSION,
            xi.jobAbility.ENMITY_DOWN,
            xi.jobAbility.ENMITY_UP,
            xi.jobAbility.STEAL,
            xi.jobAbility.MUG,
            xi.jobAbility.HIDE,
            xi.jobAbility.SNEAK_ATTACK,
            xi.jobAbility.TRICK_ATTACK,
            xi.jobAbility.ASSASSINS_CHARGE,
            xi.jobAbility.FEINT,
            xi.jobAbility.ACCOMPLICE,
            xi.jobAbility.COLLABORATOR,
            xi.jobAbility.AMBUSH,
            xi.jobAbility.DESPOIL,
            xi.jobAbility.CONSPIRATOR,
            xi.jobAbility.ABSORB_STR,
            xi.jobAbility.ABSORB_DEX,
            xi.jobAbility.ABSORB_VIT,
            xi.jobAbility.ABSORB_AGI,
            xi.jobAbility.ABSORB_INT,
            xi.jobAbility.ABSORB_MND,
            xi.jobAbility.ABSORB_CHR,
            xi.jobAbility.ABSORB_ACC,
            xi.jobAbility.ABSORB_ATT,
            xi.jobAbility.STEAL_TP,
            xi.jobAbility.ABSORB_TP,
            xi.jobAbility.MANAFONT,
            xi.jobAbility.CHAINSPELL,
            xi.jobAbility.ENMITY_DOWN,
            xi.jobAbility.ENMITY_UP,
            xi.jobAbility.STONESKIN,
            xi.jobAbility.BLINK,
            xi.jobAbility.Utsusemi_Ichi,
            xi.jobAbility.Utsusemi_Ni,
            xi.jobAbility.Utsusemi_San,
            xi.jobAbility.THIRD_EYE,
            xi.jobAbility.MEDITATE,
            xi.jobAbility.WARDING_CIRCLE,
            xi.jobAbility.SEKKANOKI,
            xi.jobAbility.HASSO,
            xi.jobAbility.INNIN,
            xi.jobAbility.CONCENTRATION,
            xi.jobAbility.PERFECT_COUNTER,
            xi.jobAbility.MANTRA,
            xi.jobAbility.FOCUS,
            xi.jobAbility.DODGE,
            xi.jobAbility.CHAKRA,
            xi.jobAbility.CONVERT,
            xi.jobAbility.COMPOSE,
            xi.jobAbility.SCHOLARS_ROLL,
            xi.jobAbility.CORSAIRS_ROLL,
            xi.jobAbility.DANCERS_ROLL,
            xi.jobAbility.MONKS_ROLL,
            xi.jobAbility.HUNTERS_ROLL,
            xi.jobAbility.SAMURAI_ROLL,
            xi.jobAbility.NINJA_ROLL,
            xi.jobAbility.DRACHEN_ROLL,
            xi.jobAbility.EVOKERS_ROLL,
            xi.jobAbility.MAGUSS_ROLL,
            xi.jobAbility.ALCHEMISTS_ROLL,
            xi.jobAbility.CASTERS_ROLL,
            xi.jobAbility.COURSERS_ROLL,
            xi.jobAbility.BLITZERS_ROLL,
            xi.jobAbility.TACTICIANS_ROLL,
            xi.jobAbility.ALLIES_ROLL,
            xi.jobAbility.MISERS_ROLL,
            xi.jobAbility.COMPANIONS_ROLL,
            xi.jobAbility.RUNEISTS_ROLL,
            xi.jobAbility.BOLTERS_ROLL,
            xi.jobAbility.CASTERS_ROLL,
            xi.jobAbility.COURSERS_ROLL,
            xi.jobAbility.BLITZERS_ROLL,
            xi.jobAbility.TACTICIANS_ROLL,
            xi.jobAbility.ALLIES_ROLL,
            xi.jobAbility.MISERS_ROLL,
            xi.jobAbility.COMPANIONS_ROLL,
            xi.jobAbility.RUNEISTS_ROLL,
            xi.jobAbility.BOLTERS_ROLL,
        }
        
        for _, abilityId in ipairs(jobAbilities) do
            local recast = target:getRecast(xi.recast.ABILITY, abilityId)
            -- Only reset if the ability is available (recast is 0 or very close to 0)
            -- If it has significant time remaining on cooldown, don't reset it
            -- Example: If you have 40 seconds left on Counterstance, it won't reset to full 5 minutes
            if recast == 0 or recast < 3 then
                target:resetRecast(xi.recast.ABILITY, abilityId)
            end
        end
    end
    
    skill:setMsg(xi.msg.basic.SKILL_NO_EFFECT)
    return 0
end

return mobskillObject

