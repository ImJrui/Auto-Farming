local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS -- 得到作物定义表

<!-- 计算作物营养物质 -->
nutrient_consumption代表作物消耗的营养物质，表中是数值类型{M, 0, 0}
nutrient_restoration代表作物是否恢复营养物质，表中是布尔值类型或者空值{nil, true, true}
计算养分消耗/储存数据，消耗量=储蓄量，返回一个表nutrient{-M, M/2, M/2}

<!-- 设计布局坐标 -->
直接参考
AutoFarmLogic.SNAP_3x3 = {
    {-1.333, -1.333}, {0, -1.333}, {1.333, -1.333},
    {-1.333, 0},      {0, 0},      {1.333, 0},
    {-1.333, 1.333},  {0, 1.333},  {1.333, 1.333},
}

AutoFarmLogic.SNAP_HEXAGON = {
    {-1.5, -1.6}, {0.5, -1.6},
    {-0.5, -0.8}, {1.5, -0.8},
    {-1.5, 0},    {0.5, 0},
    {-0.5, 0.8},  {1.5, 0.8},
    {-1.5, 1.6},  {0.5, 1.6},
}

<!-- 设计种植模板 -->
根据营养物质和布局坐标，制作布局模板，模板全部以2个相邻的农田地块为标准型
载入时一次计算，并标记季节、作物数量信息，游戏中只要引用就行，如
{
    {combination = data, season = "spring", plants = {"farm_plant_1" = 1, "farm_plant_2" = 2, "farm_plant_3" = 2}},
    ...
}
data需要设计好每块农田上作物的种类和坐标

比例
21
11
311
221
211
111

layouts = {
    {
        name = "21",
        layout1 = {
            A, A, A,
            A, A, A,
            B, B, B,
            B, B, B,
            A, A, A,
            A, A, A,
        },
        layout2 = {
            A, A, B, B, A, A,
            A, A, B, B, A, A,
            A, A, B, B, A, A,
        },
        position = SNAP_3x3
    },
    {
        name = "11",
        layout1 = {
            A, A, A,
            A, A, A,
            B, B, B,
            B, B, B,
            A, A, A,
            A, A, A,
        },
        layout2 = {
            A, A, B, B, A, A,
            A, A, B, B, A, A,
            A, A, B, B, A, A,
        },
    },
        name = "311",
        layout1 = {
            A, A, A,
            A, A, A,
            B, B, B,
            B, B, B,
            A, A, A,
            A, A, A,
        },
        layout2 = {
            A, A, B, B, A, A,
            A, A, B, B, A, A,
            A, A, B, B, A, A,
        },
    },
        name = "221
}