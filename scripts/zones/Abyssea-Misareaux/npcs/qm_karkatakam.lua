-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm9 (???)
-- Spawns Karkatakam
-- !pos 200 -15 519 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.KARKATAKAM, { xi.ki.ATMA_OF_THE_CRADLE })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity
