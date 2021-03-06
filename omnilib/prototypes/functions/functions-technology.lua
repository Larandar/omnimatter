function omni.lib.add_unlock_recipe(tech, recipe,force)
	local found = false
	if data.raw.technology[tech] and (data.raw.recipe[recipe] or force) then
		if data.raw.technology[tech].effects then
			for _,eff in pairs(data.raw.technology[tech].effects) do
				if eff.type == "unlock-recipe" and eff.recipe == recipe then
					found = true
					break
				end
			end
		else
			data.raw.technology[tech].effects = {}
		end
		if not found then
			table.insert(data.raw.technology[tech].effects,{type="unlock-recipe",recipe = recipe})
			omni.lib.disable_recipe(recipe)
			return
		end	
	else
		--log("cannot add recipe to "..tech.." as it doesn't exist")
	end
end

function omni.lib.remove_unlock_recipe(tech, recipe)
	local res = {}
	if tech then
		for _,eff in pairs(data.raw.technology[tech].effects or {}) do
			if eff.type == "unlock-recipe" and eff.recipe ~= recipe then
				res[#res+1]=eff
			end
		end
		data.raw.technology[tech].effects=res
	end
end
function omni.lib.replace_unlock_recipe(tech, recipe,new)
	local res = {}
	for _,eff in pairs(data.raw.technology[tech].effects) do
		if eff.type == "unlock-recipe" and eff.recipe == recipe then
			eff.recipe=new
		end
	end
	--data.raw.technology[tech].effects=res
end

function omni.lib.replace_science_pack(tech,old, new)
	local r = new
	if not r then r = "omni-pack" end
	if data.raw.technology[tech] then
		for i,ing in pairs(data.raw.technology[tech].unit.ingredients) do
			if ing.name and ing.name == old then
				ing.name = r
			elseif ing[1] == old then
				ing[1] = r
			end
		end
	else
		log(tech.." cannot be found, replacement of "..old.." with "..r.." has failed.")
	end
end

function omni.lib.add_science_pack(tech,pack)
	if data.raw.technology[tech] then
		local found = false
		for __,sp in pairs(data.raw.technology[tech].unit.ingredients) do
			for __,ing in pairs(sp) do
				if ing == pack then found=true end
			end
		end
		if not found then
			if type(pack) == "table" then
				table.insert(data.raw.technology[tech].unit.ingredients,pack)
			elseif type(pack) == "string" then
				table.insert(data.raw.technology[tech].unit.ingredients,{type = "item", name = pack, amount = 1})
			elseif type(pack)=="number" then
				table.insert(data.raw.technology[tech].unit.ingredients,{type = "item", name = "omni-pack", amount = pack})
			else
				table.insert(data.raw.technology[tech].unit.ingredients,{type = "item", name = "omni-pack", amount = 1})
			end
		else
			log("Ingredient "..pack.." already exists.")
		end
	else
		log("Cannot find "..tech..", ignoring it.")
	end
end

function omni.lib.remove_science_pack(tech,pack)
	if data.raw.technology[tech] then
		for i,ing in pairs(data.raw.technology[tech].unit.ingredients) do
			if ing[1]==pack then
				table.remove(data.raw.technology[tech].unit.ingredients,i)
			end
		end
	else
		log("Can not find tech "..tech.." to replace science pack "..pack)
	end
end

function omni.lib.replace_prerequisite(tech,old, new)
	if data.raw.technology[tech] and data.raw.technology[tech].prerequisites then
		for i,req in pairs(data.raw.technology[tech].prerequisites) do
			if req==old then
				data.raw.technology[tech].prerequisites[i]=new
			end
		end
	else
		log("Can not find tech "..tech.." to replace prerequisite "..old.." with "..new)
	end
end

function omni.lib.remove_prerequisite(tech,prereq)
	if data.raw.technology[tech] and data.raw.technology[tech].prerequisites then
		local pr={}
		for i,req in pairs(data.raw.technology[tech].prerequisites) do
			if req~=prereq then
				pr[#pr+1]=req
			end
		end
		data.raw.technology[tech].prerequisites=pr
	else
		log("Can not find tech "..tech.." to remove prerequisite "..prereq)
	end
end

function omni.lib.set_prerequisite(tech, req)
	if data.raw.technology[tech] then
		if type(req) == "table" then
			data.raw.technology[tech].prerequisites = req
		else
			data.raw.technology[tech].prerequisites = {req}
		end
	else
		log("Can not find tech "..tech.." to set prerequisite "..prereq)
	end
end

--Add a prerequisite to a tech, force will jump checks if that prereq exists
function omni.lib.add_prerequisite(tech, req, force)
	local found = nil
	--check that the table exists, or create a blank one
	if data.raw.technology[tech] then
		if not data.raw.technology[tech].prerequisites then
			data.raw.technology[tech].prerequisites = {}
		end
	end
	if type(req) == "table" then
		for _,r in pairs(req) do
			if data.raw.technology[r] or force then
				for i,prereq in pairs(data.raw.technology[tech].prerequisites) do
					if prereq == r then found = 1 end
				end
				if not found then
					table.insert(data.raw.technology[tech].prerequisites,r)
				else
					log("Prerequisite "..r.." already exists")
				end
				found = nil
			end
		end
	elseif req and (data.raw.technology[req] or force) then
		if data.raw.technology[tech] then
			for i,prereq in pairs(data.raw.technology[tech].prerequisites) do
				if prereq == req then found = 1 end
			end
			if not found then
				table.insert(data.raw.technology[tech].prerequisites,req)
			else
				log("Prerequisite "..req.." already exists")
			end
		else
			log(tech.." does not exist, please check spelling.")
		end
	else
		log("There is no prerequisities to add to "..tech)
	end
end