local FARM_RADIUS = 30

local WATERINGCANS = {
    wateringcan = true,
    premiumwateringcan = true
}

local PONDS = {
    oasislake = true,
    pond = true,
    pond_mos = true,
    pond_cave = true
}

local WEEDS = {
    weed_forgetmelots = true,
    weed_tillweed = true,
    weed_firenettle = true,
    weed_ivy = true,
    farm_soil_debris = true,
}

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local FERTILIZE_THRESHOLD = 2 -- (值域0~4)

local FERTILIZERS = {
    growth = {},
    compost = {},
    manure = {},
    multi = {},
}

for prefab, data in pairs(FERTILIZER_DEFS) do

    local nutrients = data.nutrients

    if nutrients then
        local g = nutrients[1] or 0
        local c = nutrients[2] or 0
        local m = nutrients[3] or 0

        local count = 0
        if g > 0 then count = count + 1 end
        if c > 0 then count = count + 1 end
        if m > 0 then count = count + 1 end

        -------------------------------------------------
        -- 分类逻辑
        -------------------------------------------------
        if count >= 2 then
            -- 多属性
            FERTILIZERS.multi[prefab] = true

        else
            -- 单属性
            if g > 0 then
                FERTILIZERS.growth[prefab] = true
            elseif c > 0 then
                FERTILIZERS.compost[prefab] = true
            elseif m > 0 then
                FERTILIZERS.manure[prefab] = true
            end
        end
    end
end

-------------------------------------------------
-- 工具函数
-------------------------------------------------
local function GetEquippedItem(inst, equipslot)
    return inst.replica.inventory and inst.replica.inventory:GetEquippedItem(equipslot) or nil
end

local function FindFirstItem(inst, fn)
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

local function FindFirstItemInContainers(inst, fn)
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

local function GetItemPercentused(item)
    if item.replica and item.replica.inventoryitem then
        local classified = item.replica.inventoryitem.classified
        if classified and classified.percentused then
            return classified.percentused:value() / 100
        end
    end
    return 0
end

local function DebugPrint(...)
    print("[AutoFarm]", ...)
end

local function GetMoisture(soil)

    if soil == nil or soil.AnimState == nil then
        return 1
    end

    local wet = soil.AnimState:GetCurrentAnimationTime() or 1
    return math.max(0, math.min(1, wet))

end

local function GetNutrientLevels(soil)

    if soil == nil or soil.nutrientlevels == nil then
        return nil
    end

    local nutrientlevels = soil.nutrientlevels:value()

    return {
        growth = bit.band(nutrientlevels, 7),
        compost = bit.band(bit.rshift(nutrientlevels, 3), 7),
        manure = bit.band(bit.rshift(nutrientlevels, 6), 7)
    }

end

local function IsValid(ent)
    return ent and ent:IsValid() and not ent:HasTag("INLIMBO")
end

local function UnEquip(inst, equipslot)
    local item = GetEquippedItem(inst, equipslot)
    if item then
        SendRPCToServer(RPC.UseItemFromInvTile, ACTIONS.UNEQUIP.code, item)
    end
end
-------------------------------------------------
-- AutoFarm
-------------------------------------------------

local AutoFarm = Class(function(self, inst)

    self.inst = inst

    self.enabled = false

    self.state = nil
    self.target = nil

    self.state_cd = 0

    self.pos = nil

    self.task = nil
    self.icon_button = nil

    self.freq = 0.1

    self.mode_index = 1
    self.modes = {false,true}

    self.lang = "EN"
end)

-------------------------------------------------
-- 主循环
-------------------------------------------------

function AutoFarm:OnUpdate()

    if not self.enabled then
        self:Stop()
        return
    end

    self.pos = self.inst:GetPosition()

    if self.state_cd > 0 then
        self.state_cd = math.max(self.state_cd - self.freq, 0)
        return
    end

    -------------------------------------------------
    -- 执行当前目标
    -------------------------------------------------

    if self.target and IsValid(self.target) then

        self.inst.replica.inventory:ReturnActiveItem()

        if self.state == "PHONOGRAPH" then
            if self:DoPhonograph() then return end
        end

        if self.state == "WATER" then
            if self:DoWater() then return end
        end

        if self.state == "FERTILIZE" then
            if self:DoFertilize() then return end
        end

        if self.state == "WEED" then
            if self:DoWeed() then return end
        end

        if self.state == "TALK" then
            if self:DoTalk() then return end
        end

        if self.state == "FILL" then
            if self:DoFill() then return end
        end

        self.target = nil
        self.state = nil
    end

    -------------------------------------------------
    -- 搜索新任务
    -------------------------------------------------

    if self:FindPhonograph() then return end
    if self:FindSoil() then return end
    if self:FindWeed() then return end
    if self:FindPlant() then return end
    -- if self:FindFill() then return end

    self:SetStateCD(1)
end

-------------------------------------------------
-- 唱片机
-------------------------------------------------
function AutoFarm:FindPhonograph()
    local ents = TheSim:FindEntities(self.pos.x, 0, self.pos.z, FARM_RADIUS, {"recordplayer", "enabled"}, {"turnedon"})
    for _,phonograph in ipairs(ents) do
        local pos = phonograph:GetPosition()
        local plants = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.PHONOGRAPH_TEND_RANGE, {"tendable_farmplant"})
        if #plants > 0 then
            self.target = phonograph
            self:SetState("PHONOGRAPH")
            return true
        end
    end
    return false
end

function AutoFarm:DoPhonograph()
    if not self.target:HasTag("enabled") or self.target:HasTag("turnedon") then
        return false
    end

    UnEquip(self.inst, EQUIPSLOTS.HANDS)

    local pos = self.target:GetPosition()

    SendRPCToServer(RPC.RightClick, ACTIONS.TURNON.code, pos.x, pos.z, self.target)

    DebugPrint("On Task: Open Phonograph")
    self:SetStateCD(0.5)
    return true
end

-------------------------------------------------
-- 浇水/施肥
-------------------------------------------------

function AutoFarm:FindSoil()
    local soils = TheSim:FindEntities(self.pos.x, 0, self.pos.z, FARM_RADIUS, nil)
    for _,soil in ipairs(soils) do
        if soil.prefab == "nutrients_overlay" then
            local pos = soil:GetPosition()
            local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x, pos.y, pos.z)
            for i = 1, #ents do
                if ents[i]:HasTag("farm_plant") and not ents[i]:HasTag("pickable") and not ents[i]:HasTag("weed") then
                    if GetMoisture(soil) < 0.75 then
                        local hands = GetEquippedItem(self.inst, EQUIPSLOTS.HANDS)
                        if hands and hands:HasTag("wateringcan") and GetItemPercentused(hands) > 0.01 then
                            self.target = soil
                            self:SetState("WATER")
                            return true
                        end

                        local wateringcan = FindFirstItem(self.inst,function(item)
                            return item:HasTag("wateringcan") and GetItemPercentused(item) > 0.01
                        end)
                        if wateringcan then
                            SendRPCToServer(RPC.UseItemFromInvTile, ACTIONS.EQUIP.code, wateringcan)
                            self.target = soil
                            self:SetState("WATER")
                            self:SetStateCD(0.2)
                            return true
                        end
                    end

                    local nutrients = GetNutrientLevels(soil)
                    if nutrients then
                        for type,val in pairs(nutrients) do
                            if val < FERTILIZE_THRESHOLD then
                                local fert = FindFirstItem(self.inst,function(item)
                                    return FERTILIZERS[type][item.prefab]
                                end)

                                if fert then
                                    self.target = soil
                                    self:SetState("FERTILIZE")
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

function AutoFarm:DoWater()
    if GetMoisture(self.target) >= 0.75 then
        return false
    end

    local hands = GetEquippedItem(self.inst, EQUIPSLOTS.HANDS)
    if hands and hands:HasTag("wateringcan") and GetItemPercentused(hands) > 0.01 then
        local pos = self.target:GetPosition()
        SendRPCToServer(RPC.RightClick, ACTIONS.POUR_WATER_GROUNDTILE.code, pos.x, pos.z, nil, nil, true, nil)

        self:SetStateCD(1)

        DebugPrint("On Task: Watering Soil")
        return true
    end

    return false
end

function AutoFarm:DoFertilize()
    local nutrients = GetNutrientLevels(self.target)
    if not nutrients then
        return false
    end

    local g = nutrients.growth
    local c = nutrients.compost
    local m = nutrients.manure

    DebugPrint("nutrients:", g, c, m)

    -------------------------------------------------
    -- ✅ 优先：三项都低 → 用复合肥
    -------------------------------------------------
    if g < FERTILIZE_THRESHOLD and c < FERTILIZE_THRESHOLD and m < FERTILIZE_THRESHOLD then
        local fertilizer, cont, slot = FindFirstItemInContainers(self.inst, function(item)
            return FERTILIZERS["multi"][item.prefab]
        end)

        if cont and slot then
            if cont == self.inst.replica.inventory then
                SendRPCToServer(RPC.TakeActiveItemFromCountOfSlot, slot, nil, 1)
            else
                cont:TakeActiveItemFromCountOfSlot(slot, 1)
            end

            local pos = self.target:GetPosition()
            SendRPCToServer(RPC.LeftClick, ACTIONS.DEPLOY.code, pos.x, pos.z, nil, true, nil)

            DebugPrint("On Task: Fertilize Soil (Multi)")
            self:SetStateCD(0.3)
            return true
        end
        -- ⚠️ 如果没有复合肥，不return，继续走下面单项逻辑
    end

    -------------------------------------------------
    -- ✅ 单项补充（按缺的优先）
    -------------------------------------------------
    for type, val in pairs(nutrients) do
        if val < FERTILIZE_THRESHOLD then
            local fertilizer, cont, slot = FindFirstItemInContainers(self.inst, function(item)
                return FERTILIZERS[type][item.prefab]
            end)

            if cont and slot then
                if cont == self.inst.replica.inventory then
                    SendRPCToServer(RPC.TakeActiveItemFromCountOfSlot, slot, nil, 1)
                else
                    cont:TakeActiveItemFromCountOfSlot(slot, 1)
                end

                local pos = self.target:GetPosition()
                SendRPCToServer(RPC.LeftClick, ACTIONS.DEPLOY.code, pos.x, pos.z, nil, true, nil)

                DebugPrint("On Task: Fertilize Soil ("..type..")")
                self:SetStateCD(0.3)
                return true
            end
        end
    end

    return false
