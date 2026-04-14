local GetModConfigData = GetModConfigData

local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

function DebugPrint(...)
    if GetModConfigData("CFG_DEBUG_MODE") then
        print("[AUTOFARM]", ...)
    end
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

function FindItems(inst, fn)
    local function filter_fn(item)
        if fn then return fn(item) end
        return true
    end

    local items = {}
    local invent = inst.replica.inventory

    local activeitem = invent:GetActiveItem()
    if activeitem and filter_fn(activeitem) then
        table.insert(items, activeitem)
    end

    for _, item in pairs(invent:GetItems()) do
        if item and filter_fn(item) then
            table.insert(items, item)
        end
    end

    local equips = invent:GetEquips()
    for _, equip in pairs(equips) do
        if filter_fn(equip) then
            table.insert(items, equip)
        end
        local container = equip.replica.container
        if container then
            for i = 1, container:GetNumSlots() do
                local item = container:GetItemInSlot(i)
                if item and filter_fn(item) then
                    table.insert(items, item)
                end
            end
        end
    end

    return items
end

function GetStackSize(item)
    if item ~= nil and item.replica ~= nil and item.replica.stackable ~= nil then
        return item.replica.stackable:StackSize()
    end
    return 1
end

function GetMaxSize(item)
    if item ~= nil and item.replica ~= nil and item.replica.stackable ~= nil then
        return item.replica.stackable:MaxSize()
    end
    return 1
end

function GetAtlasAndTex(prefabname)
    local scrapbookdata = require("screens/redux/scrapbookdata")
    local data = scrapbookdata[prefabname]
    if data and data.tex then
        return resolvefilepath(data.atlas or GetInventoryItemAtlas(data.tex)), data.tex
    end
    local tex = prefabname .. ".tex"
    local atlas = GetInventoryItemAtlas(tex)
    if atlas ~= nil then
        return resolvefilepath(atlas), tex
    end
    return "images/lavaarena_unlocks.xml", "locked_creature_details.tex"
end

function GetWorldType()
    if TheWorld then
        if TheWorld:HasTag("forest") then
            return WORLDTYPE.FOREST
        elseif TheWorld:HasTag("cave") then
            return WORLDTYPE.CAVE
        elseif TheWorld:HasTag("island") then
            return WORLDTYPE.SHIPWRECKED
        elseif TheWorld:HasTag("volcano") then
            return WORLDTYPE.VOLCANOWORLD
        elseif TheWorld:HasTag("porkland") then
            return WORLDTYPE.PORKLAND
        end
        return WORLDTYPE.UNKNOWN
    end
end

-- no-op state coordination (no autostatemanager)
local function SetState(inst, state) end
local function ClearState(inst, state) end
local function CanRunState(inst, state) return true end