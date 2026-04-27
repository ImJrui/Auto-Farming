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
    inst:AddComponent("autofarm")
    inst:AddComponent("autoplant")
    inst.components.autofarm:SetShowStatus(CFG_SHOW_STATE)
    inst.components.autofarm:SetStatusHeight(CFG_STATUS_HEIGHT)
    inst.components.autoplant:SetShowStatus(CFG_SHOW_STATE)
    inst.components.autoplant:SetStatusHeight(CFG_STATUS_HEIGHT)
end)

--------------------------------------------------
-- OnHotKey
-- Hotkey = ON->OFF, OFF long press->continue, OFF short press->open menu
--------------------------------------------------
local HOTKEY_LONG_PRESS_TIME = 0.5
local hotkey_task = nil
local hotkey_is_down = false
local hotkey_pending_short_press = false
local hotkey_long_pressed = false

local function IsHotKeyBlocked()
    if not ThePlayer or not ThePlayer.HUD or ThePlayer.HUD:HasInputFocus() then
        return true
    end

    return false
end

local function GetAutoComponents()
    local autofarm = ThePlayer.components.autofarm
    local autoplant = ThePlayer.components.autoplant

    return autofarm, autoplant
end

local function IsAutoRunning(autofarm, autoplant)
    return (autofarm and autofarm:IsEnabled()) or (autoplant and autoplant:IsEnabled())
end

local function StopAuto(autofarm, autoplant)
    if autofarm then autofarm:Disable() end
    if autoplant then autoplant:Disable() end
    ThePlayer.HUD:HideStatusDisplayer()
    ThePlayer.HUD:CloseComboScreen()
    ThePlayer.HUD:CloseComboConfirmScreen()
end

local function ContinueAuto(autofarm, autoplant)
    if autoplant and autoplant:HasUnfinishedTargets() then
        autoplant:Enable()
    elseif autofarm then
        autofarm:Enable()
    end
end

local function OpenAutoMenu(autoplant)
    if autoplant then
        autoplant:OpenComboScreen()
    end
end

local function CancelHotKeyTask()
    if hotkey_task then
        hotkey_task:Cancel()
        hotkey_task = nil
    end
end

local function OnHotKeyLongPress()
    hotkey_task = nil
    if not hotkey_pending_short_press then
        return
    end

    hotkey_long_pressed = true

    if IsHotKeyBlocked() then
        return
    end

    local autofarm, autoplant = GetAutoComponents()
    if not IsAutoRunning(autofarm, autoplant) then
        ContinueAuto(autofarm, autoplant)
    end
end

local function OnHotKeyDown()
    if hotkey_is_down then
        return
    end

    if IsHotKeyBlocked() then
        return
    end

    hotkey_is_down = true

    local autofarm, autoplant = GetAutoComponents()
    if IsAutoRunning(autofarm, autoplant) then
        hotkey_pending_short_press = false
        hotkey_long_pressed = false
        CancelHotKeyTask()
        StopAuto(autofarm, autoplant)
        return
    end

    if hotkey_pending_short_press then
        return
    end

    hotkey_pending_short_press = true
    hotkey_long_pressed = false
    CancelHotKeyTask()
    hotkey_task = ThePlayer:DoTaskInTime(HOTKEY_LONG_PRESS_TIME, OnHotKeyLongPress)
end

local function OnHotKeyUp()
    if not hotkey_is_down and not hotkey_pending_short_press then
        return
    end

    local should_open_menu = hotkey_pending_short_press and not hotkey_long_pressed
    hotkey_is_down = false
    hotkey_pending_short_press = false
    hotkey_long_pressed = false
    CancelHotKeyTask()

    if should_open_menu and not IsHotKeyBlocked() then
        local _, autoplant = GetAutoComponents()
        OpenAutoMenu(autoplant)
    end
end

local CFG_KEY = GetModConfigData("CFG_KEY")
TheInput:AddKeyDownHandler(CFG_KEY, OnHotKeyDown)
TheInput:AddKeyUpHandler(CFG_KEY, OnHotKeyUp)

--------------------------------------------------
-- ComboScreen Postinit
--------------------------------------------------
modimport("postinit/screens/playerhud")
