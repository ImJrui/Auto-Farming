local lang = locale
local function en_zh(String)  -- use this fn can be automatically translated according to the language in the table
	String.zhr = String.zh
	String.zht = String.zht or String.zh
	return String[lang] or String.en
end

--The name of the mod displayed in the 'mods' screen.
name = en_zh({en = "Master Farmer", zh = "种田高手"})

--A description of the mod.
description = en_zh({
	en = "",
	zh = "",
})

--Who wrote this awesome mod?
author = "TUTU"

--A version number so you can ask people if they are running an old version of your mod.
version = "1.0.0"

--This lets other players know if your mod is out of date. This typically needs to be updated every time there's a new game update.
api_version = 10

dst_compatible = true

--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = false

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = true

--This lets people search for servers with this mod by these tags
server_filter_tags = {}


priority =-20  --模组优先级0-10 mod 加载的顺序   0最后载入  覆盖大值


local function AddOption(KEY, data)
	return {description = KEY, data = data}
end

configuration_options={ --模组变量配置
    {
        name = "CFG_LANGUAGE",
        -- hover = "",
        label = en_zh({en = "language", zh = "语言"}),
        options = {
			AddOption("English", "EN"),
			AddOption("中文", "ZH"),
        },
        default = "ZH",
    },
    {
        name = "CFG_KEY",
        -- hover = "",
        label = en_zh({en = "key", zh = "按键"}),
        options = {
			AddOption("B", 98),
			AddOption("C", 99),
			AddOption("G", 103),
			AddOption("H", 104),
			AddOption("J", 106),
			AddOption("K", 107),
			AddOption("L", 108),
			AddOption("N", 110),
			AddOption("O", 111),
			AddOption("P", 112),
			AddOption("R", 114),
			AddOption("T", 116),
			AddOption("V", 118),
			AddOption("X", 120),
			AddOption("Z", 122),
			AddOption("F1", 282),
			AddOption("F2", 283),
			AddOption("F3", 284),
			AddOption("F4", 285),
			AddOption("F5", 286),
			AddOption("F6", 287),
			AddOption("F7", 288),
			AddOption("F8", 289),
			AddOption("F9", 290),
			AddOption("F10", 291),
			AddOption("F11", 292),
        },
        default = 111,
    },
}

mod_dependencies = {}

icon_atlas = "preview.xml"
icon = "preview.tex"