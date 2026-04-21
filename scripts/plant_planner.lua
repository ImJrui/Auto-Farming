local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS -- 得到作物定义表

local SNAP_3x3 = {
    Vector3(-1.333, 0, -1.333), Vector3(0,      0, -1.333), Vector3(1.333,  0, -1.333),
    Vector3(-1.333, 0,  0),     Vector3(0,      0,  0),     Vector3(1.333,  0,  0),
    Vector3(-1.333, 0,  1.333), Vector3(0,      0,  1.333), Vector3(1.333,  0,  1.333),
}

local SNAP_HEXAGON = {
    Vector3(-1.5, 0, -1.6),   Vector3(0.5, 0, -1.6),
        Vector3(-0.5, 0, -0.8),   Vector3(1.5, 0, -0.8),
    Vector3(-1.5, 0,  0),     Vector3(0.5, 0,  0),
        Vector3(-0.5, 0,  0.8),   Vector3(1.5, 0,  0.8),
    Vector3(-1.5, 0,  1.6),   Vector3(0.5, 0,  1.6),
}

local SNAP_HEXAGON_OFFSET = {
    Vector3(1, 0, 0),   Vector3(1, 0, 0),
        Vector3(-1, 0, 0),   Vector3(-1, 0, 0),
    Vector3(1, 0, 0),   Vector3(1, 0, 0),
        Vector3(-1, 0, 0),   Vector3(-1, 0, 0),
    Vector3(1, 0, 0),   Vector3(1, 0, 0),
}

local LAYOUT_TEMPLATES = {
    ["6-3"] = {
        layout_up = {
            1, 1, 1,
            1, 1, 1,
            2, 2, 2,
        },
        layout_down = {
            2, 2, 2,
            1, 1, 1,
            1, 1, 1,
        },
        layout_left = {
            1, 1, 2,
            1, 1, 2,
            1, 1, 2,
        },
        layout_right = {
            2, 1, 1,
            2, 1, 1,
            2, 1, 1,
        },
        positions = SNAP_3x3
    },
    ["6-2-2"] = {
        layout_up = {
            1, 1,
            1, 1,
            1, 1,
            2, 3,
            2, 3,
        },
        layout_down = {
            2, 3,
            2, 3,
            1, 1,
            1, 1,
            1, 1,
        },
        layout_left = {
            1, 1,
            1, 3,
            1, 3,
            1, 2,
            1, 2,
        },
        layout_right = {
            1, 1,
            3, 1,
            3, 1,
            2, 1,
            2, 1,
        },
        positions = SNAP_HEXAGON
    },
    ["5-5"] = {
        layout_up = {
            1, 2,
            1, 2,
            1, 2,
            1, 2,
            1, 2,
        },
        layout_down = {
            1, 2,
            1, 2,
            1, 2,
            1, 2,
            1, 2,
        },
        layout_left = {
            1, 2,
            1, 2,
            1, 2,
            1, 2,
            1, 2,
        },
        layout_right = {
            1, 2,
            1, 2,
            1, 2,
            1, 2,
            1, 2,
        },
        positions = SNAP_HEXAGON
    },
    ["5-3-2"] = {
        layout_up = {
            1, 1,
            1, 1,
            2, 1,
            2, 3,
            2, 3,
        },
        layout_down = {
            2, 3,
            2, 3,
            2, 1,
            1, 1,
            1, 1,
        },
        layout_left = {
            1, 2,
            1, 2,
            1, 3,
            1, 3,
            1, 3,
        },
        layout_right = {
            2, 1,
            2, 1,
            3, 1,
            3, 1,
            3, 1,
        },
        positions = SNAP_HEXAGON
    },
    ["4-4-2"] = {
        layout_up = {
            1, 1,
            1, 1,
            2, 2,
            2, 2,
            3, 3,
        },
        layout_down = {
            3, 3,
            2, 2,
            2, 2,
            1, 1,
            1, 1,
        },
        layout_left = {
            2, 2,
            1, 2,
            1, 2,
            1, 3,
            1, 3,
        },
        layout_right = {
            2, 2,
            2, 1,
            2, 1,
            3, 1,
            3, 1,
        },
        positions = SNAP_HEXAGON
    },
    ["4-4"] = {
        layout_up = {
            1, 1, 1,
            1, 0, 2,
            2, 2, 2,
        },
        layout_down = {
            1, 1, 1,
            1, 0, 2,
            2, 2, 2,
        },
        layout_left = {
            1, 1, 1,
            1, 0, 2,
            2, 2, 2,
        },
        layout_right = {
            1, 1, 1,
            1, 0, 2,
            2, 2, 2,
        },
        positions = SNAP_3x3
    },
    ["4-2-2"] = {
        layout_up = {
            0, 1, 1,
            3, 2, 1,
            3, 2, 1,
        },
        layout_down = {
            3, 2, 1,
            3, 2, 1,
            0, 1, 1,
        },
        layout_left = {
            1, 1, 1,
            1, 2, 2,
            0, 3, 3,
        },
        layout_right = {
            1, 1, 1,
            2, 2, 1,
            3, 3, 0,
        },
        positions = SNAP_3x3
    },
    ["3-3-3"] = {
        layout_up = {
            1, 2, 3,
            1, 2, 3,
            1, 2, 3,
        },
        layout_down = {
            1, 2, 3,
            1, 2, 3,
            1, 2, 3,
        },
        layout_left = {
            1, 1, 1,
            2, 2, 2,
            3, 3, 3,
        },
        layout_right = {
            1, 1, 1,
            2, 2, 2,
            3, 3, 3,
        },
        positions = SNAP_3x3
    },
}

for k, v in pairs(LAYOUT_TEMPLATES) do
    LAYOUT_TEMPLATES[k].name = k
end

local PLANT_GRADE = {
    dragonfruit = 10,
    pepper = 9,
    garlic = 8,
    potato = 8,
    onion = 8,
    pumpkin = 7,
    tomato = 7,
    asparagus = 6,
    corn = 6,
    eggplant = 6,
    pomegranate = 5,
    watermelon = 5,
    durian = 5,
    carrot = 5,
}
------------------------------------------------------
-- [[计算营养物质]]
------------------------------------------------------
local PLANT_NUTRIENTS = {} -- {dragonfruit={L/2, L/2, -L}}

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
    for _,v in ipairs(restore_idex) do
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
-- [[养分平衡组合]]
------------------------------------------------------
local BALANCED_COMBOS = {} -- 平衡组合

local COMMON_SEASONS_CACHE = {} -- 缓存表

local function GetCommonSeasons(plants)
    local cache_key = table.concat(plants, "-")
    if COMMON_SEASONS_CACHE[cache_key] then
        return COMMON_SEASONS_CACHE[cache_key]
    end

    local first = plants[1]
    local seasons = {}

    -- 先复制第一个植物的季节
    for season, bool in pairs(PLANT_DEFS[first].good_seasons) do
        if bool then
            seasons[season] = true
        end
    end

    -- 逐个取交集
    for season,_ in pairs(seasons) do
        for i = 2, #plants do
            local plant = plants[i]
            local good = PLANT_DEFS[plant].good_seasons

            if not good[season] then
                seasons[season] = nil
                break
            end
        end
    end

    COMMON_SEASONS_CACHE[cache_key] = seasons
    return seasons
end

local function HasAnySeason(seasons)
    return next(seasons) ~= nil
end

local function IsBalanced(combo) -- combo = {palnt1 = num1, plant2 = num2}
    local total_nutrients = {0, 0, 0}
    for plant,num in pairs(combo) do
        local nutrients = PLANT_NUTRIENTS[plant]
        for i,v in ipairs(nutrients) do
            total_nutrients[i] = total_nutrients[i] + v*num
        end
    end
    for _,v in ipairs(total_nutrients) do
        if math.abs(v) > 0.01 then
            return false
        end
    end
    return true
end

local function SortByCount(combo_data)
    -- combo_data格式: {plant1 = num1, plant2 = num2, ...}
    local data = {}

    -- 将键值对转换为数组，便于排序
    for name, count in pairs(combo_data) do
        table.insert(data, {
            name = name,
            count = count
        })
    end

    -- 按数量从大到小排序
    table.sort(data, function(a, b)
        if a.count == b.count then
            return a.name < b.name
        end
        return a.count > b.count
    end)

    -- 只提取植物名称，形成有序数组
    local priority = 0
    local sorted_plants = {}
    local sorted_counts = {}
    local sorted_str = {}
    for i, v in ipairs(data) do
        sorted_str[i] = v.name.."*"..v.count
        priority = priority + (PLANT_GRADE[v.name] or 5) * v.count
        sorted_plants[i] = v.name
        sorted_counts[i] = v.count
    end

    return table.concat(sorted_str, ","), priority, sorted_plants, sorted_counts
end

