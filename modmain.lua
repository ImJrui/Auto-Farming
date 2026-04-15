modimport("main/constants")
modimport("main/toolutil")
modimport("main/strings")

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
-- OnHotKey
-- Hotkey = ON→OFF, OFF+Ctrl→continue, OFF→open menu
--------------------------------------------------
local function OnHotKey()
    if not ThePlayer or not ThePlayer.HUD or ThePlayer.HUD:HasInputFocus() then
        return
    end

    local autofarm = ThePlayer.components.autofarm
    local autoplant = ThePlayer.components.autoplant
    local is_running = (autofarm and autofarm:IsEnabled()) or (autoplant and autoplant:IsEnabled())

    if is_running then
        if autofarm then autofarm:Disable() end
        if autoplant then autoplant:Disable() end
        ThePlayer.HUD:HideStatusDisplayer()
        ThePlayer.HUD:CloseComboScreen()
        ThePlayer.HUD:CloseComboConfirmScreen()
    elseif TheInput:IsKeyDown(KEY_CTRL) then
        if autoplant and autoplant:HasUnfinishedTargets() then
            autoplant:Enable()
        else
            autofarm:Enable()
        end
    else
        if autoplant then
            autoplant:OpenComboScreen()
        end
    end
end

TheInput:AddKeyDownHandler(GetModConfigData("CFG_KEY"), OnHotKey)

--------------------------------------------------
-- ComboScreen Postinit
--------------------------------------------------
modimport("postinit/screens/playerhud")
