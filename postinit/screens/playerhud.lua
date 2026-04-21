local PlayerHud = require("screens/playerhud")

local ComboScreen = require("screens/comboscreen")
local ComboConfirmScreen = require("screens/comboconfirmscreen")
local FilterScreen = require("screens/filterscreen")

local StatusDisplayer = require("widgets/statusdisplayer")

--------------------------------------------------
-- ComboScreen
--------------------------------------------------
function PlayerHud:OpenComboScreen(balanced_combos, filtered_plants)
    self:CloseComboScreen()

    self.comboscreen = ComboScreen(self.owner, balanced_combos, filtered_plants)
    self:OpenScreenUnderPause(self.comboscreen)
end

function PlayerHud:CloseComboScreen()
    if self.comboscreen then
        if self.comboscreen.inst:IsValid() then
            TheFrontEnd:PopScreen(self.comboscreen)
        end
        self.comboscreen = nil
    end
end

--------------------------------------------------
-- ComboConfirm
--------------------------------------------------
function PlayerHud:OpenComboConfirmScreen(combo, tiles, seeds_amount)
    self:CloseComboConfirmScreen()
    self.comboconfirmscreen = ComboConfirmScreen(self.owner, combo, tiles, seeds_amount)
    self:OpenScreenUnderPause(self.comboconfirmscreen)
    return true
end

function PlayerHud:CloseComboConfirmScreen()
    if self.comboconfirmscreen then
        if self.comboconfirmscreen.inst:IsValid() then
            TheFrontEnd:PopScreen(self.comboconfirmscreen)
        end
        self.comboconfirmscreen = nil
    end
end

--------------------------------------------------
-- Filter
--------------------------------------------------
function PlayerHud:OpenFilterScreen(data, filtered_plants, filter_season_index)
    self:CloseFilterScreen()

    if self.comboscreen and self.comboscreen.inst:IsValid() then
        self.comboscreen:Hide()
        self.filter_hidden_comboscreen = self.comboscreen
    else
        self.filter_hidden_comboscreen = nil
    end

    self.filterscreen = FilterScreen(self.owner, data, filtered_plants, filter_season_index)
    self:OpenScreenUnderPause(self.filterscreen)
    return true
end

function PlayerHud:CloseFilterScreen()
    if self.filterscreen then
        if self.filterscreen.inst:IsValid() then
            TheFrontEnd:PopScreen(self.filterscreen)
        end
        self.filterscreen = nil
    end

    if self.filter_hidden_comboscreen and self.filter_hidden_comboscreen.inst:IsValid() then
        self.filter_hidden_comboscreen:Show()
    end
    self.filter_hidden_comboscreen = nil
end
