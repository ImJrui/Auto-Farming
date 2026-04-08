local plant_planner = require("plant_planner")
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local MAX_STUCK_ATTEMPTS = 5

-- Geometric Placement mod ID (workshop)
local GEOMETRY_MOD_ID = "workshop-351325790"

-- 检测 Geometric Placement 是否开启（mod 启用 + Ctrl 状态符合）
-- 逻辑与 Geometric Placement 源码一致：
--   CTRL=false（默认）：按住 Ctrl 时 mod 生效
--   CTRL=true：按住 Ctrl 时 mod 关闭
local function IsGeometryEnabled()
    if not KnownModIndex:IsModEnabled(GEOMETRY_MOD_ID) then
        return false
    end
    local ctrl_data = GetModConfigData("CTRL", GEOMETRY_MOD_ID)
    local ctrl = (ctrl_data == true)
    return ctrl == TheInput:IsKeyDown(KEY_CTRL)
end

-- 局部 SendRightClick：临时翻转 Ctrl 状态，
-- 使 Geometric Placement 的 hook 认为 mod 关闭，从而不吸附坐标
local function SendRightClick(code, action_code, x, z, ...)
    if IsGeometryEnabled() then
        local old_IsKeyDown = TheInput.IsKeyDown
        TheInput.IsKeyDown = function(self, key)
            if key == KEY_CTRL then
                return not old_IsKeyDown(self, key)
            end
            return old_IsKeyDown(self, key)
        end
        SendRPCToServer(code, action_code, x, z, ...)
        TheInput.IsKeyDown = old_IsKeyDown
    else
        SendRPCToServer(code, action_code, x, z, nil, nil, true)
    end
end

local seasons_type = {
    dst = {"autumn", "winter", "spring", "summer"},
    sw = {"mild", "wet", "green", "dry"},
    ham = {"temperate", "humid", "lush"},
}

local function IsFarmHoe(item)
    return item.prefab == "farm_hoe" or item.prefab == "golden_farm_hoe" or item.prefab == "shovel_lunarplant"
end

local function CanTillSoilAtPoint(pos)
    return TheWorld.Map:CanTillSoilAtPoint(pos.x, pos.y, pos.z)
end

local function GetSoilAtPoint(pos)
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 0.1, {"soil"}, {"NOCLICK"})
    for i = 1, #ents do
        local ent = ents[i]
        if ent:IsValid() and ent.prefab == "farm_soil" then
            return ent
        end
    end
    return nil
end

local function IsPositionPlanted(pos)
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 0.1, {"farm_plant"}, {"weed"})
    return #ents > 0
end

local function IsCurrentAnimationIn(inst, anims)
    for i = 1, #anims do
        local anim = anims[i]
        if inst.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end
    return false
end

local function IsPlanting(inst)
    local active_item = inst.replica.inventory:GetActiveItem()
    return active_item and string.find(active_item.prefab, "_seeds")
        and IsCurrentAnimationIn(inst, {"build_pre", "build_loop", "build_pst"})
end

local AutoPlant = Class(function(self, inst)
    self.inst = inst
    self.enabled = false
    self.state = nil
    self.target = nil
    self.target_index = 1
    self.targets = {}
    self.state_cd = 0
    self.pos = nil
    self.task = nil
    self.icon_button = nil
    self.freq = 0.1
    self.height = 2.5
    self.show_status = true
    self.stuck_attempts = MAX_STUCK_ATTEMPTS
end)

function AutoPlant:OnUpdate()
    if not self.enabled then
        self:Stop()
        return
    end

    if self.state_cd > 0 then
        self.state_cd = math.max(self.state_cd - self.freq, 0)
        return
    end

    if IsBusy(self.inst) or IsPlanting(self.inst) then
        return
    end

    if #self.targets == 0 then
        self:Disable()
        return
    end

    if not self.target then
        self.target = self.targets[self.target_index]
        if not self.target then
            self:ResetPlantingPlan()
            return
        end
    end

    if self.target.planted then
        self:SetNextTarget()
        return
    end

    PutAllOfActiveItemInCont(self.inst)

    local pos = self.target.pos

    if IsPositionPlanted(pos) then
        if self:OnPositionPlanted() then return end
    end

    if self.inst:HasTag("plantkin") then
        if self:DoGroundPlanting() then return end
    end

    local soil = GetSoilAtPoint(pos)
    if soil then
        if self:DoPlanting(soil) then return end
    end

    if CanTillSoilAtPoint(pos) and not self.inst:HasTag("plantkin") then
        if self:DoTill() then return end
    end

    self:SetNextTarget()
