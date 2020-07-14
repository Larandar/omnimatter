if mods["omnimatter_crystal"] then
	RecGen:create("omnimatter_science","omni-pack"):
		tool():
		setStacksize(200):
		setDurability(1):
		setIcons("__base__/graphics/icons/production-science-pack.png"):
		setDurabilityDesc("description.science-pack-remaining-amount"):
		setEnergy(5):
		addProductivity():
		setTechName("omnipack-technology"):
		setTechCost(150):
		setTechIcon("omnipack-tech"):
		setTechPacks(2):
		setTechPrereq("omnitractor-electric-2"):
		setTechTime(20):
		extend()
		
	TechGen:import("chemical-science-pack"):addPrereq("omnipack-technology"):extend()
end