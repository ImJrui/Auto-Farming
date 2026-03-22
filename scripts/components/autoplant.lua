function AutoPlant:GenerateTemplates()
    local templates = {}

    ------------------------------------------------------------------
    -- 基础配置
    ------------------------------------------------------------------
    local SNAP_3x3 = {
        {-1.333, -1.333}, {0, -1.333}, {1.333, -1.333},
        {-1.333, 0},      {0, 0},      {1.333, 0},
        {-1.333, 1.333},  {0, 1.333},  {1.333, 1.333},
    }

    local SNAP_HEX = {
        {-1.5, -1.6}, {0.5, -1.6},
            {-0.5, -0.8}, {1.5, -0.8},
        {-1.5, 0},    {0.5, 0},
            {-0.5, 0.8},  {1.5, 0.8},
        {-1.5, 1.6},  {0.5, 1.6},
    }

    local TILE_OFFSET = 4 -- 两块地之间距离

    ------------------------------------------------------------------
    -- 工具函数
    ------------------------------------------------------------------

    local function deepcopy(t)
        local r = {}
        for k,v in pairs(t) do
            r[k] = type(v)=="table" and deepcopy(v) or v
        end
        return r
    end

    local function intersect_seasons(crops)
        local res = nil
        for _, crop in ipairs(crops) do
            local def = PLANT_DEFS[crop]
            if def and def.good_seasons then
                if not res then
                    res = deepcopy(def.good_seasons)
                else
                    for s,_ in pairs(res) do
                        if not def.good_seasons[s] then
                            res[s] = nil
                        end
                    end
                end
            end
        end
        return res or {}
    end

    local function count_plants(layout)
        local t = {}
        for _, p in ipairs(layout) do
            t[p.crop] = (t[p.crop] or 0) + 1
        end
        return t
    end

    ------------------------------------------------------------------
    -- 排序逻辑（核心：保证家族）
    ------------------------------------------------------------------

    local function build_fill_order(snap, boundary_mode)
        local order = {}

        for i, pos in ipairs(snap) do
            local x, z = pos[1], pos[2]
            table.insert(order, {
                idx = i,
                proj = x,      -- 左右方向
                perp = z       -- 上下行
            })
        end

        if boundary_mode then
            table.sort(order, function(a,b)
                return a.proj < b.proj
            end)
        else
            table.sort(order, function(a,b)
                if a.perp ~= b.perp then
                    return a.perp < b.perp
                end
                return a.proj < b.proj
            end)
        end

        local r = {}
        for _,v in ipairs(order) do
            table.insert(r, v.idx)
        end
        return r
    end

    ------------------------------------------------------------------
    -- 单地块布局生成
    ------------------------------------------------------------------

    local function build_single_tile(snap, crops, counts)
        local minc, maxc = counts[1], counts[1]
        for _,c in ipairs(counts) do
            minc = math.min(minc, c)
            maxc = math.max(maxc, c)
        end

        local boundary_mode = (minc * 2 <= maxc)

        local order = build_fill_order(snap, boundary_mode)

        -- 按数量排序
        local idxs = {}
        for i=1,#crops do table.insert(idxs, i) end
        table.sort(idxs, function(a,b) return counts[a] > counts[b] end)

        local assign = {}
        local pos = 1

        for _,ci in ipairs(idxs) do
            for _=1,counts[ci] do
                table.insert(assign, {
                    snap_idx = order[pos],
                    crop = crops[ci]
                })
                pos = pos + 1
            end
        end

        return assign
    end

    ------------------------------------------------------------------
    -- 双地块拼接（核心）
    ------------------------------------------------------------------

    local function build_two_tiles(pattern, crops, counts)
        local snap = (pattern=="3x3") and SNAP_3x3 or SNAP_HEX

        local tile1 = build_single_tile(snap, crops, counts)
        local tile2 = {}

        -- 镜像（只镜像作物分布，不改snap）
        for _, v in ipairs(tile1) do
            table.insert(tile2, {
                snap_idx = v.snap_idx,
                crop = v.crop
            })
        end

        local layout = {}

        -- 左地块
        for _, v in ipairs(tile1) do
            local off = snap[v.snap_idx]
            table.insert(layout, {
                crop = v.crop,
                x = off[1] - TILE_OFFSET/2,
                z = off[2]
            })
        end

        -- 右地块（镜像X）
        for _, v in ipairs(tile2) do
            local off = snap[v.snap_idx]
            table.insert(layout, {
                crop = v.crop,
                x = -off[1] + TILE_OFFSET/2,
                z = off[2]
            })
        end

        return layout
    end

    ------------------------------------------------------------------
    -- 枚举组合（2~3作物）
    ------------------------------------------------------------------

    local crops = {}
    for name, def in pairs(PLANT_DEFS) do
        if name ~= "randomseed" then
            table.insert(crops, name)
        end
    end

    local patterns = {
        {name="3x3", slots=9},
        {name="hex", slots=10},
    }

    for _, pat in ipairs(patterns) do
        for i=1,#crops do
            for j=i+1,#crops do
                local c1, c2 = crops[i], crops[j]

                for n1=2, pat.slots-2 do
                    local n2 = pat.slots - n1

                    local layout = build_two_tiles(
                        pat.name,
                        {c1, c2},
                        {n1, n2}
                    )

                    local plants = count_plants(layout)

                    -- 每种作物至少4株（跨两地块）
                    local ok = true
                    for _,v in pairs(plants) do
                        if v < 4 then ok = false break end
                    end

                    if ok then
                        table.insert(templates, {
                            layout = layout,
                            seasons = intersect_seasons({c1,c2}),
                            plants = plants,
                        })
                    end
                end
            end
        end
    end

    self.templates = templates
end