local PlayerHud = require("screens/playerhud")

local ComboScreen = require("screens/comboscreen")
local ComboConfirmScreen = require("screens/comboconfirmscreen")

local StatusDisplayer = require("widgets/statusdisplayer")

--------------------------------------------------
-- ComboScreen
--------------------------------------------------
function PlayerHud:OpenComboScreen(balanced_combos)
    self:CloseComboScreen()

    self.comboscreen = ComboScreen(self.owner, balanced_combos)
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
