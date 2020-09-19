function omni.lib.set_recipe_ingredients(recipename, ...)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        local arg = {...}
        local ingredients = {}
        for i, v in pairs(arg) do
            local tmp = {}
            if type(v) == "string" then
                tmp = {{name = v, type = "item", amount = 1}}
            elseif type(v) == "table" then
                if type(v[1]) == "string" then
                    tmp = {{name = v[1], type = "item", amount = v[2]}}
                elseif v.name then
                    tmp = {
                        {
                            name = v.name,
                            type = v.type or "item",
                            amount = v.amount,
                            probability = v.probability,
                            amount_min = v.amount_min,
                            amount_max = v.amount_max
                        }
                    }
                end
            end
            ingredients = omni.lib.union(ingredients, tmp)
        end

        if recipe.ingredients then recipe.ingredients = ingredients end
        if recipe.normal and recipe.normal.ingredients then
            recipe.normal.ingredients = ingredients
        end
        if recipe.expensive and recipe.expensive.ingredients then
            recipe.expensive.ingredients = ingredients
        end
    end
end

function omni.lib.set_recipe_results(recipename, ...)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        local arg = {...}
        local results = {}
        for i, v in pairs(arg) do
            local tmp = {}
            if type(v) == "string" then
                tmp = {{name = v, type = "item", amount = 1}}
            elseif type(v) == "table" then
                if type(v[1]) == "string" then
                    tmp = {{name = v[1], type = "item", amount = v[2]}}
                elseif v.name then
                    tmp = {
                        {
                            name = v.name,
                            type = v.type or "item",
                            amount = v.amount,
                            probability = v.probability,
                            amount_min = v.amount_min,
                            amount_max = v.amount_max
                        }
                    }
                end
            end
            results = omni.lib.union(results, tmp)
        end
        if recipe.result then
            recipe.result = nil
            recipe.result_count = nil
            if not recipe.results then recipe.normal.results = {} end
        end
        if recipe.results then recipe.results = result end
        if recipe.normal then
            if recipe.normal.result then
                recipe.normal.result = nil
                recipe.normal.result_count = nil
            end
            recipe.normal.results = result
        end
        if recipe.expensive then
            if recipe.expensive.result then
                recipe.expensive.result = nil
                recipe.expensive.result_count = nil
            end
            recipe.expensive.results = result
        end
    end
end

local function parse_item_argument(item)
    if not item then
        return nil, nil
        -- A single string -> a minimal item prototype
    elseif type(item) == "string" then
        return {type = "item", name = item, amount = 1},
               {type = "item", name = item, amount = 1}
        -- A table of 1 or 2 element -> name + amount
    elseif type(item[1]) == "string" then
        return {type = "item", name = item[1], amount = item[2] or 1},
               {type = "item", name = item[1], amount = item[2] or 1}
        -- There is a name -> we parse it as an item prototype
    elseif item.name then
        -- We add default values
        if not item.type then item.type = "item" end
        if not item.amout then item.amount = 1 end
        return item, item
        -- A split normal/expensive via named table
    elseif item.normal or item.expensive then
        local normal_item, expensive_item = nil, nil
        if item.normal then
            normal_item, _ = parse_item_argument(item.normal)
        end
        if item.expensive then
            _, expensive_item = parse_item_argument(item.expensive)
        end
        return normal_item, expensive_item
        -- A split normal/expensive via list
    elseif type(item[1]) == "table" then
        local normal_item, expensive_item = nil, nil
        if item[1] then normal_item, _ = parse_item_argument(item[1]) end
        if item[2] then _, expensive_item = parse_item_argument(item[2]) end
        return normal_item, expensive_item
    else
        log("Could not parse item: " .. item)
        return nil, nil
    end
end

local function split_expensive_recipe(recipe)
    -- Already slitted
    if recipe.normal and recipe.expensive then return end

    recipe.normal = {}
    recipe.expensive = {}

    if recipe.energy_required then
        recipe.normal.energy_required = recipe.energy_required
        recipe.expensive.energy_required = recipe.energy_required
        -- Clean base recipe
        recipe.energy_required = nil
    end

    if recipe.ingredients then
        recipe.normal.ingredients = table.deepcopy(recipe.ingredients)
        recipe.expensive.ingredients = table.deepcopy(recipe.ingredients)
        -- Clean base recipe
        recipe.ingredients = nil
    end

    if recipe.result then
        local results = {
            {
                type = "item",
                name = recipe.result,
                amount = recipe.result_count or 1
            }
        }
        recipe.normal.results = table.deepcopy(results)
        recipe.expensive.results = table.deepcopy(results)
        -- Clean base recipe
        recipe.result = nil
        recipe.result_count = nil
    end

    if recipe.results then
        recipe.normal.results = table.deepcopy(recipe.results)
        recipe.expensive.results = table.deepcopy(recipe.results)
        -- Clean base recipe
        recipe.results = nil
    end
end

local function merge_ingredients(ingredients, to_add)
    -- Check if ingredient the ingredient is already used
    for i, ingredient in pairs(ingredients) do
        -- check if nametags exist (only check ingredient[i] when no name tags exist)
        if ingredient.name and ingredient.name == to_add.name then
            ingredient.amount = ingredient.amount + to_add.amount
            return
        elseif ingredient[1] and ingredient[1] == to_add.name then
            ingredient[2] = ingredient[2] + to_add.amount
            return
        end
    end

    table.insert(ingredients, to_add)
end

function omni.lib.add_recipe_ingredient(recipename, ingredient)
    local recipe = data.raw.recipe[recipename]

    -- The recipe does not exist, we can do nothing
    if not recipe then
        -- log("omni.lib.add_recipe_ingredient: "..recipe.." does not exist.")
        return
    end

    -- Parse passed ingredient
    local normal_ingredient, expensive_ingredient =
        parse_item_argument(ingredient)

    -- Splitted recipe ingredients
    if normal_ingredient ~= expensive_ingredient or
        (recipe.normal or recipe.expensive) then
        -- If not already do, split the recipe
        split_expensive_recipe(recipe)

        if normal_ingredient then
            -- If there was no ingredient then we will make one
            if not recipe.normal.ingredients then
                recipe.normal.ingredients = {}
            end
            merge_ingredients(recipe.normal.ingredients, normal_ingredient)
        end

        if expensive_ingredient then
            -- If there was no ingredient then we will make one
            if not recipe.expensive.ingredients then
                recipe.expensive.ingredients = {}
            end
            merge_ingredients(recipe.expensive.ingredients, expensive_ingredient)
        end
    elseif normal_ingredient then
        -- If there was no ingredient then we will make one
        if not recipe.ingredients then recipe.ingredients = {} end
        merge_ingredients(recipe.ingredients, normal_ingredient)
    end
end

