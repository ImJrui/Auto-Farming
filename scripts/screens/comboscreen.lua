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

local ComboScreen = Class(Screen, function(self, owner, balanced_combos)
    Screen._ctor(self, "ComboScreen")

    self.owner = owner
    self.balanced_combos = balanced_combos or {}

    self.root = self:AddChild(TEMPLATES.ScreenRoot("root"))

    self.panel = self.root:AddChild(TEMPLATES.RectangleWindow(520, 620))

    self.title = self.panel:AddChild(Text(BODYTEXTFONT, 40, STRINGS.AUTOPLANT.COMBO_LIST))
    self.title:SetPosition(0, 270)

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

    -- Cancel button
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
    local current_season = TheWorld.state.season
    table.sort(self.balanced_combos, function(a, b)
        local value_a = a.seasons[current_season] and a.priority or a.priority / 2
        local value_b = b.seasons[current_season] and b.priority or b.priority / 2
        return value_a > value_b
    end)

    local items = {}
    for i, combo in ipairs(self.balanced_combos) do
        table.insert(items, {combo = combo})
    end

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
        TEMPLATES.ScrollingGrid(items, {
            context = {},
            widget_width = 500,
            widget_height = 90,
            num_visible_rows = 5,
            num_columns = 1,
            item_ctor_fn = ItemCtor,
            apply_fn = Apply,
        })
    )
end

function ComboScreen:OnControl(control, down)
    if ComboScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down then
        if control == CONTROL_CANCEL then
            self.owner.HUD:CloseComboScreen()
            return true
        end
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
