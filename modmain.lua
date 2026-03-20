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
    local player = ThePlayer
    if player and player.components.autofarm then
        player.components.autofarm:Switch()
    end
end

TheInput:AddKeyDownHandler(GetModConfigData("CFG_KEY"), Toggle)

