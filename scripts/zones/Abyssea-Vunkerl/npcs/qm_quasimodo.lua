-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm2 (???)
-- Spawns Quasimodo
-- !pos -278 -40 -367 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.QUASIMODO, { xi.ki.OSSIFIED_GARGOUILLE_HAND })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity

