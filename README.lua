local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS -- 得到作物定义表

-- 比例
-- 21
-- 11
-- 311
-- 221
-- 211
-- 111

local A,B,C

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

local layouts = {
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
            A, B, A, B,
            A, B, A, B,
            A, B, A, B,
            A, B, A, B,
            A, B, A, B,
        },
        layout2 = {
            A, B,
            A, B,
            A, B,
            A, B,
            A, B,
            A, B,
            A, B,
            A, B,
            A, B,
            A, B,
        },
        position = SNAP_HEXAGON
    },
    {
        name = "311",
        layout1 = {
            A, A, A, A,
            A, C, C, A,
            A, C, C, A,
            A, B, B, A,
            A, B, B, A,
        },
        layout2 = {
            A, A,
            A, A,
            A, A,
            B, C,
            B, C,
            B, C,
            B, C,
            A, A,
            A, A,
            A, A,
        },
        position = SNAP_HEXAGON
    },
    {
        name = "221",
        layout1 = {
            B, B, B, B,
            A, B, B, A,
            A, B, B, A,
            A, C, C, A,
            A, C, C, A,
        },
        layout2 = {
            A, A,
            A, A,
            B, B,
            B, B,
            C, C,
            C, C,
            B, B,
            B, B,
            A, A,
            A, A,
        },
        position = SNAP_HEXAGON
    },
    {
        name = "211",
        layout1 = {
            0, A, A,
            C, B, A,
            C, B, A,
            C, B, A,
            C, B, A,
            0, A, A,
        },
        layout2 = {
            A, A, A, A, A, A,
            A, B, B, B, B, A,
            0, C, C, C, C, 0,
        },
        position = SNAP_3x3
    },
    {
        name = "111",
        layout1 = {
            A, B, C,
            A, B, C,
            A, B, C,
            A, B, C,
            A, B, C,
            A, B, C,
        },
        layout2 = {
            A, A, A, A, A, A,
            B, B, B, B, B, B,
            C, C, C, C, C, C,
        },
        position = SNAP_3x3
    },
}