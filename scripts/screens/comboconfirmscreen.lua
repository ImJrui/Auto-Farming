local PopupDialogScreen = require("screens/redux/popupdialog")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Text = require("widgets/text")

local ComboConfirmScreen = Class(PopupDialogScreen, function(self, owner, combo, tiles, seeds_amount)
    local title = STRINGS.AUTOPLANT.PLANT_COMBO
    local text = ""

    if seeds_amount < 2 then
        text = text .. STRINGS.AUTOPLANT.SEEDS_INSUFFICIENT .. "\n"
    end

    if #tiles < 2 then
        text = text .. STRINGS.AUTOPLANT.CLEAR_FARM_SOIL .. "\n"
    end

    if text == "" then
        text = " "
    end

    local buttons = {}

    if #tiles >= 2 and seeds_amount >= 2 then
        table.insert(buttons, {
            text = STRINGS.AUTOPLANT.TILES_2,
            cb = function()
                owner.components.autoplant:ResetPlantingPlan()
                owner.components.autoplant:GeneratePlantingPlan(combo, tiles, 2)
                owner.components.autoplant:Enable()
                TheFrontEnd:PopScreen()
                owner.HUD:CloseComboScreen()
            end,
        })
    end

    if #tiles >= 4 and seeds_amount >= 4 then
        table.insert(buttons, {
            text = STRINGS.AUTOPLANT.TILES_4,
            cb = function()
                owner.components.autoplant:ResetPlantingPlan()
                owner.components.autoplant:GeneratePlantingPlan(combo, tiles, 4)
                owner.components.autoplant:Enable()
                TheFrontEnd:PopScreen()
                owner.HUD:CloseComboScreen()
            end,
        })
    end

    table.insert(buttons, {
        text = STRINGS.AUTOPLANT.CANCEL,
        cb = function()
            TheFrontEnd:PopScreen()
        end,
        control = CONTROL_CANCEL
    })

    PopupDialogScreen._ctor(self, title, text, buttons)

    self.owner = owner

    if text == " " and self.text then
        self.text:Hide()
    end

    if not (#tiles >= 2 and seeds_amount >= 2) then
        return
    end

    self.icons = self.dialog:AddChild(Widget("icons"))

    local elements = {}
    local total_w = 0

    for i, plant in ipairs(combo.plants or {}) do
        local count = combo.counts and combo.counts[i] or 1
        local atlas, tex = GetAtlasAndTex(plant)
        if atlas and tex then
            local icon_w = 40
            local text_w = 30

            table.insert(elements, {
                plant = plant,
                count = count,
                width = icon_w + text_w + 10
            })

            total_w = total_w + icon_w + text_w + 10
        end
    end

    local x = -total_w / 2

    for _, e in ipairs(elements) do
        local atlas, tex = GetAtlasAndTex(e.plant)

        local icon = self.icons:AddChild(Image(atlas, tex))
        icon:SetScale(0.45)
        icon:SetPosition(x + 20, 0)
        icon:SetHoverText(STRINGS.NAMES[string.upper(e.plant)] or e.plant)

        local txt = self.icons:AddChild(Text(NUMBERFONT, 22, "x" .. e.count))
        txt:SetPosition(x + 45, 0)
        x = x + e.width
    end

    self.icons:SetPosition(0, 45)

    local names = {}
    for _, plant in ipairs(combo.plants or {}) do
        table.insert(names, STRINGS.NAMES[string.upper(plant)] or plant)
    end

    local combo_str = table.concat(names, " -- ")
    local combo_text = self.icons:AddChild(Text(NUMBERFONT, 22, combo_str))
    combo_text:SetPosition(0, -40)
end)

function ComboConfirmScreen:OnControl(control, down)
    if ComboConfirmScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:PopScreen()
        return true
    end

    return false
end

function ComboConfirmScreen:OnMouseButton(button, down, x, y)
    if ComboConfirmScreen._base.OnMouseButton(self, button, down, x, y) then
        return true
    end

    if not down and button == MOUSEBUTTON_RIGHT then
        TheFrontEnd:PopScreen()
        return true
    end

    return false
end

return ComboConfirmScreen
