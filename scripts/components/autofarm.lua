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
    self.cmp_name = "autofarm"

    self.enabled = false

    self.state = nil
    self.target = nil

    self.show_status = true
    self.height = 2.5

    self.state_cd = 0

    self.pos = nil

    self.task = nil
    self.icon_button = nil

    self.freq = 0.1

    self.mode_index = 1
    self.modes = {false,true}

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

    -- if not CanRunState(self.inst,"FARM") then
    --     return
    -- end

    if IsBusy(self.inst) then
        return
    end

    -------------------------------------------------
    -- 执行当前目标
    -------------------------------------------------

    if self.target and IsValid(self.target) then
        -- SetState(self.inst, "FARM")

        PutAllOfActiveItemInCont(self.inst)

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

    self:Wait(1)
    -- ClearState(self.inst, "FARM")
end

-------------------------------------------------
-- 唱片机
-------------------------------------------------
function AutoFarm:FindPhonograph()
    local ents = TheSim:FindEntities(self.pos.x, 0, self.pos.z, FARM_RADIUS, {"recordplayer", "enabled"}, {"turnedon"})
    for _,phonograph in ipairs(ents) do
        local pos = phonograph:GetPosition()
        local plants = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.PHONOGRAPH_TEND_RANGE, {"tendable_farmplant"}, {"weed"})
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
    self:Wait(0.5)
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
                    if GetMoisture(soil) < 0.5 then
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
                            self:Wait(0.2)
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

        self:Wait(1)

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
            self:Wait(0.3)
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
                self:Wait(0.3)
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
                self:Wait(0.2)
                return true
            end
        end
    end
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
    self:Wait(0.4)
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
    self:Wait(0.5)
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

    self:Wait(0.8)
    return true

end

-------------------------------------------------
-- Start Stop
-------------------------------------------------

function AutoFarm:Start()
    if not self.enabled then
        self:Stop()
        return
    end

    if self.task == nil then
        self.task = self.inst:DoPeriodicTask(self.freq,function()
            self:OnUpdate()
        end)
    end
end

function AutoFarm:Stop()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end

    self.target = nil
    self.state = nil
    self.state_cd = 0

    -- ClearState(self.inst,"FARM")
end

-------------------------------------------------
-- 模式
-------------------------------------------------

function AutoFarm:SetIconButton(button)
    self.icon_button = button
end

function AutoFarm:SetMode(index)
    self.mode_index = index
    local mode = self.modes[self.mode_index]
    if mode then
        self:Enable()
    else
        self:Disable()
    end

    -- SetComponentCache(self.cmp_name, {mode_index = self.mode_index})
end

function AutoFarm:SetNextMode()
    local next_index = self.mode_index + 1
    if next_index > #self.modes then
        next_index = 1
    end
    self:SetMode(next_index)
end

-------------------------------------------------
-- Enable Disable
-------------------------------------------------

function AutoFarm:Enable()
    self.enabled = true
    self:Start()
    self:UpdateButtonAppearance()

    -- 显示状态
    if self.inst.HUD and self.show_status then
        local tex = "nutrientsgoggleshat.tex"
        local atlas = resolvefilepath(GetInventoryItemAtlas(tex))
        self.inst.HUD:ShowStatusDisplayer(atlas, tex, STRINGS.AUTOFARM.FARMING, self.height or 2.5)
    else
        local current = self:IsEnabled()
        local text = current and STRINGS.AUTOFARM.ENABLED or STRINGS.AUTOFARM.DISABLED

        self.inst.components.talker:Say(STRINGS.AUTOFARM.MANE.. ": " .. text)
    end
end

function AutoFarm:Disable()
    self.enabled = false
    self:Stop()
    self:UpdateButtonAppearance()

    -- 隐藏状态
    if self.inst.HUD and self.show_status then
        self.inst.HUD:HideStatusDisplayer()
    else
        local current = self:IsEnabled()
        local text = current and STRINGS.AUTOFARM.ENABLED or STRINGS.AUTOFARM.DISABLED

        self.inst.components.talker:Say(STRINGS.AUTOFARM.MANE.. ": " .. text)
    end
end

function AutoFarm:IsEnabled()
    return self.enabled
end
function AutoFarm:SetShowStatus(bool)
    self.show_status = bool
end

function AutoFarm:SetStatusHeight(height)
    self.height = height
end

function AutoFarm:UpdateButtonAppearance()
    if not self.icon_button then
        return
    end

    if self.enabled then
        self.icon_button:SetTint(1, 1, 1, 1)
    else
        self.icon_button:SetTint(0,0,0,0.5)
    end
end

-------------------------------------------------
-- 工具
-------------------------------------------------
function AutoFarm:SetState(state)
    self.state = state
end

function AutoFarm:Wait(time)
    self.state_cd = time
end

return AutoFarm