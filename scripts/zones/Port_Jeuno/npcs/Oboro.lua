-----------------------------------
-- Area: Port Jeuno
--  NPC: Oboro
-- Ultimate Weapon Upgrade & Dynamis - Divergence Crafted Equipment NPC
-- !pos -180.000 11.000 86.000 246
-----------------------------------
local ID = zones[xi.zone.PORT_JEUNO]
-----------------------------------
---@type TNpcEntity
local entity = {}

-- Materials for upgrades
local PLUTON        = xi.item.PLUTON
local BEITETSU      = xi.item.BEITETSU
local RIFTBORN_BOULDER = xi.item.RIFTBORN_BOULDER

-- Required material count for Ultimate Weapon upgrades
local MATERIAL_COUNT_119 = 300
local MATERIAL_COUNT_DIVERGENCE = 150

entity.onTrigger = function(player, npc)
    -- Start the main menu event (397)
    -- Based on retail captures, event 397 is the initial menu
    player:startEvent(397)
end

entity.onEventUpdate = function(player, csid, option, npc)
    -- Event 397: Main menu - no updates needed
    -- Event 396: JSE Neck augmentation menu
    -- Event 440: JSE Neck augmentation selection
    -- Event 410-413: JSE Weapon upgrade with 300 materials
    -- Event 367-405: Empyrean weapon upgrade process
    if csid == 396 then
        -- JSE Neck augmentation menu
        -- Params: 1, 3, 6, 31 (based on captures)
        local mainWeapon = player:getEquip(xi.slot.MAIN)
        if mainWeapon then
            local weaponId = mainWeapon:getID()
            player:updateEvent(1, 3, 6, 31, 0, 0, 0, 0)
        else
            player:updateEvent(1, 3, 0, 13, 0, 0, 0, 0)
        end
    elseif csid == 440 then
        -- JSE Neck augmentation - event updates handled by client
        -- Params include item ID (25442, 25419 in captures)
    elseif csid >= 410 and csid <= 413 then
        -- JSE Weapon upgrade with 300 materials
        -- Event 410: Initial check (weapon ID in param 0)
        -- Event 411-413: Upgrade process
        local mainWeapon = player:getEquip(xi.slot.MAIN)
        if mainWeapon then
            local weaponId = mainWeapon:getID()
            if csid == 410 then
                player:updateEvent(weaponId, 0, 0, 0, 0, 0, 0, 0)
            end
        end
    elseif csid >= 367 and csid <= 405 then
        -- Empyrean weapon upgrade process
        -- Event 373: Trade confirmation (Pluton ID 4061, quantity 300)
        -- Event 380: Weapon check (Pluton ID, Weapon ID)
        -- Event 383: Upgrade completion (upgraded weapon ID)
        -- Event 405: Final confirmation
        local mainWeapon = player:getEquip(xi.slot.MAIN)
        if mainWeapon then
            local weaponId = mainWeapon:getID()
            if csid == 373 then
                -- Trade confirmation: Pluton (4061) x 300
                player:updateEvent(4061, 300, 0, 0, 0, 0, 0, 0)
            elseif csid == 380 then
                -- Weapon check
                player:updateEvent(4061, weaponId, 0, 0, 0, 0, 0, 0)
            elseif csid == 405 then
                -- Final confirmation with weapon and material info
                player:updateEvent(4061, 10, 9990, 0, 0, 0, 0, 20512)
            end
        end
    end
end

entity.onEventFinish = function(player, csid, option, npc)
    -- Handle event completion
    if csid == 397 then
        -- Main menu option selected
        -- Option 0: Close menu
        -- Option 10: Open JSE Neck augmentation menu (396)
        if option == 10 then
            player:startEvent(396)
        end
    elseif csid == 396 then
        -- JSE Neck augmentation menu
        -- Option 0: Cancel
        -- Option 11: Proceed to augmentation selection (440)
        if option == 11 then
            player:startEvent(440)
        end
    elseif csid == 440 then
        -- JSE Neck augmentation selection
        -- Option 1: Select augmentation
        -- Option 2: Confirm
        if option == 2 then
            -- Augmentation confirmed, process happens in onTrade
        end
    elseif csid == 410 then
        -- JSE Weapon upgrade initial check
        -- Option 1: Proceed with upgrade
        if option == 1 then
            player:startEvent(411)
        end
    elseif csid >= 411 and csid <= 413 then
        -- JSE Weapon upgrade process
        -- Option 0: Continue/Confirm
        if csid == 411 and option == 0 then
            player:startEvent(412)
        elseif csid == 412 and option == 0 then
            player:startEvent(413)
        elseif csid == 413 and option == 0 then
            -- Upgrade confirmed, process happens in onTrade
        end
    elseif csid >= 367 and csid <= 405 then
        -- Empyrean weapon upgrade process
        if csid == 367 and option == 1 then
            -- Start upgrade process
            player:startEvent(369)
        elseif csid == 369 and option == 2 then
            player:startEvent(370)
        elseif csid == 370 and option == 12 then
            player:startEvent(373)
        elseif csid == 373 and option == 5 then
            -- Trade confirmed, process happens in onTrade
        elseif csid == 380 and option == 0 then
            player:startEvent(383)
        elseif csid == 383 and option == 8 then
            player:startEvent(403)
        elseif csid == 403 and option == 0 then
            player:startEvent(404)
        elseif csid == 404 and option == 1 then
            player:startEvent(405)
        elseif csid == 405 and option == 0 then
            -- Upgrade confirmed, process happens in onTrade
        end
    end
