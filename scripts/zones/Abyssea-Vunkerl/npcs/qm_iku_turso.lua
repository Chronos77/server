-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm3 (???)
-- Spawns Iku-Turso
-- !pos 244 -32 240 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IKU_TURSO, { xi.ki.GLOSSY_SEA_MONK_SUCKER })
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.abyssea.qmOnEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.abyssea.qmOnEventFinish(player, csid, option, npc)
end

return entity