end

function AutoPlant:OnPositionPlanted()
    self.targets[self.target_index].planted = true
    self.stuck_attempts = MAX_STUCK_ATTEMPTS
    return true
end

function AutoPlant:DoGroundPlanting()
    if not CanTillSoilAtPoint(self.target.pos) then
        return false
    end

    local plant_def = self.target and PLANT_DEFS[self.target.plant]
    if not plant_def then
        return false
    end

    local seed, cont, slot = FindFirstItemInContainers(self.inst, function(item)
        return item.prefab == PLANT_DEFS[self.target.plant].seed
    end)

    if cont and slot then
        if cont == self.inst.replica.inventory then
            SendRPCToServer(RPC.TakeActiveItemFromCountOfSlot, slot, nil, 1)
        else
            cont:TakeActiveItemFromCountOfSlot(slot, 1)
        end

        local pos = self.target.pos
        SendRightClick(RPC.RightClick, ACTIONS.DEPLOY.code, pos.x, pos.z, nil, nil, true)

        DebugPrint("On Task: Plant " .. tostring(self.target.plant))
        self.stuck_attempts = MAX_STUCK_ATTEMPTS
        self:SetStateCD(0.3)
        return true
    end

    return false
end

function AutoPlant:DoPlanting(soil)
    if not soil or not soil:IsValid() or soil:HasTag("NOCLICK") then
        return false
    end

    local plant_def = self.target and PLANT_DEFS[self.target.plant]
    if not plant_def then
        return false
    end

    local seed = FindFirstItem(self.inst, function(item)
        return item.prefab == PLANT_DEFS[self.target.plant].seed
    end)

    if seed then
        SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, ACTIONS.PLANTSOIL.code, seed, soil, nil)
        DebugPrint("On Task: Plant " .. tostring(self.target.plant))
        self.stuck_attempts = MAX_STUCK_ATTEMPTS
        self:SetStateCD(0.3)
        return true
    end

    return false
end

function AutoPlant:DoTill()
    local pos = self.target.pos
    if GetSoilAtPoint(pos) then
        return false
    end

    local hands = GetEquippedItem(self.inst, EQUIPSLOTS.HANDS)
    if hands and IsFarmHoe(hands) and GetItemPercentused(hands) > 0 then
        SendRightClick(RPC.RightClick, ACTIONS.TILL.code, pos.x, pos.z, nil, nil, true)
        self.stuck_attempts = MAX_STUCK_ATTEMPTS
        self:SetStateCD(0.5)
        DebugPrint("锄地")
        return true
    end

    local farmhoe = FindFirstItem(self.inst, function(item)
        return IsFarmHoe(item)
    end)
    if farmhoe then
        SendRPCToServer(RPC.UseItemFromInvTile, ACTIONS.EQUIP.code, farmhoe)
        DebugPrint("装备锄头")
    end

    return false
end

function AutoPlant:SetNextTarget()
    local next_index = self.target_index + 1
    if next_index > #self.targets then
        self.target_index = 1
        self.stuck_attempts = self.stuck_attempts - 1
        self:SetStateCD(1)
        if self.stuck_attempts <= 0 then
            DebugPrint("AutoPlant: No valid target for " .. MAX_STUCK_ATTEMPTS .. " attempts, stopping.")
            self:ResetPlantingPlan()
            self:Disable()
            if self.inst.components.autofarm then
                self.inst.components.autofarm:Enable()
            end
            return
        end
        self:CheckTargets()
    else
        self.target_index = next_index
    end
    self.target = self.targets[self.target_index]
end

function AutoPlant:CheckTargets()
    for i = 1, #self.targets do
        local target = self.targets[i]
        if not target.planted then
            return
        end
    end
    -- All planted → switch to autofarm
    self:ResetPlantingPlan()
    self:Disable()
    if self.inst.components.autofarm then
        self.inst.components.autofarm:Enable()
    end
end

function AutoPlant:SetStateCD(time)
    self.state_cd = time
end

