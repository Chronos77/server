-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm11 (???)
-- Spawns Tuskertrap
-- !pos -22 -23 656 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.TUSKERTRAP, { xi.ki.SAPPHIRE_ABYSSITE_OF_LENITY })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity
