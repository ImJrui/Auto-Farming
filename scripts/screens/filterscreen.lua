local Screen = require("widgets/screen")
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")

local TEMPLATES = require("widgets/redux/templates")

local CROP_BUTTON_SIZE = 70
local CROP_BUTTON_ATLAS = "images/global_redux.xml"
local CROP_BUTTON_OFF_TEX = "button_carny_square_disabled.tex"
local CROP_BUTTON_ON_TEX = "button_carny_square_normal.tex"
local SEASON_ARROW_ATLAS = "images/global_redux.xml"
local SEASON_ARROW_HEIGHT = 40

local function SetCropButtonState(w, selected)
    local tex = selected and CROP_BUTTON_ON_TEX or CROP_BUTTON_OFF_TEX

    w.bg:SetTextures(CROP_BUTTON_ATLAS, tex, tex, tex, tex, tex)
    w.bg:ForceImageSize(CROP_BUTTON_SIZE, CROP_BUTTON_SIZE)
end

local function MakeSeasonArrowButton(left, onclick)
    local prefix = left and "left" or "right"
    local btn = ImageButton(
        SEASON_ARROW_ATLAS,
        "arrow2_" .. prefix .. ".tex",
        "arrow2_" .. prefix .. "_over.tex",
        "arrow_" .. prefix .. "_disabled.tex",
        "arrow2_" .. prefix .. "_down.tex",
        nil,
        {1, 1},
        {0, 0}
    )

    btn.scale_on_focus = false
    btn.move_on_click = false
    local _, arrow_height = btn:GetSize()
    local arrow_scale = SEASON_ARROW_HEIGHT / arrow_height
    btn:SetScale(arrow_scale, arrow_scale, 1)
    btn:SetOnClick(onclick)

    return btn
end

local function GetSeasonName(season)
    if STRINGS.UI and STRINGS.UI.SERVERLISTINGSCREEN and STRINGS.UI.SERVERLISTINGSCREEN.SEASONS then
        return STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[string.upper(season)] or season
    end
    return season
end

local FilterScreen = Class(Screen, function(self, owner, data, filtered_plants, filter_season_index)
    Screen._ctor(self, "FilterScreen")

    self.owner = owner
    self.data = data or {}

    self.selected = {}
    for _, plant in ipairs(filtered_plants or {}) do
        self.selected[plant] = true
    end

    self.seasons = {}
    for season, _ in pairs(self.data) do
        table.insert(self.seasons, season)
    end

    local order = {
        autumn = 11, winter = 10, spring = 9, summer = 8,
        mild = 7, wet = 6, green = 5, dry = 4,
        temperate = 3, humid = 2, lush = 1,
    }

    table.sort(self.seasons, function(a, b)
        return (order[a] or 0) > (order[b] or 0)
    end)

    local has_filter = filtered_plants ~= nil and #filtered_plants > 0
    self.current_index = has_filter and filter_season_index or 1

    if not self.current_index or not self.seasons[self.current_index] then
        self.current_index = 1
    end

    local current_season = TheWorld and TheWorld.state and TheWorld.state.season
    if not has_filter and current_season then
        for i, season in ipairs(self.seasons) do
            if season == current_season then
                self.current_index = i
                break
            end
        end
    end

    self.root = self:AddChild(TEMPLATES.ScreenRoot("root"))
    self.panel = self.root:AddChild(TEMPLATES.RectangleWindow(520, 500))

    self.title = self.panel:AddChild(Text(BODYTEXTFONT, 40, STRINGS.AUTOPLANT.CROP_FILTER))
    self.title:SetPosition(0, 200)

    self.season_text = self.panel:AddChild(Text(BODYTEXTFONT, 30))
    self.season_text:SetPosition(0, -140)
    self.season_text:SetColour(UICOLOURS.GOLD_SELECTED)

    self.left_btn = self.panel:AddChild(MakeSeasonArrowButton(true, function()
        self:ChangeSeason(-1)
    end))
    self.left_btn:SetPosition(-120, -140)

    self.right_btn = self.panel:AddChild(MakeSeasonArrowButton(false, function()
        self:ChangeSeason(1)
    end))
    self.right_btn:SetPosition(120, -140)

    self.confirm = self.panel:AddChild(
        TEMPLATES.StandardButton(function()
            self:OnConfirm()
        end, STRINGS.AUTOPLANT.CONFIRM, {150, 50})
    )
    self.confirm:SetPosition(-100, -200)

    self.cancel = self.panel:AddChild(
        TEMPLATES.StandardButton(function()
            if self.owner.components.autoplant then
                self.owner.components.autoplant:ClearFilter()
            end
            self.owner.HUD:CloseFilterScreen()
        end, STRINGS.AUTOPLANT.CANCEL, {150, 50})
    )
    self.cancel:SetPosition(100, -200)

    self.grid = self.panel:AddChild(Widget("grid"))
    self.grid:SetPosition(0, 20)

    self:BuildGrid()
    self:Refresh()
end)

function FilterScreen:BuildGrid()
    local function ItemCtor(context, index)
        local w = Widget("item" .. index)

        w.bg = w:AddChild(ImageButton(CROP_BUTTON_ATLAS, CROP_BUTTON_OFF_TEX))
        w.bg.scale_on_focus = false
        w.bg.move_on_click = false
        SetCropButtonState(w, false)

        w.icon = w:AddChild(Image())
        w.icon:SetClickable(false)

        return w
    end

    local function Apply(context, widget, crop)
        if crop then
            widget:Show()

            local atlas, tex = GetAtlasAndTex(crop)
            if atlas and tex then
                widget.icon:Show()
                widget.icon:SetTexture(atlas, tex)
                widget.icon:SetScale(0.5)
                widget.bg:SetHoverText(STRINGS.NAMES[string.upper(crop)] or crop)
            else
                widget.bg:ClearHoverText()
                widget.icon:Hide()
            end

            SetCropButtonState(widget, self.selected[crop])
            widget.bg:SetOnClick(function()
                self.selected[crop] = not self.selected[crop]
                SetCropButtonState(widget, self.selected[crop])
            end)
        else
            widget.bg:ClearHoverText()
            widget.bg:SetOnClick(nil)
            SetCropButtonState(widget, false)
            widget:Hide()
        end
    end

    self.crop_scroll = self.grid:AddChild(TEMPLATES.ScrollingGrid({}, {
        context = {},
        widget_width = CROP_BUTTON_SIZE,
        widget_height = CROP_BUTTON_SIZE,
        num_visible_rows = 3,
        num_columns = 6,
        item_ctor_fn = ItemCtor,
        apply_fn = Apply,
        force_peek = true,
        scrollbar_offset = 20,
    }))
end

function FilterScreen:ChangeSeason(delta)
    if #self.seasons == 0 then
        return
    end

    self.current_index = self.current_index + delta

    if self.current_index < 1 then
        self.current_index = #self.seasons
    elseif self.current_index > #self.seasons then
        self.current_index = 1
    end

    self.selected = {}
    self:Refresh()
end

function FilterScreen:Refresh()
    if #self.seasons == 0 then
        return
    end

    local season = self.seasons[self.current_index]
    self.season_text:SetString(GetSeasonName(season))

    if self.crop_scroll then
        self.crop_scroll:SetItemsData(self.data[season] or {})
        self.crop_scroll:ResetScroll()
    end
end

function FilterScreen:OnConfirm()
    local result = {}

    for crop, v in pairs(self.selected) do
        if v then
            table.insert(result, crop)
        end
    end

    if self.owner.components.autoplant then
        self.owner.components.autoplant:ApplyFilter(result, self.current_index)
    end

    self.owner.HUD:CloseFilterScreen()
end

function FilterScreen:OnRawKey(key, down)
    if not down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        self:OnConfirm()
        return true
    end

    if FilterScreen._base.OnRawKey(self, key, down) then
        return true
    end

    return false
end

function FilterScreen:OnControl(control, down)
    if FilterScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down and control == CONTROL_CANCEL then
        self.owner.HUD:CloseFilterScreen()
        return true
    end

    return false
end

function FilterScreen:OnMouseButton(button, down, x, y)
    if FilterScreen._base.OnMouseButton(self, button, down, x, y) then
        return true
    end

    if not down and button == MOUSEBUTTON_RIGHT then
        self.owner.HUD:CloseFilterScreen()
        return true
    end

    return false
end

return FilterScreen
