-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm1 (???)
-- Spawns Minax Bugard
-- !pos 520 15 -268 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.MINAX_BUGARD, { xi.ki.BLOODSTAINED_BUGARD_FANG })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity
