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
function PlayerHud:ShowStatusDisplayer(atlas, tex, str)
    if not self.statusdisplayer then
        self.statusdisplayer = self.root:AddChild(StatusDisplayer(self.owner))
    end

    self.statusdisplayer:SetData(atlas, tex, str)
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
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        inst:AddComponent("autofarm")
        inst.components.autofarm:SetLanguage(GetModConfigData("CFG_LANGUAGE"))
    end
end)

--------------------------------------------------
-- Toggle
--------------------------------------------------
local function Toggle()
    if ThePlayer and ThePlayer.components.autofarm and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus() then
        ThePlayer.components.autofarm:Switch()
    end
end

TheInput:AddKeyDownHandler(GetModConfigData("CFG_KEY"), Toggle)

