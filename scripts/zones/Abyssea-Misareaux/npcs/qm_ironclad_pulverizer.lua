-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm16 (???)
-- Spawns Ironclad Pulverizor
-- !pos -198 -31 160 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IRONCLAD_PULVERIZER, { xi.ki.ATMA_OF_THE_RAZED_RUINS })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity
