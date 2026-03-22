local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS -- 得到作物定义表

local SNAP_3x3 = {
    {-1.333, -1.333}, {0, -1.333}, {1.333, -1.333},
    {-1.333, 0},      {0, 0},      {1.333, 0},
    {-1.333, 1.333},  {0, 1.333},  {1.333, 1.333},
}

local SNAP_HEXAGON = {
    {-1.5, -1.6},   {0.5, -1.6},
        {-0.5, -0.8},   {1.5, -0.8},
    {-1.5, 0},      {0.5, 0},
        {-0.5, 0.8},    {1.5, 0.8},
    {-1.5, 1.6},    {0.5, 1.6},
}
------------------------------------------------------
-- [[计算营养物质]]
------------------------------------------------------
local PLANT_NUTRIENTS = {}

local function GetPlantNutrients(plant)
    local def = PLANT_DEFS[plant]
    if not def then
        print("InValid Plant")
        return nil
    end

    local nutrients = {0, 0, 0}

    local total_nutrients = 0
    local restore_idex = {}
    for i, v in ipairs(def.nutrient_consumption) do
        total_nutrients = total_nutrients + v
        if v == 0 then
            table.insert(restore_idex, i)
        else
            nutrients[i] = -v
        end
    end

    local restore_val = total_nutrients / #restore_idex
    for _,v in pairs(restore_idex) do
        nutrients[v] = restore_val
    end

    return nutrients
end

for plant, def in pairs(PLANT_DEFS) do
    if plant ~= "randomseed" then
        PLANT_NUTRIENTS[plant] = GetPlantNutrients(plant)
    end
end
------------------------------------------------------
-- [[计算比例]]
------------------------------------------------------
local BALANCED_COMBOS = {}

local function IsBalanced(combo) -- combo = {palnt1 = num1, plant2 = num2}
    local total_nutrients = {0, 0, 0}
    for plant,num in pairs(combo) do
        local nutrients = PLANT_NUTRIENTS[plant]
        for i,v in pairs(nutrients) do
            total_nutrients[i] = total_nutrients[i] + v*num
        end
    end
    for _,v in pairs(total_nutrients) do
        if math.abs(v) > 0.01 then
            return false
        end
    end
    return true
end

local function FindBalancedCombos()
    local slotsnum = {8, 9, 10}
end

BALANCED_COMBOS = {
    {
        data = {
            pumpkin = 4,
            potato = 2,
            garlic = 2,
        },
        proportion = "4-2-2", --需要从大到小排序
        season = {autumn = true, winter = true},
    },
    {
        data = {
            tomato = 6,
            dragonfruit = 3,
        },
        proportion = "6-3", --需要从大到小排序
        season = {spring = true},
    },
}

for _,v in pairs(BALANCED_COMBOS) do
    local name = nil
    local seasons = {autumn = true, winter = true, spring = true, summer = true}
    for plant,mun in pairs(v.data) do
        if name then
            name = tostring(mun)
        else
            name = name.."-"..tostring(mun)
        end

        for season,_ in pairs(seasons) do
            if not PLANT_DEFS[plant].good_seasons[season] then
                seasons[season] = nil
            end
        end
    end

    v.proportion = name
    v.seasons = seasons
end


local AutoPlant = Class(function(self, inst)

    self.inst = inst

    self.enabled = false

    self.state = nil
    self.target = nil

    self.state_cd = 0

    self.pos = nil

    self.task = nil
    self.icon_button = nil

    self.freq = 0.1

    self.mode_index = 1
    self.modes = {false,true}

    self.lang = "EN"
end)


function AutoPlant:CalcLayout(A, B, C, prop)
    A, B, C = A or 0, B or 0, C or 0

    local layouts = {
        ["6-3"] = {
            name = "6-3",
            layout_up = {
                A, A, A,
                A, A, A,
                B, B, B,
            },
            layout_down = {
                B, B, B,
                A, A, A,
                A, A, A,
            },
            layout_left = {
                A, A, B,
                A, A, B,
                A, A, B,
            },
            layout_right = {
                B, A, A,
                B, A, A,
                B, A, A,
            },
            position = SNAP_3x3
        },
        ["5-5"] = {
            name = "5-5",
            layout_up = {
                A, B,
                A, B,
                A, B,
                A, B,
                A, B,
            },
            layout_down = {
                A, B,
                A, B,
                A, B,
                A, B,
                A, B,
            },
            layout_left = {
                A, B,
                A, B,
                A, B,
                A, B,
                A, B,
            },
            layout_right = {
                A, B,
                A, B,
                A, B,
                A, B,
                A, B,
            },
            position = SNAP_HEXAGON
        },
        ["6-2-2"] = {
            name = "6-2-2",
            layout_up = {
                A, A,
                A, A,
                A, A,
                B, C,
                B, C,
            },
            layout_down = {
                B, C,
                B, C,
                A, A,
                A, A,
                A, A,
            },
            layout_left = {
                A, A,
                A, C,
                A, C,
                A, B,
                A, B,
            },
            layout_right = {
                A, A,
                C, A,
                C, A,
                B, A,
                B, A,
            },
            position = SNAP_HEXAGON
        },
        ["4-4-2"] = {
            name = "4-4-2",
            layout_top = {
                A, A,
                A, A,
                B, B,
                B, B,
                C, C,
            },
            layout_down = {
                C, C,
                B, B,
                B, B,
                A, A,
                A, A,
            },
            layout_left = {
                B, B,
                A, B,
                A, B,
                A, C,
                A, C,
            },
            layout_right = {
                B, B,
                B, A,
                B, A,
                C, A,
                C, A,
            },
            position = SNAP_HEXAGON
        },
        ["4-2-2"] = {
            name = "4-2-2",
            layout_up = {
                0, A, A,
                C, B, A,
                C, B, A,
            },
            layout_down = {
                C, B, A,
                C, B, A,
                0, A, A,
            },
            layout_left = {
                A, A, A,
                A, B, B,
                0, C, C,
            },
            layout_right = {
                A, A, A,
                B, B, A,
                C, C, 0,
            },
            position = SNAP_3x3
        },
        ["3-3-3"] = {
            name = "3-3-3",
            layout_up = {
                A, B, C,
                A, B, C,
                A, B, C,
            },
            layout_down = {
                A, B, C,
                A, B, C,
                A, B, C,
            },
            layout_left = {
                A, A, A,
                B, B, B,
                C, C, C,
            },
            layout_right = {
                A, A, A,
                B, B, B,
                C, C, C,
            },
            position = SNAP_3x3
        },
    }
    return layouts[prop]
end

return AutoPlant