-----------------------------------
-- Area: Abyssea Konschtat
--  Mob: Licorice
-- Note: PH for Guimauve
-----------------------------------
require("scripts/globals/zone")
require("scripts/globals/mobs")
-----------------------------------
local entity = {}

entity.onMobDeath = function(mob, player, isKiller)
    local ID = zones[xi.zone.ABYSSEA_KONSCHTAT]
    local rand = math.random(900, 1200)  -- 15-20 minutes
    xi.mob.phOnDespawn(mob, ID.mob.GUIMAUVE_PH, 100, rand)
end

entity.onMobDespawn = function(mob)
end

return entity
