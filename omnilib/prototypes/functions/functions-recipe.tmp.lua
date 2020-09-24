

function omni.lib.add_recipe_ingredient(recipename, ingredient)
    local rec = data.raw.recipe[recipename]

    -- Recipe does not exist
    if not rec then return end

    local norm = {}
    local expens = {}

    if not ingredient.name then
        if type(ingredient) == "string" then
            norm = {type = "item", name = ingredient, amount = 1}
            expens = {type = "item", name = ingredient, amount = 1}
        elseif ingredient.normal or ingredient.expensive then
            if ingredient.normal then
                norm = {
                    type = ingredient.normal.type or "item",
                    name = ingredient.normal.name or ingredient.normal[1],
                    amount = ingredient.normal.amount or ingredient.normal[2] or
                        1
                }
            else
                norm = nil
            end
            if ingredient.expensive then
                expens = {
                    type = ingredient.expensive.type or "item",
                    name = ingredient.expensive.name or ingredient.expensive[1],
                    amount = ingredient.expensive.amount or
                        ingredient.expensive[2] or 1
                }
            else
                expens = nil
            end
        elseif ingredient[1].name then
            norm = ingredient[1]
            expens = ingredient[2]
        elseif type(ingredient[1]) == "string" then
            norm = {type = "item", name = ingredient[1], amount = ingredient[2]}
            expens = {
                type = "item",
                name = ingredient[1],
                amount = ingredient[2]
            }
        end
    else
        norm = ingredient
        expens = ingredient
    end

    -- Where to put the ingredients
    if not rec.ingredients then
        -- Do nothing, because there is no ingredients ?

    -- Else we insert the ingredient in the normal ingredients
    elseif norm and norm == expens then
        merge_ingredients(rec.ingredients, norm)

        -- There is a difference between norm and expensive ingredients, copy into .normal/.expensive
    elseif norm ~= expens then
        rec.normal = {}
        rec.expensive = {}

        -- Make normal recipe
        rec.normal.ingredients = table.deepcopy(rec.ingredients)

        -- Make expensive recipe
        rec.expensive.ingredients = table.deepcopy(rec.ingredients)

        -- Move results to normal/expensive recipes
        if rec.result then
            local results = {
                {
                    type = "item",
                    name = rec.result,
                    amount = rec.result_count or 1
                }
            }
            rec.normal.results = table.deepcopy(results)
            rec.expensive.results = table.deepcopy(results)
        elseif rec.results then
            rec.normal.results = table.deepcopy(rec.results)
            rec.expensive.results = table.deepcopy(rec.results)
        end

        -- Remove root attributes that have been moved
        rec.ingredients = nil
        rec.results = nil
        rec.result = nil
        rec.result_count = nil

        -- Merge ingredients
        merge_ingredients(rec.normal.ingredients, norm)
        merge_ingredients(rec.expensive.ingredients, expens)

    end
end