function AutoPlant:OnSelectCombo(combo)
    -- 统计种子数量满足多少地皮
    local seeds_amount = 4
    for veggie, count in pairs(combo.data) do
        local seeds = FindItems(self.inst, function(item) return item.prefab == PLANT_DEFS[veggie].seed end) or {}
        local seeds_count = 0
        for _, seed in ipairs(seeds) do
            DebugPrint("found seed:", tostring(PLANT_DEFS[veggie].seed), GetStackSize(seed))
            seeds_count = seeds_count + GetStackSize(seed)
        end

        DebugPrint("seeds_count:", tostring(PLANT_DEFS[veggie].seed), seeds_count)
        if seeds_count < count then
            seeds_amount = 0
            break
        end

        seeds_amount = math.min(seeds_amount, seeds_count / count)
    end

    DebugPrint("seeds_amount", tostring(seeds_amount))
    -- 找农田
    local tiles = self:FindFarmTiles(combo) or {}
    self:OpenComboConfirm(combo, tiles, seeds_amount)
end

function AutoPlant:FindFarmTiles(combo)
    local player_pos = self.inst:GetPosition()
    local RADIUS = 8

    local tile_map = {} -- [tx][tz] = tile
    local tiles = {}

    -------------------------------------------------
    -- 收集tile（带tx,ty）
    -------------------------------------------------
    local ents = TheSim:FindEntities(player_pos.x, 0, player_pos.z, RADIUS, nil)
    for _, ent in ipairs(ents) do
        if ent.prefab == "nutrients_overlay" and self:CanPlaceComboOnTile(combo, ent) then
            local pos = ent:GetPosition()
            local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(pos.x, 0, pos.z)

            tile_map[tx] = tile_map[tx] or {}
            tile_map[tx][tz] = ent

            table.insert(tiles, {tile = ent, tx = tx, tz = tz})
        end
    end

    if #tiles < 2 then return nil end

    DebugPrint("found farm tiles:", tostring(#tiles))

    -------------------------------------------------
    -- 收集田字布局
    -------------------------------------------------
    for i = 1, #tiles do
        local tx = tiles[i].tx
        local tz = tiles[i].tz
        if tile_map[tx][tz + 1] and tile_map[tx + 1] and tile_map[tx + 1][tz] and tile_map[tx + 1][tz + 1] then
            return {tile_map[tx][tz], tile_map[tx][tz + 1], tile_map[tx + 1][tz], tile_map[tx + 1][tz + 1]}
        end
    end

    -------------------------------------------------
    -- 收集2格布局
    -------------------------------------------------
    for i = 1, #tiles do
        local tx = tiles[i].tx
        local tz = tiles[i].tz
        local adjacent_tile = tile_map[tx][tz + 1] or tile_map[tx][tz - 1]
                            or tile_map[tx + 1] and tile_map[tx + 1][tz]
                            or tile_map[tx - 1] and tile_map[tx - 1][tz]
        if adjacent_tile then
            return {tile_map[tx][tz], adjacent_tile}
        end
    end

    return nil
end

function AutoPlant:CanPlaceComboOnTile(combo, tile)
    local layouts = plant_planner.GetLayouts(combo)
    if not layouts then return false end

    local positions = plant_planner.GeneratePositionsPlan(tile, layouts.positions)
    local test = 1

    for i = 1, #positions do
        local pos = positions[i]
        if not TheWorld.Map:CanTillSoilAtPoint(pos.x, pos.y, pos.z) then
            test = test - 1
            if test < 0 then
                return false
            end
        end
    end

    return true
end

function AutoPlant:GeneratePlantingPlan(combo, tiles, tiles_count)
    -------------------------------------------------
    -- 1 计算 tile 坐标 + 中心
    -------------------------------------------------
    local tile_datas = {}
    local sum_tx, sum_ty = 0, 0

    for _, tile in ipairs(tiles) do
        local pos = tile:GetPosition()
        local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(pos.x, 0, pos.z)

        table.insert(tile_datas, {
            tile = tile,
            tx = tx,
            tz = tz,
        })

        sum_tx = sum_tx + tx
        sum_ty = sum_ty + tz
    end

    local center_tx = sum_tx / #tile_datas
    local center_ty = sum_ty / #tile_datas

    -------------------------------------------------
    -- 2 生成种植计划
    -------------------------------------------------
    local result = {}
    local layouts = plant_planner.GetLayouts(combo) or {}

    for _, data in ipairs(tile_datas) do
        local tx, tz = data.tx, data.tz
        local tile = data.tile

        local abandon = false

        -- 2格布局：只取一侧（防止左右同时种）
        if #tile_datas > 2 and tiles_count == 2 then
            if tx < center_tx then
                abandon = true
            end
        end

        if not abandon then
            local layout = {}

            if tz < center_ty then
                layout = layouts.layout_up
            elseif tz > center_ty then
                layout = layouts.layout_down
            elseif tx < center_tx then
                layout = layouts.layout_left
            elseif tx > center_tx then
                layout = layouts.layout_right
            end

            local positions = plant_planner.GeneratePositionsPlan(tile, layouts.positions)

            for i = 1, #layout do
                table.insert(result, {
                    plant = layout[i],
                    pos = positions[i],
                    planted = false
                })
            end
        end
    end

    self.targets = result
end

function AutoPlant:ResetPlantingPlan()
    self.target = nil
    self.target_index = 1
    self.targets = {}
    self.state_cd = 0
    self.stuck_attempts = MAX_STUCK_ATTEMPTS
end

function AutoPlant:OpenComboScreen()
    local world_type = GetWorldType()
    local seasons_table = (world_type == WORLDTYPE.FOREST or world_type == WORLDTYPE.CAVE) and seasons_type.dst
                or (world_type == WORLDTYPE.SHIPWRECKED or world_type == WORLDTYPE.VOLCANOWORLD) and seasons_type.sw
                or (world_type == WORLDTYPE.PORKLAND) and seasons_type.ham
                or seasons_type.dst

    local combos = {}
    for k, v in pairs(plant_planner.BALANCED_COMBOS) do
        if plant_planner.LAYOUT_TEMPLATES[v.proportion] then
            for _, season in ipairs(seasons_table) do
                if v.seasons[season] then
                    table.insert(combos, v)
                    break
                end
            end
        end
    end

    if self.inst and self.inst.HUD then
        self.inst.HUD:OpenComboScreen(combos)
    end
end

function AutoPlant:OpenComboConfirm(combo, tiles, seeds_amount)
    if self.inst and self.inst.HUD then
        self.inst.HUD:OpenComboConfirmScreen(combo, tiles, seeds_amount)
    end
end

-------------------------------------------------
-- Start / Stop
-------------------------------------------------

function AutoPlant:Start()
    if not self.enabled then
        self:Stop()
        return
    end

    self.stuck_attempts = MAX_STUCK_ATTEMPTS

    if self.task == nil then
        self.task = self.inst:DoPeriodicTask(self.freq, function()
            self:OnUpdate()
        end)
    end
end

function AutoPlant:Stop()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
    self.state_cd = 0
end

-------------------------------------------------
-- Enable / Disable
-------------------------------------------------

function AutoPlant:Enable()
    self.enabled = true
    self:Start()
    self:UpdateButtonAppearance()
    if self.inst.HUD and self.show_status then
        local tex = "golden_farm_hoe.tex"
        local atlas = resolvefilepath(GetInventoryItemAtlas(tex))
        self.inst.HUD:ShowStatusDisplayer(atlas, tex, STRINGS.AUTOPLANT.PLANTING, self.height)
    end
end

function AutoPlant:Disable()
    self.enabled = false
    self:Stop()
    self:UpdateButtonAppearance()
    if self.inst.HUD and self.show_status then
        self.inst.HUD:HideStatusDisplayer()
    end
end

function AutoPlant:IsEnabled()
    return self.enabled
end

function AutoPlant:UpdateButtonAppearance()
    if self.icon_button then
        if self.enabled then
            self.icon_button:SetTint(1, 1, 1, 1)
        else
            self.icon_button:SetTint(0, 0, 0, 0.5)
        end
    end
end

function AutoPlant:SetShowStatus(bool)
    self.show_status = bool
end

function AutoPlant:SetStatusHeight(height)
    self.height = height
end

function AutoPlant:HasUnfinishedTargets()
    if #self.targets == 0 then
        return false
    end
    for i = 1, #self.targets do
        if not self.targets[i].planted then
            return true
        end
    end
    return false
end

function AutoPlant:SetIconButton(button)
    self.icon_button = button
end

return AutoPlant
