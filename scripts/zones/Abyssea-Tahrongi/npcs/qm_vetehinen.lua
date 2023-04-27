-----------------------------------
-- Zone: Abyssea-Tahrongi
--  NPC: qm_vetehinen (???)
-- Spawns Vetehinen
-- !pos 76.4331 -0.5382 -435.0262 45
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_TAHRONGI]
-----------------------------------
local entity = {}

entity.onTrade = function(player, npc, trade)
    xi.abyssea.qmOnTrade(player, npc, trade, ID.mob.VETEHINEN, { xi.item.HIGH_QUALITY_LIMULE_PINCER })
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, 0, 0, { xi.item.HIGH_QUALITY_LIMULE_PINCER })
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
