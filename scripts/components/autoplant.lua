local function CalcProportions()
    local results = {}

    --------------------------------------------------
    -- 收集作物
    --------------------------------------------------

    local crops = {}

    for name, def in pairs(PLANT_DEFS) do
        if name ~= "randomseed" and def.nutrient_consumption then
            table.insert(crops, {
                name = name,
                n = def.nutrient_consumption
            })
        end
    end

    --------------------------------------------------
    -- 工具函数
    --------------------------------------------------

    local function deepcopy(t)
        local r = {}
        for k,v in pairs(t) do
            r[k] = type(v)=="table" and deepcopy(v) or v
        end
        return r
    end

    local function calc_sum(combo)
        local sum = {0,0,0}
        for crop, cnt in pairs(combo) do
            local n = PLANT_DEFS[crop].nutrient_consumption
            sum[1] = sum[1] + n[1]*cnt
            sum[2] = sum[2] + n[2]*cnt
            sum[3] = sum[3] + n[3]*cnt
        end
        return sum
    end

    local function is_balanced(sum)
        return sum[1] == 0 and sum[2] == 0 and sum[3] == 0
    end

    local function build_proportion(data)
        local arr = {}
        for _,v in pairs(data) do table.insert(arr, v) end
        table.sort(arr, function(a,b) return a>b end)
        return table.concat(arr, "-")
    end

    local function intersect_seasons(data)
        local res = {autumn=true, winter=true, spring=true, summer=true}

        for crop,_ in pairs(data) do
            local def = PLANT_DEFS[crop]
            if def and def.good_seasons then
                for s,_ in pairs(res) do
                    if not def.good_seasons[s] then
                        res[s] = nil
                    end
                end
            end
        end

        return res
    end

    --------------------------------------------------
    -- 2种组合
    --------------------------------------------------

    for i=1,#crops do
        for j=i+1,#crops do

            local A = crops[i].name
            local B = crops[j].name

            -- 枚举数量（限制范围避免爆炸）
            for a=2,10 do
                for b=2,10 do

                    local combo = {
                        [A] = a,
                        [B] = b,
                    }

                    local sum = calc_sum(combo)

                    if is_balanced(sum) then
                        table.insert(results, {
                            data = combo,
                            proportion = build_proportion(combo),
                            seasons = intersect_seasons(combo),
                        })
                    end

                end
            end
        end
    end

    --------------------------------------------------
    -- 3种组合
    --------------------------------------------------

    for i=1,#crops do
        for j=i+1,#crops do
            for k=j+1,#crops do

                local A = crops[i].name
                local B = crops[j].name
                local C = crops[k].name

                for a=2,8 do
                    for b=2,8 do
                        for c=2,8 do

                            local combo = {
                                [A] = a,
                                [B] = b,
                                [C] = c,
                            }

                            local sum = calc_sum(combo)

                            if is_balanced(sum) then
                                table.insert(results, {
                                    data = combo,
                                    proportion = build_proportion(combo),
                                    seasons = intersect_seasons(combo),
                                })
                            end

                        end
                    end
                end

            end
        end
    end

    --------------------------------------------------
    -- 去重（关键！）
    --------------------------------------------------

    local unique = {}
    local final = {}

    for _,v in ipairs(results) do
        local key = v.proportion

        -- 再加作物种类防止冲突
        local names = {}
        for k,_ in pairs(v.data) do table.insert(names, k) end
        table.sort(names)

        key = key .. "|" .. table.concat(names, ",")

        if not unique[key] then
            unique[key] = true
            table.insert(final, v)
        end
    end

    --------------------------------------------------

    return final
end