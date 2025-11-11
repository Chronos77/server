-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm14 (???)
-- Spawns Sedna
-- !pos 403 -31 390 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SEDNA, { xi.ki.ATMA_OF_THE_TUSKED_TERROR })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity

