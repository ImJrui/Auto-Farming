local MODROOT = MODROOT
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)
require("translator")

local languages = {
    zh = "chinese_s",
    zhr = "chinese_s",
    ch = "chinese_s",
    chs = "chinese_s",
    sc = "chinese_s",
    zht = "chinese_s",
    tc = "chinese_s",
    cht = "chinese_s",
}

local function import(module_name)
    module_name = module_name .. ".lua"
    local result = kleiloadlua(MODROOT .. "strings/" .. module_name)

    if result == nil then
        error("Strings file not found: " .. module_name)
    elseif type(result) == "string" then
        error("Error loading strings/" .. module_name .. "!\n" .. result)
    else
        setfenv(result, PLENV)
        return result()
    end
end

-- 加载字符串表
ToolUtil.MergeTable(STRINGS, import("common"), true)

-- 获取服务器语言并加载对应 PO 文件
local desiredlang = LOC.GetLocaleCode()
if desiredlang and languages[desiredlang] then
    PLENV.LoadPOFile("scripts/languages/masterfarmer_" .. languages[desiredlang] .. ".po", desiredlang)
    TranslateStringTable(STRINGS)
end
