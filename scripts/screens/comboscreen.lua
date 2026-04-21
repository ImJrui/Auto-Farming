local Screen = require("widgets/screen")
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")

local TEMPLATES = require("widgets/redux/templates")

-- 定义季节排序顺序
local season_sort = {
    DST = {
        autumn = 4,
        winter = 3,
        spring = 2,
        summer = 1,
    },
    SW = {
        mild = 4,
        wet = 3,
        green = 2,
        dry = 1,
    },
    HAM = {
        temperate = 3,
        humid = 2,
        lush = 1,
    },
}

local function GetSeasonName(season)
    local season_display
    if STRINGS.UI and STRINGS.UI.SERVERLISTINGSCREEN and STRINGS.UI.SERVERLISTINGSCREEN.SEASONS then
        season_display = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[string.upper(season)]
    end

    if not season_display or season_display == "" then
        season_display = season:sub(1, 1):upper() .. season:sub(2)
    end

    return season_display
end

local function ComboContainsAllPlants(combo, plants)
    if not plants or #plants == 0 then
        return true
    end

    local combo_plants = {}
    for _, plant in ipairs(combo.plants or {}) do
        combo_plants[plant] = true
    end

    for _, plant in ipairs(plants) do
        if not combo_plants[plant] then
            return false
        end
    end

    return true
end

local function GetPlantDisplayName(plant)
    return STRINGS.NAMES[string.upper(plant)] or plant
end

local function GetFilteredPlantsText(plants)
    local names = {}

    for _, plant in ipairs(plants or {}) do
        table.insert(names, GetPlantDisplayName(plant))
    end

    return table.concat(names, ",")
end

local ComboScreen = Class(Screen, function(self, owner, balanced_combos, filtered_plants)
    Screen._ctor(self, "ComboScreen")

    self.owner = owner
    self.all_combos = balanced_combos or {}
    self.filtered_plants = filtered_plants or {}

    self.root = self:AddChild(TEMPLATES.ScreenRoot("root"))

    self.panel = self.root:AddChild(TEMPLATES.RectangleWindow(520, 620))

    self.title = self.panel:AddChild(Text(BODYTEXTFONT, 40, STRINGS.AUTOPLANT.COMBO_LIST))
    self.title:SetPosition(0, 270)

    self.filter = self.panel:AddChild(
        TEMPLATES.StandardButton(
            function()
                self.owner.components.autoplant:OpenFilterScreen()
            end,
            "Filter",
            {75, 40}
        )
    )
    self.filter:SetPosition(-178, 252)

    local crafting_atlas = resolvefilepath(CRAFTING_ATLAS)
    self.clear_filter = self.panel:AddChild(
        TEMPLATES.StandardButton(
            function()
                if self.owner.components.autoplant then
                    self.owner.components.autoplant:ClearFilter()
                end
            end,
            "",
            {40, 40}
        )
    )
    self.clear_filter:SetPosition(-120, 252)
    self.clear_filter.icon = self.clear_filter:AddChild(Image(crafting_atlas, "pinslot_unpin_button.tex"))
    self.clear_filter.icon:SetScale(0.3)
    self.clear_filter.icon:SetClickable(false)
    self.clear_filter:SetHoverText("clear")

    self:UpdateFilterButtonText()

    -- Continue button → resume autoplant if has unfinished targets, otherwise enable autofarm
    self.continue = self.panel:AddChild(
        TEMPLATES.StandardButton(
            function()
                if self.owner.components.autoplant:HasUnfinishedTargets() then
                    self.owner.components.autoplant:Enable()
                else
                    self.owner.components.autofarm:Enable()
                end
                self.owner.HUD:CloseComboScreen()
            end,
            STRINGS.AUTOPLANT.CONTINUE,
            {150, 50}
        )
    )
    self.continue:SetPosition(-100, -270)

    self.cancel = self.panel:AddChild(
        TEMPLATES.StandardButton(
            function() self.owner.HUD:CloseComboScreen() end,
            STRINGS.AUTOPLANT.CANCEL,
            {150, 50}
        )
    )
    self.cancel:SetPosition(100, -270)

    self:BuildList()
end)

