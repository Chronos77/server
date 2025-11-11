-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm12 (???)
-- Spawns Npfundlwa
-- !pos 412 -7 50 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.NPFUNDLWA, { xi.ki.SAPPHIRE_ABYSSITE_OF_FORTUNE })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity
