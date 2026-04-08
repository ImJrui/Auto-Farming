modimport("main/strings")
modimport("main/constants")
modimport("main/toolutil")

GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end,
})

--------------------------------------------------
-- PlayerHud
--------------------------------------------------
local PlayerHud = require("screens/playerhud")
local StatusDisplayer = require("widgets/statusdisplayer")
function PlayerHud:ShowStatusDisplayer(atlas, tex, str, height)
    if not self.statusdisplayer then
        self.statusdisplayer = self.root:AddChild(StatusDisplayer(self.owner))
    end

    self.statusdisplayer:SetData(atlas, tex, str, height)
    self.statusdisplayer:ShowUI()
end

function PlayerHud:HideStatusDisplayer()
    if self.statusdisplayer then
        self.statusdisplayer:HideUI()
    end
end

--------------------------------------------------
-- Player
--------------------------------------------------
local CFG_SHOW_STATE = GetModConfigData("CFG_SHOW_STATE")
local CFG_STATUS_HEIGHT = GetModConfigData("CFG_STATUS_HEIGHT")

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        inst:AddComponent("autofarm")
        inst:AddComponent("autoplant")
        inst.components.autofarm:SetShowStatus(CFG_SHOW_STATE)
        inst.components.autofarm:SetStatusHeight(CFG_STATUS_HEIGHT)
        inst.components.autoplant:SetShowStatus(CFG_SHOW_STATE)
        inst.components.autoplant:SetStatusHeight(CFG_STATUS_HEIGHT)
    end
end)

--------------------------------------------------
-- Toggle / Open ComboScreen
-- Key press = toggle: OFF → open ComboScreen, ON → disable all
--------------------------------------------------
local function Toggle()
    if not ThePlayer or not ThePlayer.HUD or ThePlayer.HUD:HasInputFocus() then
        return
    end

    local autofarm = ThePlayer.components.autofarm
    local autoplant = ThePlayer.components.autoplant

    local is_running = (autofarm and autofarm:IsEnabled()) or (autoplant and autoplant:IsEnabled())

    if is_running then
        -- Disable all
        if autofarm then autofarm:Disable() end
        if autoplant then autoplant:Disable() end
        ThePlayer.HUD:HideStatusDisplayer()
        ThePlayer.HUD:CloseComboScreen()
        ThePlayer.HUD:CloseComboConfirmScreen()
    else
        -- Open ComboScreen
        if autoplant then
            autoplant:OpenComboScreen()
        end
    end
end

TheInput:AddKeyDownHandler(GetModConfigData("CFG_KEY"), Toggle)

--------------------------------------------------
-- ComboScreen Postinit
--------------------------------------------------
modimport("postinit/screens/playerhud")