function omni.lib.add_recipe_result(recipename, result)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        local norm = {}
        local expens = {}
        if not result.name then
            if type(result) == "string" then
                norm = {type = "item", name = result, amount = 1}
                expens = {type = "item", name = result, amount = 1}
            elseif result.normal or result.expensive then
                if result.normal then
                    norm = {
                        type = result.normal.type or "item",
                        name = result.normal.name or result.normal[1],
                        amount = result.normal.amount or result.normal[2] or 1
                    }
                else
                    norm = nil
                end
                if result.expensive then
                    expens = {
                        type = result.expensive.type or "item",
                        name = result.expensive.name or result.expensive[1],
                        amount = result.expensive.amount or result.expensive[2] or
                            1
                    }
                else
                    expens = nil
                end
            elseif result[1].name then
                norm = result[1]
                expens = result[2]
            elseif type(result[1]) == "string" then
                norm = {type = "item", name = result[1], amount = result[2]}
                expens = {type = "item", name = result[1], amount = result[2]}
            end
        else
            norm = result
            expens = result
        end
        local found = false
        -- Single result checks
        if recipe.result then
            recipe.results = {type = "item", name = recipe.result, amount = 1}
            recipe.result = nil
            recipe.result_count = nil
        end
        if recipe.normal.result then
            recipe.normal.results = {type = "item", name = recipe.result, amount = 1}
            recipe.normal.result = nil
            recipe.normal.result_count = nil
        end
        if recipe.expensive.result then
            recipe.expensive.results = {
                type = "item",
                name = recipe.result,
                amount = 1
            }
            recipe.expensive.result = nil
            recipe.expensive.result_count = nil
        end
        -- recipe.results --If only .normal needs to be modified, keep results, else copy into .normal/.expensive
        if recipe.results and norm ~= expens then
            recipe.normal = {}
            recipe.expensive = {}
            recipe.normal.results = table.deepcopy(recipe.results)
            recipe.expensive.results = table.deepcopy(recipe.results)
            recipe.results = nil
            if recipe.ingredients then
                recipe.normal.results = table.deepcopy(recipe.ingredients)
                recipe.expensive.results = table.deepcopy(recipe.ingredients)
                recipe.ingredients = nil
            end
        elseif recipe.results and norm then
            found = false
            for i, result in pairs(recipe.results) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name then
                    if result.name == norm.name then
                        found = true
                        result.amount = result.amount + norm.amount
                        break
                    end
                elseif result[1] and result[1] == norm.name then
                    found = true
                    result[2] = result[2] + norm.amount
                    break
                end
            end
            if not found then table.insert(recipe.results, norm) end
        end
        -- recipe.normal.results
        if norm and recipe.normal and recipe.normal.results then
            found = false
            for i, result in pairs(recipe.normal.results) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name then
                    if result.name == norm.name then
                        found = true
                        result.amount = result.amount + norm.amount
                        break
                    end
                elseif result[1] and result[1] == norm.name then
                    found = true
                    result[2] = result[2] + norm.amount
                    break
                end
            end
            if not found then table.insert(recipe.normal.results, norm) end
        end
        -- recipe.expensive.results
        if expens and recipe.expensive and recipe.expensive.results then
            found = false
            for i, result in pairs(recipe.expensive.results) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name then
                    if result.name == expens.name then
                        found = true
                        result.amount = result.amount + expens.amount
                        break
                    end
                elseif result[1] and result[1] == expens.name then
                    found = true
                    result[2] = result[2] + expens.amount
                    break
                end
            end
            if not found then
                table.insert(recipe.expensive.results, expens)
            end
        end
    else
        -- log(recipe.." does not exist.")
    end
end

function omni.lib.remove_recipe_ingredient(recipename, ingredient)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        if recipe.ingredients then
            for i, ingredient in pairs(recipe.ingredients) do
                if ingredient.name == ingredient or ingredient[1] == ingredient then
                    table.remove(recipe.ingredients, i)
                end
            end
        end
        if recipe.normal and recipe.normal.ingredients then
            for i, ingredient in pairs(recipe.normal.ingredients) do
                if ingredient.name == ingredient or ingredient[1] == ingredient then
                    table.remove(recipe.normal.ingredients, i)
                end
            end
        end
        if recipe.expensive and recipe.expensive.ingredients then
            for i, ingredient in pairs(recipe.expensive.ingredients) do
                if ingredient.name == ingredient or ingredient[1] == ingredient then
                    table.remove(recipe.expensive.ingredients, i)
                end
            end
        end
    else
        log("Can not remove ingredient " .. ingredient .. ". Recipe " ..
                recipename .. " not found.")
    end
end

function omni.lib.remove_recipe_result(recipename, result)
    local recipe = data.raw.recipe[recipename]
    if not recipe.result and not recipe.normal.result then
        if recipe.results then
            for i, result in pairs(recipe.results) do
                if result.name == result then
                    table.remove(recipe.results, i)
                    if recipe.normal.main_product and recipe.normal.main_product ==
                        result then
                        recipe.normal.main_product = nil
                    end
                    break
                end
            end
        end
        if recipe.normal and recipe.normal.results then
            for i, result in pairs(recipe.normal.results) do
                if result.name == result then
                    table.remove(recipe.normal.results, i)
                    if recipe.normal.main_product and recipe.normal.main_product ==
                        result then
                        recipe.normal.main_product = nil
                    end
                    break
                end
            end
        end
        if recipe.expensive and recipe.expensive.results then
            for i, result in pairs(recipe.expensive.results) do
                if result.name == result then
                    table.remove(recipe.expensive.results, i)
                    if recipe.expensive.main_product and recipe.expensive.main_product ==
                        result then
                        recipe.expensive.main_product = nil
                    end
                    break
                end
            end
        end
    else
        log("Attempted to remove the only result that recipe " .. recipename ..
                " has. Cannot be done")
    end