local function FindBalancedCombos()
    local results = {}

    local plants = {}
    for plant,_ in pairs(PLANT_NUTRIENTS) do
        table.insert(plants, plant)
    end

    local slotsnum = {8, 9, 10}

    -- 组合：2种植物
    for _, total in ipairs(slotsnum) do
        for i = 1, #plants do
            for j = i+1, #plants do
                local p1, p2 = plants[i], plants[j]

                for n1 = 2, total-2 do
                    local n2 = total - n1
                    if n2 >= 2 then
                        local combo = {
                            [p1] = n1,
                            [p2] = n2
                        }

                        if IsBalanced(combo) then
                            local name, priority, sorted_plants, sorted_counts = SortByCount(combo)
                            local seasons = GetCommonSeasons(sorted_plants)
                            if HasAnySeason(seasons) then
                                table.insert(results, {
                                    data = combo,
                                    proportion = table.concat(sorted_counts, "-"),
                                    seasons = seasons,
                                    plants = sorted_plants,
                                    counts = sorted_counts,
                                    name = name,
                                    priority = priority,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    -- 组合：3种植物
    for _, total in ipairs(slotsnum) do
        for i = 1, #plants do
            for j = i+1, #plants do
                for k = j+1, #plants do
                    local p1, p2, p3 = plants[i], plants[j], plants[k]

                    for n1 = 2, total-4 do
                        for n2 = 2, total-n1-2 do
                            local n3 = total - n1 - n2
                            if n3 >= 2 then
                                local combo = {
                                    [p1] = n1,
                                    [p2] = n2,
                                    [p3] = n3
                                }

                                if IsBalanced(combo) then
                                    local name, priority, sorted_plants, sorted_counts = SortByCount(combo)
                                    local seasons = GetCommonSeasons(sorted_plants)
                                    if HasAnySeason(seasons) then
                                        table.insert(results, {
                                            data = combo,
                                            proportion = table.concat(sorted_counts, "-"),
                                            seasons = seasons,
                                            plants = sorted_plants,
                                            counts = sorted_counts,
                                            name = name,
                                            priority = priority,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return results
end

BALANCED_COMBOS = FindBalancedCombos()

------------------------------------------------------
-- [[计算布局]]
------------------------------------------------------
local function GetLayouts(combo)
    local plants = combo.plants

    -- 2. 获取模板
    local template = LAYOUT_TEMPLATES[combo.proportion]
    if not template then return nil end

    -- 3. 创建结果布局（深拷贝，避免修改模板）
    local result = {
        name = template.name,
        positions = template.positions,
        layout_up = {},
        layout_down = {},
        layout_left = {},
        layout_right = {}
    }

    -- 4. 替换占位符
    local function ProcessLayout(layout_array)
        local layout = {}
        for _, value in ipairs(layout_array) do
            local name = plants[value] or 0
            table.insert(layout, name)
        end
        return layout
    end

    result.layout_up = ProcessLayout(template.layout_up)
    result.layout_down = ProcessLayout(template.layout_down)
    result.layout_left = ProcessLayout(template.layout_left)
    result.layout_right = ProcessLayout(template.layout_right)

    return result
end

local function GeneratePositionsPlan(tile, positions)
    local result = {}
    local tiles_pos = tile:GetPosition()
    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(tiles_pos.x, 0, tiles_pos.z)  -- 获取网格坐标
    local offset = #positions > 9 and ty % 2 == 1 and SNAP_HEXAGON_OFFSET or {}

    for i = 1, #positions do
        table.insert(result, tiles_pos + positions[i] + (offset[i] or Vector3(0, 0, 0)))
    end

    return result
end

local IN_SEASON_PLANTS = {}

for plant, def in pairs(PLANT_DEFS) do
    if plant ~= "randomseed" and def.good_seasons then
        for season, v in pairs(def.good_seasons) do
            if v then
                IN_SEASON_PLANTS[season] = IN_SEASON_PLANTS[season] or {}
                table.insert(IN_SEASON_PLANTS[season], plant)
            end
        end
    end
end

return {
    SNAP_3x3 = SNAP_3x3,
    SNAP_HEXAGON = SNAP_HEXAGON,
    SNAP_HEXAGON_OFFSET = SNAP_HEXAGON_OFFSET,
    PLANT_NUTRIENTS = PLANT_NUTRIENTS,
    BALANCED_COMBOS = BALANCED_COMBOS,
    LAYOUT_TEMPLATES = LAYOUT_TEMPLATES,
    IN_SEASON_PLANTS = IN_SEASON_PLANTS,
    GetLayouts = GetLayouts,
    GeneratePositionsPlan = GeneratePositionsPlan,
}

--[[ 示例 Examples
BALANCED_COMBOS = {
    {
        data = {tomato = 6, dragonfruit = 3},
        proportion = "6-3",
        seasons = {spring = true},
        plants = {"tomato", "dragonfruit"} -- 排序好的
    },
    ...
}

PLANT_NUTRIENTS = {
    tomato = {-S, -S, 2S},
    dragonfruit = {L/2, L/2, -L},
    ...
}

GetLayouts(combo) = {
    name = "6-3",
    positions = SNAP_3x3,
    layout_up = {
        tomato,        tomato,          tomato,
        tomato,        tomato,          tomato,
        dragonfruit,   dragonfruit,    dragonfruit,
    },
    layout_down = {
        dragonfruit,    dragonfruit,    dragonfruit,
        tomato,         tomato,         tomato,
        tomato,         tomato,         tomato,
    },
    layout_left = {
        tomato,         tomato,         dragonfruit,
        tomato,         tomato,         dragonfruit,
        tomato,         tomato,         dragonfruit,
    },
    layout_right = {
        dragonfruit,    tomato,         tomato,
        dragonfruit,    tomato,         tomato,
        dragonfruit,    tomato,         tomato,
    },
}
]]
