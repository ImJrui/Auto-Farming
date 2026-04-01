GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local lang = GetModConfigData("CFG_LANGUAGE")

local function en_zh(string)
    return string[lang] or string["EN"]
end

STRINGS.AUTOFARM = {
    ENABLED = en_zh({EN = "Enabled", CN = "启用"}),
    DISABLED = en_zh({EN = "Disabled", CN = "关闭"}),
    MANE = en_zh({EN = "Auto Farm", CN = "自动种地"}),
    FARMING = en_zh({EN = "Auto Farming...", CN = "自动种地中..."}),
}