function ComboScreen:BuildList()
    local function ItemCtor(context, index)
        local w = Widget("item" .. index)
        w.bg = w:AddChild(TEMPLATES.ListItemBackground(500, 90, function() end))
        w.bg.move_on_click = true

        w.icons = w:AddChild(Widget("icons"))
        w.icons:SetPosition(-200, 0)

        w.name = w:AddChild(Text(BODYTEXTFONT, 28))
        w.name:SetPosition(60, 15)

        w.season = w:AddChild(Text(UIFONT, 20))
        w.season:SetPosition(60, -25)

        return w
    end

    local function Apply(context, widget, data)
        if not data then
            widget:Hide()
            return
        end

        widget:Show()

        local combo = data.combo
        local current_season = TheWorld.state.season

        widget.icons:KillAllChildren()

        local x = 0
        for i, plant in ipairs(combo.plants or {}) do
            local count = combo.counts and combo.counts[i] or 1
            local atlas, tex = GetAtlasAndTex(plant)
            if atlas and tex then
                local icon = widget.icons:AddChild(Image(atlas, tex))
                icon:SetScale(0.4, 0.4)
                icon:SetPosition(x, 10)
                icon:SetHoverText(STRINGS.NAMES[string.upper(plant)] or plant)

                local txt = widget.icons:AddChild(Text(NUMBERFONT, 20, "x" .. count))
                txt:SetPosition(x, -20)
                x = x + 60
            end
        end

        if combo.seasons and combo.seasons[current_season] then
            widget.name:SetString(STRINGS.AUTOPLANT.PRIORITY .. tostring(combo.priority or 0))
            widget.name:SetColour(1, 1, 1, 1)
        else
            widget.name:SetString(STRINGS.AUTOPLANT.NOT_IN_SEASON)
            widget.name:SetColour(1, 0, 0, 1)
        end

        local world_type = GetWorldType()
        local sort_table = (world_type == WORLDTYPE.FOREST or world_type == WORLDTYPE.CAVE) and season_sort.DST
            or (world_type == WORLDTYPE.SHIPWRECKED or world_type == WORLDTYPE.VOLCANOWORLD) and season_sort.SW
            or (world_type == WORLDTYPE.PORKLAND) and season_sort.HAM
            or season_sort.DST

        local seasons = {}
        for season, bool in pairs(combo.seasons or {}) do
            if bool and sort_table[season] then
                table.insert(seasons, season)
            end
        end

        table.sort(seasons, function(a, b)
            return (sort_table[a] or 0) > (sort_table[b] or 0)
        end)

        local seasons_name = {}
        for _, season in ipairs(seasons) do
            table.insert(seasons_name, GetSeasonName(season))
        end
        widget.season:SetString(#seasons_name > 0 and table.concat(seasons_name, ", ") or STRINGS.AUTOPLANT.UNKNOWN)

        widget.bg:SetOnClick(function()
            self.owner.components.autoplant:OnSelectCombo(combo)
        end)
    end

    self.scroll = self.panel:AddChild(
        TEMPLATES.ScrollingGrid({}, {
            context = {},
            widget_width = 500,
            widget_height = 90,
            num_visible_rows = 5,
            num_columns = 1,
            item_ctor_fn = ItemCtor,
            apply_fn = Apply,
        })
    )

    self:RefreshList()
end

function ComboScreen:SetFilterPlants(filtered_plants)
    self.filtered_plants = filtered_plants or {}
    self:UpdateFilterButtonText()
    self:RefreshList()
end

function ComboScreen:UpdateFilterButtonText()
    local has_filter = #(self.filtered_plants or {}) > 0

    if self.filter then
        if has_filter then
            self.filter:SetText("Filtered")
            self.filter:SetHoverText("Filtered:" .. GetFilteredPlantsText(self.filtered_plants), {offset_y = 45})
        else
            self.filter:SetText("Filter")
            self.filter:ClearHoverText()
        end
    end

    if self.clear_filter then
        if has_filter then
            self.clear_filter:Show()
        else
            self.clear_filter:Hide()
        end
    end
end

function ComboScreen:RefreshList()
    if not self.scroll then
        return
    end

    local current_season = TheWorld.state.season
    local filtered_combos = {}

    for _, combo in ipairs(self.all_combos or {}) do
        if ComboContainsAllPlants(combo, self.filtered_plants) then
            table.insert(filtered_combos, combo)
        end
    end

    table.sort(filtered_combos, function(a, b)
        local value_a = a.seasons[current_season] and a.priority or a.priority / 2
        local value_b = b.seasons[current_season] and b.priority or b.priority / 2
        return value_a > value_b
    end)

    local items = {}
    for _, combo in ipairs(filtered_combos) do
        table.insert(items, {combo = combo})
    end

    self.scroll:SetItemsData(items)
    self.scroll:ResetScroll()
end

function ComboScreen:OnControl(control, down)
    if ComboScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down and control == CONTROL_CANCEL then
        self.owner.HUD:CloseComboScreen()
        return true
    end

    return false
end

function ComboScreen:OnMouseButton(button, down, x, y)
    if ComboScreen._base.OnMouseButton(self, button, down, x, y) then
        return true
    end

    if not down and button == MOUSEBUTTON_RIGHT then
        self.owner.HUD:CloseComboScreen()
        return true
    end

    return false
end

return ComboScreen
