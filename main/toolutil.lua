local scrapbookdata = require("screens/redux/scrapbookdata")

local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

function DebugPrint(...)
    print("[TSLM]", ...)
end

function GetEquippedItem(inst, equipslot)
    return inst.replica.inventory and inst.replica.inventory:GetEquippedItem(equipslot) or nil
end

function GetAnimation(ent)
	if ent == nil then return end
	local a, anim, c, d, e, f = ent.AnimState:GetHistoryData()
	return tostring(anim)
end

function IsBusy(player)
	local busy_anims ={
		"atk",
		"hit",
		"run",
	}

	local anim = GetAnimation(player) or ""

	for _, v in ipairs(busy_anims) do
		if string.find(anim, v) then
			return true
		end
	end

    if anim == "build_loop" then
        return false
    end

	return (player.sg and player.sg:HasStateTag("moving")) or
		   (player:HasTag("moving") and not player:HasTag("idle")) or
		    player.components.playercontroller:IsDoingOrWorking()
end

function FindFirstItem(inst, fn)
    local function filter_fn(item)
        if fn then
            return fn(item)
        end
        return true
    end

    local invent = inst.replica.inventory

    -- Cheak Active Item
    local activeitem = invent:GetActiveItem()
    if activeitem and filter_fn(activeitem) then
        return activeitem
    end

    -- Check Inventory
    for _, item in pairs(invent:GetItems()) do
        if item and filter_fn(item) then
            return item
        end
    end

    -- Check Equips Containers
    local equips = invent:GetEquips()
    for _, equip in pairs(equips) do
        if filter_fn(equip) then
            return equip
        end

        local container = equip.replica.container
        if container then
            for i = 1, container:GetNumSlots() do
                local item = container:GetItemInSlot(i)
                if item and filter_fn(item) then
                    return item
                end
            end
        end
    end

    return nil
end

function FindFirstItemInContainers(inst, fn)
    local function filter_fn(item)
        if fn then
            return fn(item)
        end
        return true
    end

    local invent = inst.replica.inventory

    -- Check Inventory
    for slot = 1, invent:GetNumSlots() do
        local item = invent:GetItemInSlot(slot)
        if item and filter_fn(item) then
            return item, invent, slot
        end
    end

    -- Check Equips Containers
    local equips = invent:GetEquips()
    for _, equip in pairs(equips) do
        local container = equip.replica.container
        if container then
            for slot = 1, container:GetNumSlots() do
                local item = container:GetItemInSlot(slot)
                if item and filter_fn(item) then
                    return item, container, slot
                end
            end
        end
    end

    return nil, nil, nil
end

function PutAllOfActiveItemInCont(inst)
    if inst.replica.inventory then
        inst.replica.inventory:ReturnActiveItem()
    end
end

function GetItemPercentused(item)
    if item.replica and item.replica.inventoryitem then
        local classified = item.replica.inventoryitem.classified
        if classified and classified.percentused then
            return classified.percentused:value() / 100
        end
    end
    return 0
end