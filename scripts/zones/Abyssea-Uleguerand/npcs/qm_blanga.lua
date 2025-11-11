-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm3 (???)
-- Spawns Blanga
-- !pos -615.221 -39.768 -16.079 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.BLANGA, { xi.ki.ATMA_OF_THE_STONE_GOD })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity

