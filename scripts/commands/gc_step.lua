-----------------------------------
-- func: gc_step
-- desc: Tell Lua to run a garbage collection step
-- note: For testing only (GM level 5)
-----------------------------------

cmdprops =
{
    permission = 4,
    parameters = ""
}

function onTrigger(player)
    GarbageCollectStep()
end
