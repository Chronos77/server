-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm6 (???)
-- Spawns Upas-Kamuy
-- !pos -212 -184 449 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.UPAS_KAMUY, {})
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity

