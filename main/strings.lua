GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local lang = GetModConfigData("LANGUAGE")
 
local function en_zh(string) 
    return string[lang] or string["EN"]
end

STRINGS.AUTOFARM.ENABLED = en_zh({
    EN = "Enabled",
    CN = "启用",
})

STRINGS.AUTOFARM.DISABLED = en_zh({
    EN = "Disabled",
    CN = "关闭",
})

STRINGS.AUTOFARM.MANE = en_zh({
    EN = "Auto Farm",
    CN = "自动种地",
})

STRINGS.AUTOFARM.FARMING = en_zh({
    EN = "Auto Farming...",
    CN = "自动种地中...",
})