end

function omni.lib.replace_recipe_result(recipename, result, replacement)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        local repname = nil
        local repamount = nil
        local reptype = nil
        if type(replacement) == "table" then
            repname = replacement.name or replacement[1]
            repamount = replacement.amount or replacement[2]
            reptype = replacement.type
        else
            repname = replacement
        end
        -- Single result
        if recipe.result and recipe.result == result then recipe.result = repname end
        if recipe.normal and recipe.normal.result and recipe.normal.result == result then
            recipe.normal.result = repname
        end
        if recipe.expensive and recipe.expensive.result and recipe.expensive.result ==
            result then recipe.expensive.result = repname end

        -- recipe.results
        local ress = {}
        if recipe.results then ress[#ress + 1] = recipe.results end
        if recipe.normal and recipe.normal.results then
            ress[#ress + 1] = recipe.normal.results
        end
        if recipe.expensive and recipe.expensive.results then
            ress[#ress + 1] = recipe.expensive.results
        end

        for _, diff in pairs(ress) do
            local found = false
            local num = 0
            -- create a new variable that gets reset to repamount for each diff
            local amount = repamount
            -- check if the replacement is already an result
            for i, result in pairs(diff) do
                if (result.name or result[1]) == repname then
                    found = true
                    num = i
                    amount = (repamount or 1) + (result.amount or result[2])
                    break
                end
            end

            for i, result in pairs(diff) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name and result.name == result then
                    if found then
                        if diff[num].amount then
                            diff[num].amount = amount
                        else
                            diff[num][2] = repamount
                        end
                        diff[i] = nil
                    else
                        result.name = repname
                        result.amount = repamount or result.amount
                        result.type = reptype or result.type
                    end
                    break
                elseif not result.name and result[1] and result[1] == result then
                    if found then
                        if diff[num].amount then
                            diff[num].amount = amount
                        else
                            diff[num][2] = repamount
                        end
                        diff[i] = nil
                    else
                        result[1] = repname
                        result[2] = repamount or result[2]
                    end
                    break
                end
            end
        end
        -- Check if the main product was replaced
        if recipe.main_product and recipe.main_product == result then
            recipe.main_product = repname
        end
        if recipe.normal and recipe.normal.main_product and recipe.normal.main_product ==
            result then recipe.normal.main_product = repname end
        if recipe.expensive and recipe.expensive.main_product and
            recipe.expensive.main_product == result then
            recipe.normexpensiveal.main_product = repname
        end
    end
end

function omni.lib.replace_recipe_ingredient(recipename, ingredient, replacement)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        local repname = nil
        local repamount = nil
        local reptype = nil
        if type(replacement) == "table" then
            repname = replacement.name or replacement[1]
            repamount = replacement.amount or replacement[2]
            reptype = replacement.type
        else
            repname = replacement
        end

        local ings = {}
        if recipe.ingredients then ings[#ings + 1] = recipe.ingredients end
        if recipe.normal and recipe.normal.ingredients then
            ings[#ings + 1] = recipe.normal.ingredients
        end
        if recipe.expensive and recipe.expensive.ingredients then
            ings[#ings + 1] = recipe.expensive.ingredients
        end

        for _, diff in pairs(ings) do
            local found = false
            local num = 0
            -- create a new variable that gets reset to repamount for each diff
            local amount = repamount
            -- check if the replacement is already an ingredient
            for i, ingredient in pairs(diff) do
                if (ingredient.name or ingredient[1]) == repname then
                    found = true
                    num = i
                    amount = (repamount or 1) + (ingredient.amount or ingredient[2])
                    break
                end
            end

            for i, ingredient in pairs(diff) do
                -- check if nametags exist (only check ingredient[i] when no name tags exist)
                if ingredient.name and ingredient.name == ingredient then
                    if found then
                        if diff[num].amount then
                            diff[num].amount = amount
                        else
                            diff[num][2] = repamount
                        end
                        diff[i] = nil
                    else
                        ingredient.name = repname
                        ingredient.amount = repamount or ingredient.amount
                        ingredient.type = reptype or ingredient.type
                    end
                    break
                elseif not ingredient.name and ingredient[1] and ingredient[1] == ingredient then
                    if found then
                        if diff[num].amount then
                            diff[num].amount = amount
                        else
                            diff[num][2] = repamount
                        end
                        diff[i] = nil
                    else
                        ingredient[1] = repname
                        ingredient[2] = repamount or ingredient[2]
                    end
                    break
                end
            end
        end
    end
end

function omni.lib.multiply_recipe_ingredient(recipename, ingredient, mult)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        -- recipe.ingredients
        if recipe.ingredients then
            for i, ingredient in pairs(recipe.ingredients) do
                -- check if nametags exist (only check ingredient[i] when no name tags exist)
                if ingredient.name then
                    if ingredient.name == ingredient then
                        ingredient.amount = omni.lib.round(ingredient.amount * mult)
                        break
                    end
                elseif ingredient[1] and ingredient[1] == ingredient then
                    ingredient[2] = omni.lib.round(ingredient[2] * mult)
                    break
                end
            end
        end
        -- recipe.normal.ingredients
        if recipe.normal and recipe.normal.ingredients then
            for i, ingredient in pairs(recipe.normal.ingredients) do
                -- check if nametags exist (only check ingredient[i] when no name tags exist)
                if ingredient.name then
                    if ingredient.name == ingredient then
                        ingredient.amount = omni.lib.round(ingredient.amount * mult)
                        break
                    end
                elseif ingredient[1] and ingredient[1] == ingredient then
                    ingredient[2] = omni.lib.round(ingredient[2] * mult)
                    break
                end
            end
        end
        -- recipe.expensive.ingredients
        if recipe.expensive and recipe.expensive.ingredients then
            for i, ingredient in pairs(recipe.expensive.ingredients) do
                -- check if nametags exist (only check ingredient[i] when no name tags exist)
                if ingredient.name then
                    if ingredient.name == ingredient then
                        ingredient.amount = omni.lib.round(ingredient.amount * mult)
                        break
                    end
                elseif ingredient[1] and ingredient[1] == ingredient then
                    ingredient[2] = omni.lib.round(ingredient[2] * mult)
                    break
                end
            end
        end
    end
end

function omni.lib.multiply_recipe_result(recipename, result, mult)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        -- Single result
        if recipe.result and recipe.result == result then
            recipe.results = {type = "item", name = recipe.result, amount = 1}
            recipe.result = nil
            recipe.result_count = nil
        end
        if recipe.normal and recipe.normal.result and recipe.normal.result == result then
            recipe.normal.results = {
                type = "item",
                name = recipe.normal.result,
                amount = 1
            }
            recipe.normal.result = nil
            recipe.normal.result_count = nil
        end
        if recipe.expensive and recipe.expensive.result and recipe.expensive.result ==
            result then
            recipe.expensive.results = {
                type = "item",
                name = recipe.expensive.result,
                amount = 1
            }
            recipe.expensive.result = nil
            recipe.expensive.result_count = nil
        end
        -- recipe.results
        if recipe.results then
            for i, result in pairs(recipe.results) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name then
                    if result.name == result then
                        result.amount = omni.lib.round(result.amount * mult)
                        break
                    end
                elseif result[1] and result[1] == result then
                    result[2] = omni.lib.round(result[2] * mult)
                    break
                end
            end
        end
        -- recipe.normal.results
        if recipe.normal and recipe.normal.results then
            for i, result in pairs(recipe.normal.results) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name then
                    if result.name == result then
                        result.amount = omni.lib.round(result.amount * mult)
                        break
                    end
                elseif result[1] and result[1] == result then
                    result[2] = omni.lib.round(result[2] * mult)
                    break
                end
            end
        end
        -- recipe.expensive.results
        if recipe.expensive and recipe.expensive.results then
            for i, result in pairs(recipe.expensive.results) do
                -- check if nametags exist (only check result[i] when no name tags exist)
                if result.name then
                    if result.name == result then
                        result.amount = omni.lib.round(result.amount * mult)
                        break
                    end
                elseif result[1] and result[1] == result then
                    result[2] = omni.lib.round(result[2] * mult)
                    break
                end
            end
        end
    end
end

function omni.lib.replace_all_ingredient(ingredient, replacement)
    for _, recipe in pairs(data.raw.recipe) do
        omni.lib.replace_recipe_ingredient(recipe.name, ingredient, replacement)
    end
end

function omni.lib.replace_all_result(result, replacement)
    for _, recipe in pairs(data.raw.recipe) do
        omni.lib.replace_recipe_result(recipe.name, result, replacement)
    end
end

function omni.lib.change_recipe_category(recipe, category)
    data.raw.recipe[recipe].category = category
end

-- Checks if a recipe contains a specific material as result
function omni.lib.recipe_result_contains(recipename, itemname)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        -- Single result
        if recipe.result and recipe.result == itemname then return true end
        if recipe.normal and recipe.normal.result and recipe.normal.result == itemname then
            return true
        end
        if recipe.expensive and recipe.expensive.result and recipe.expensive.result ==
            itemname then return true end
        -- recipe.results
        if recipe.results then
            for i, result in pairs(recipe.results) do
                if omni.lib.is_in_table(itemname, result) then
                    return true
                end
            end
        end
        -- recipe.normal.results
        if recipe.normal and recipe.normal.results then
            for i, result in pairs(recipe.normal.results) do
                if omni.lib.is_in_table(itemname, result) then
                    return true
                end
            end
        end
        -- recipe.expensive.results
        if recipe.expensive and recipe.expensive.results then
            for i, result in pairs(recipe.expensive.results) do
                if omni.lib.is_in_table(itemname, result) then
                    return true
                end
            end
        end
        return nil
    end
end

function omni.lib.find_recipe(itemname)
    if type(itemname) == "table" then
        return itemname
    elseif type(itemname) ~= "string" then
        return nil
    end
    for _, recipe in pairs(data.raw.recipe) do
        if omni.lib.recipe_result_contains(recipe.name, itemname) then
            return recipe
        end
    end
    -- log("Could not find "..item.."'s recipe prototype, check it's type.")
    return nil
end

function omni.lib.get_tech_name(recipename)
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, eff in pairs(tech.effects) do
                if eff.type == "unlock-recipe" and eff.recipe == recipename then
                    return tech.name
                end
            end
        end
    end
    return nil
end

function omni.lib.remove_recipe_all_techs(recipename)
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for i, eff in pairs(tech.effects) do
                if eff.type == "unlock-recipe" and eff.recipe == recipename then
                    table.remove(data.raw.technology[tech.name].effects, i)
                end
            end
        end
    end
end

function omni.lib.replace_recipe_all_techs(recipename, replacement)
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for i, eff in pairs(tech.effects) do
                if eff.type == "unlock-recipe" and eff.recipe == recipename then
                    eff.recipe = replacement
                end
            end
        end
    end
end

function omni.lib.enable_recipe(recipename)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        -- in some cases recipe.enabled does not exist at all...
        if recipe.enabled or not (recipe.normal or recipe.expensive) then
            recipe.enabled = true
        end
        if recipe.normal then recipe.normal.enabled = true end
        if recipe.expensive then recipe.expensive.enabled = true end
    end
end

function omni.lib.disable_recipe(recipename)
    local recipe = data.raw.recipe[recipename]
    if recipe then
        -- in some cases recipe.enabled does not exist at all...
        if recipe.enabled or not (recipe.normal or recipe.expensive) then
            recipe.enabled = false
        end
        if recipe.normal then recipe.normal.enabled = false end
        if recipe.expensive then recipe.expensive.enabled = false end
    end
end
