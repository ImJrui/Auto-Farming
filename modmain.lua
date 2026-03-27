GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end,
})

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        inst:AddComponent("autofarm")
        inst.components.autofarm:SetLanguage(GetModConfigData("CFG_LANGUAGE"))
    end
end)

local function Toggle()
    if ThePlayer and ThePlayer.components.autofarm and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus() then
        ThePlayer.components.autofarm:Switch()
    end
end

TheInput:AddKeyDownHandler(GetModConfigData("CFG_KEY"), Toggle)

