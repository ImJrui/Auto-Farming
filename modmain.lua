modimport("main/strings")
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
        inst.components.autofarm:SetShowStatus(CFG_SHOW_STATE)
        inst.components.autofarm:SetStatusHeight(CFG_STATUS_HEIGHT)
    end
end)

--------------------------------------------------
-- Toggle
--------------------------------------------------
local function Toggle()
    if ThePlayer and ThePlayer.components.autofarm and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus() then
        ThePlayer.components.autofarm:SetNextMode()
    end
end

TheInput:AddKeyDownHandler(GetModConfigData("CFG_KEY"), Toggle)

