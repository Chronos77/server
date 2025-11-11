-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm16 (???)
-- Spawns Karkadann
-- !pos -158 -32 118 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.KARKADANN, { xi.ki.ATMA_OF_THE_BLINDING_HORN })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity

