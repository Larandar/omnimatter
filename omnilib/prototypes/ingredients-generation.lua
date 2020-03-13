
BuildMat = {}
BuildMat.__index = BuildMat

component={}

component["vanilla-circuit"]={"electronic-circuit","advanced-circuit","processing-unit"}
component["crystallonics"]={"basic-crystallonic","basic-oscillo-crystallonic"}
component["vanilla-gear-wheel"] = {"iron-gear-wheel"}
component["bob-gear-wheel"] = {"iron-gear-wheel", "steel-gear-wheel", "brass-gear-wheel", "cobalt-steel-gear-wheel", "titanium-gear-wheel", "tungsten-gear-wheel", "nitinol-gear-wheel"}
component["vanilla-gear-box"]= {"omnicium-iron-gear-box"}
component["bob-gear-box"] = {"omnicium-iron-gear-box","omnicium-steel-gear-box","omnicium-brass-gear-box","omnicium-titanium-gear-box","omnicium-tungsten-gear-box","omnicium-nitinol-gear-box"}
component["vanilla-plate"]={"copper-plate","iron-plate"}
component["bob-plate"]={"iron-plate", "copper-plate", "tin-plate", "lead-plate", "silver-plate", "zinc-plate", "nickel-plate", "cobalt-plate", "gold-plate", "aluminium-plate", "tungsten-plate", "titanium-plate"}
component["angel-plate"]={"copper-plate","iron-plate","angels-plate-manganese", "angels-plate-chrome", "angels-plate-platinum"}
component["angel-bob-plate"]={"iron-plate", "copper-plate", "tin-plate", "lead-plate", "silver-plate", "zinc-plate", "nickel-plate", "cobalt-plate", "angels-plate-manganese", "gold-plate", "aluminium-plate", "tungsten-plate", "titanium-plate", "angels-plate-chrome", "angels-plate-platinum"}
component["vanilla-omniplate"]= {"omnicium-plate","omnicium-iron-alloy","omnicium-steel-alloy"}
component["bearing"]={"steel-bearing", nil, "cobalt-steel-bearing", "titanium-bearing", "nitinol-bearing", "ceramic-bearing"}
component["vanilla-pipe"] = {"pipe"}
component["bob-pipe"] = {"stone-pipe", "copper-pipe", "pipe", "bronze-pipe", "brass-pipe", "steel-pipe", "plastic-pipe", "ceramic-pipe", "titanium-pipe", "tungsten-pipe"}
component["bob-circuit"]={"basic-circuit-board","electronic-circuit","advanced-circuit","processing-unit","advanced-processing-unit","advanced-processing-unit"}
component["omni-alloys"] = {"omnicium-plate","omnicium-iron-alloy","omnicium-steel-alloy"}
component["omni-bob-alloys"] = {"omnicium-plate","omnicium-iron-alloy","omnicium-steel-alloy", "omnicium-aluminium-alloy", "omnicium-tungsten-alloy"}
component["bob-crystallo-circuit"]=omni.lib.union(omni.lib.cutTable(component["bob-circuit"],2),component["crystallonics"])
component["vanilla-crystallo-circuit"]=omni.lib.union(omni.lib.cutTable(component["vanilla-circuit"],2),component["crystallonics"])

if mods["bobelectronics"] then
	if mods["omnimatter_crystal"] then
		component["circuit"]=component["bob-crystallo-circuit"]
	else
		component["circuit"]=component["bob-circuit"]
	end
else
	if mods["omnimatter_crystal"] then	
		component["circuit"]=component["vanilla-crystallo-circuit"]
	else
		component["circuit"]=component["vanilla-circuit"]
	end
end

if mods["bobplates"] then
	component["gear-wheel"]=component["bob-gear-wheel"]
	component["gear-box"]=component["bob-gear-box"]
	component["omniplate"]=component["omni-bob-alloys"]
	component["pipe"]=component["bob-pipe"]
	if mods["angelssmelting"] then
		component["plates"]=component["angel-bob-plate"]
	else
		component["plates"]=component["bob-plate"]		
	end
else
	component["gear-wheel"]=component["vanilla-gear-wheel"]
	component["gear-box"]=component["vanilla-gear-box"]
	component["omniplate"]=component["vanilla-omniplate"]
	component["pipe"]=component["vanilla-pipe"]
	if mods["angelssmelting"] then
		component["plates"]=component["angel-plate"]
	else
		component["plates"]=component["vanilla-plate"]		
	end
end

local cmpn = {"vanilla-circuit","crystallonics","vanilla-gear-wheel","bob-gear-wheel","vanilla-gear-box","bob-gear-box","plate","bob-plate","angel-plate","angel-bob-plate",
"omni-plate","vanilla-pipe","bob-pipe","bob-circuit","omni-alloys","bob-crystallo-circuit","vanilla-crystallo-circuit"}

for _, c in pairs(cmpn) do
	--component[c]=setmetatable(component[c],BuildMat)
end


function OmniGen:building()
	self.type="building"
	return self
end
function OmniGen:addComponent(t)
	if type(t)=="string" then
		if component[t] then
			if self.comp then
				self.comp[#self.comp+1]=component[t]
			else
				self.comp={component[t]}
			end
		end
	elseif type(t)=="table" then
		for _,i in pairs(t) do
			if component[i] then
				if self.comp then
					self.comp[#self.comp+1]=component[i]
				else
					self.comp={component[i]}
				end
			end
		end
	end
	return self
end
function OmniGen:setMissConstant(c)
	if type(c)=="function" then
		self.miss = c
	elseif type(c)=="number" then
		self.miss=function(levels,grade) return c end
	end
	return self
end
function OmniGen:setQuant(kind,c,add)
	if not self.quant then self.quant = {} end
	if not self.comp then self.comp={kind} end
	if not omni.lib.is_in_table(kind,self.comp) then self.comp[#self.comp+1]=kind end
	self.shift[kind] = add
	if type(c)=="function" then
		self.quant[kind] = c
	elseif type(c)=="number" then
		self.quant[kind]=function(levels,grade) return c end
	elseif type(c)=="table" then
		self.quant[kind]=function(levels,grade) return c[grade] or c[#c] end
	end
	return self
end
function OmniGen:setPreRequirement(c)
	if type(c)=="table" then
		self.prereq = c
	elseif type(c)=="string" then
		self.prereq = {name=c,type="item",amount=1}
	end
	return self
end
function OmniGen:buildingCost()
	return function(levels,grade)
		local ing = {}
		if self.prereq and grade == 1 then
			ing[#ing+1]=self.prereq
		end
		for _, part in pairs(self.comp) do
			local amount = self.quant[part](levels,grade)
			for i=grade,1,-1 do
				if i+(self.shift[part] or 0) > 0 and component[part] and component[part][i+(self.shift[part] or 0)]~="" and component[part][i+(self.shift[part] or 0)]~=nil then
					ing[#ing+1]={type="item",name=component[part][i+(self.shift[part] or 0)],amount=omni.lib.round(amount)}
					break
				else
					amount = self.miss(levels,grade)*amount
				end
			end
		end
		return ing
	end
end