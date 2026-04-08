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
version = "1.0.2"

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
        name = "CFG_DEBUG_MODE",
        label = en_zh({en = "Debug Mode", zh = "调试模式"}),
        options = {
			AddOption(en_zh({en = "Disable", zh = "关闭"}), false),
			AddOption(en_zh({en = "Enable", zh = "启用"}), true),
        },
        default = false,
    },
    {
        name = "CFG_LANGUAGE",
        -- hover = "",
        label = en_zh({en = "language", zh = "语言"}),
        options = {
			AddOption("English", "EN"),
			AddOption("中文", "CN"),
        },
        default = "CN",
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
    {
        name = "CFG_SHOW_STATE",
        -- hover = "",
        label = en_zh({en = "Display Status", zh = "显示状态"}),
        options = {
			AddOption(en_zh({en = "Enable", zh = "启用"}), true),
			AddOption(en_zh({en = "Disable", zh = "关闭"}), false),
        },
        default = true,
    },
    {
        name = "CFG_STATUS_HEIGHT",
		hover = en_zh({ -- 优化点2：补充详细的悬停提示
			en = "Adjust the vertical position of the status text/icon above your character's head.",
			zh = "调整状态文字/图标在角色头顶的垂直显示高度。"
		}),
        label = en_zh({en = "Status HUD Height", zh = "状态提示高度"}),
        options = {
			AddOption(en_zh({en = "High", zh = "较高"}), 4.25),
			AddOption(en_zh({en = "Normal", zh = "默认"}), 2.5),
			AddOption(en_zh({en = "Bottom", zh = "底部"}), -1),
        },
        default = 2.5,
    },
}

mod_dependencies = {}

icon_atlas = "preview.xml"
icon = "preview.tex"