end

-------------------------------------------------
-- 杂草
-------------------------------------------------

function AutoFarm:FindWeed()

    local weeds = TheSim:FindEntities(self.pos.x, 0, self.pos.z, FARM_RADIUS, nil, {"NOCLICK", "DECOR", "INLIMBO"}, {"weed","farm_debris"})
    for _,weed in ipairs(weeds) do
        if WEEDS[weed.prefab] then
            local hands = GetEquippedItem(self.inst, EQUIPSLOTS.HANDS)
            if hands and hands:HasTag("DIG_tool") and GetItemPercentused(hands) > 0 then
                self.target = weed
                self:SetState("WEED")
                return true
            end

            local shovel = FindFirstItem(self.inst,function(item)
                return item:HasTag("DIG_tool") and GetItemPercentused(item) > 0
            end)
            if shovel then
                SendRPCToServer(RPC.UseItemFromInvTile, ACTIONS.EQUIP.code, shovel)
                self.target = weed
                self:SetState("WEED")
                self:SetStateCD(0.2)
                return true
            end
        end
    end

    return false
end

function AutoFarm:DoWeed()
    local shovel = FindFirstItem(self.inst,function(item)
        return item:HasTag("DIG_tool") and GetItemPercentused(item) > 0
    end)

    if not shovel then
        return false
    end

    local pos = self.target:GetPosition()

    SendRPCToServer(RPC.RightClick, ACTIONS.DIG.code, pos.x, pos.z, self.target)

    DebugPrint("On Task: Weeding")
    self:SetStateCD(0.4)
    return true

end

-------------------------------------------------
-- 植物对话
-------------------------------------------------

function AutoFarm:FindPlant()

    local plants = TheSim:FindEntities(self.pos.x,0,self.pos.z,FARM_RADIUS,{"tendable_farmplant"})

    if #plants > 0 then
        for i = 1, #plants do
            local plant = plants[i]
            local pos = plant:GetPosition()
            local phonographs = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.PHONOGRAPH_TEND_RANGE, {"recordplayer", "enabled"})
            if #phonographs == 0 then
                self.target = plant
                self:SetState("TALK")
                return true
            end
        end
    end
end

function AutoFarm:DoTalk()
    if not IsValid(self.target) or not self.target:HasTag("tendable_farmplant") then
        return false
    end

    UnEquip(self.inst, EQUIPSLOTS.HANDS)

    local pos = self.target:GetPosition()

    SendRPCToServer(RPC.LeftClick, ACTIONS.INTERACT_WITH.code, pos.x, pos.z, self.target, true, nil)

    DebugPrint("On Task: Talk To Farm Plant")
    self:SetStateCD(0.5)
    return true
end

-------------------------------------------------
-- 填水壶
-------------------------------------------------

function AutoFarm:FindFill()

    local can = FindFirstItem(self.inst,function(item)
        return WATERINGCANS[item.prefab]
        and (GetItemPercentused(item) or 1) < 0.95
    end)

    if not can then
        return
    end

    local ponds = TheSim:FindEntities(self.pos.x,0,self.pos.z,FARM_RADIUS,nil)

    for _,p in ipairs(ponds) do
        if PONDS[p.prefab] then
            self.target = p
            self.state = "FILL"
            return true
        end
    end
end

function AutoFarm:DoFill()

    local pos = self.target:GetPosition()

    SendRPCToServer(
        RPC.RightClick,
        ACTIONS.FILL.code,
        pos.x,
        pos.z,
        self.target
    )

    self:SetStateCD(0.8)
    return true

end

-------------------------------------------------
-- Start Stop
-------------------------------------------------

function AutoFarm:Start()

    self.enabled = true

    if self.task == nil then
        self.task = self.inst:DoPeriodicTask(self.freq,function()
            self:OnUpdate()
        end)
    end

    local text = self.lang == "ZH" and "自动种田: 开启" or "Auto farming: Enable"
    self.inst.components.talker:Say(text)
end

function AutoFarm:Stop()
    self.enabled = false

    if self.task then
        self.task:Cancel()
        self.task = nil
    end

    self.target = nil
    self.state = nil
    self.state_cd = 0

    local text = self.lang == "ZH" and "自动种田: 关闭" or "Auto farming: Disable"
    self.inst.components.talker:Say(text)
end
-------------------------------------------------
-- 工具
-------------------------------------------------
function AutoFarm:SetState(state)
    self.state = state
end

function AutoFarm:SetStateCD(time)
    self.state_cd = time
end

function AutoFarm:Switch()
    if self.enabled then
        self:Stop()
    else
        self:Start()
    end
end

function AutoFarm:SetLanguage(lang)
    self.lang = lang
end

return AutoFarm