end

entity.onTrade = function(player, npc, trade)
    local mainWeapon = player:getEquip(xi.slot.MAIN)
    
    if not mainWeapon then
        player:messageSpecial(ID.text.OBORO_CURIOUS_ORDNANCE, 0, 0, 0, 0, 0, 0, 0)
        return
    end
    
    local weaponId = mainWeapon:getID()
    local weaponInTrade = trade:getItem(0)
    
    -- Check if the equipped weapon is in the trade
    if not weaponInTrade or weaponInTrade:getID() ~= weaponId then
        player:messageSpecial(ID.text.OBORO_NO_AURA, 0, 0, 0, 0, 0, 0, 0)
        return
    end
    
    -- Check for Ultimate Weapon upgrades (REM/REME/REMEA)
    -- Trade: Weapon (equipped) + 300 materials (Pluton/Beitetsu/Riftborn Boulder)
    -- Based on captures: Event 373 shows Pluton (4061) x 300
    local plutonCount = trade:getItemQty(PLUTON)
    local beitetsuCount = trade:getItemQty(BEITETSU)
    local riftbornCount = trade:getItemQty(RIFTBORN_BOULDER)
    
    -- Check for 300 materials (Ultimate Weapon upgrade)
    -- This corresponds to Empyrean weapon upgrade (Lv99 -> 119 I)
    -- Trade must contain: Weapon (equipped) + exactly 300 materials
    if plutonCount >= MATERIAL_COUNT_119 then
        -- Relic weapon upgrade path (Pluton)
        -- Trade: Weapon + 300 Pluton
        if trade:hasItemQty(weaponId, 1) and 
           trade:hasItemQty(PLUTON, MATERIAL_COUNT_119) and
           trade:getItemCount() == 2 then
            -- Process upgrade
            -- In retail, weapon is taken and returned after 1 game day as upgraded version
            -- TODO: Implement actual weapon upgrade logic (Lv99 -> 119 I)
            player:messageSpecial(ID.text.OBORO_ONE_DAY, 0, 0, 0, 0, 0, 0, 0)
            trade:confirmItem(weaponId, 1)
            trade:confirmItem(PLUTON, MATERIAL_COUNT_119)
            player:tradeComplete()
            return
        end
    elseif beitetsuCount >= MATERIAL_COUNT_119 then
        -- Mythic weapon upgrade path (Beitetsu)
        if trade:hasItemQty(weaponId, 1) and 
           trade:hasItemQty(BEITETSU, MATERIAL_COUNT_119) and
           trade:getItemCount() == 2 then
            player:messageSpecial(ID.text.OBORO_ONE_DAY, 0, 0, 0, 0, 0, 0, 0)
            trade:confirmItem(weaponId, 1)
            trade:confirmItem(BEITETSU, MATERIAL_COUNT_119)
            player:tradeComplete()
            return
        end
    elseif riftbornCount >= MATERIAL_COUNT_119 then
        -- Empyrean weapon upgrade path (Riftborn Boulder)
        if trade:hasItemQty(weaponId, 1) and 
           trade:hasItemQty(RIFTBORN_BOULDER, MATERIAL_COUNT_119) and
           trade:getItemCount() == 2 then
            player:messageSpecial(ID.text.OBORO_ONE_DAY, 0, 0, 0, 0, 0, 0, 0)
            trade:confirmItem(weaponId, 1)
            trade:confirmItem(RIFTBORN_BOULDER, MATERIAL_COUNT_119)
            player:tradeComplete()
            return
        end
    end
    
    -- Check for JSE Weapon upgrade with 300 materials
    -- This is for upgrading JSE weapons (not Empyrean)
    -- Events 410-413 handle this process
    
    -- Check for Dynamis - Divergence crafted equipment upgrades
    -- Example: Aettir requires Cehuetzi Claw + Zweihander + Nagan + 150 materials
    -- This is a placeholder - specific weapon recipes would be implemented here
    
    -- Check for 150 materials (Dynamis - Divergence upgrade)
    if plutonCount >= MATERIAL_COUNT_DIVERGENCE or
       beitetsuCount >= MATERIAL_COUNT_DIVERGENCE or
       riftbornCount >= MATERIAL_COUNT_DIVERGENCE then
        -- Dynamis - Divergence upgrade path
        -- Specific weapon recipes would be checked here
        -- For now, this is a placeholder
    end
    
    -- Check for JSE Neck augmentation
    -- Events 396, 440 handle this process
    -- Trade would include the neck item + augmentation materials
    
    -- If no valid trade was found
    player:messageSpecial(ID.text.OBORO_NO_AURA, 0, 0, 0, 0, 0, 0, 0)
end

return entity

