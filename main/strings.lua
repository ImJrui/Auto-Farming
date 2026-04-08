GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local lang = GetModConfigData("CFG_LANGUAGE")

local function en_zh(string)
    return string[lang] or string["EN"]
end

STRINGS.AUTOFARM = {
    ENABLED = en_zh({EN = "Enabled", CN = "启用"}),
    DISABLED = en_zh({EN = "Disabled", CN = "关闭"}),
    MANE = en_zh({EN = "Auto Farm", CN = "自动种地"}),
    FARMING = en_zh({EN = "Auto Farming...", CN = "自动照料中..."}),
}

STRINGS.AUTOPLANT = {
    ENABLED = en_zh({EN = "Enabled", CN = "启用"}),
    DISABLED = en_zh({EN = "Disabled", CN = "关闭"}),
    MANE = en_zh({EN = "Auto Plant", CN = "自动种植"}),
    PLANTING = en_zh({EN = "Auto Planting...", CN = "自动耕种中..."}),

    -- ComboScreen
    COMBO_LIST = en_zh({EN = "Combo List", CN = "组合列表"}),
    CONTINUE = en_zh({EN = "Continue", CN = "继续"}),
    CANCEL = en_zh({EN = "Cancel", CN = "取消"}),
    PRIORITY = en_zh({EN = "Priority:", CN = "优先级:"}),
    NOT_IN_SEASON = en_zh({EN = "Not in Season", CN = "不在季节"}),
    UNKNOWN = en_zh({EN = "Unknown", CN = "未知"}),

    -- ComboConfirmScreen
    PLANT_COMBO = en_zh({EN = "Plant this combo?", CN = "种植此组合？"}),
    SEEDS_INSUFFICIENT = en_zh({EN = "Seeds are insufficient", CN = "种子不足"}),
    CLEAR_FARM_SOIL = en_zh({EN = "Clear farm soil first", CN = "请先清理农田土壤"}),
    TILES_2 = en_zh({EN = "2 Tiles", CN = "2 格"}),
    TILES_4 = en_zh({EN = "4 Tiles", CN = "4 格"}),
}