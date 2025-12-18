local GameConfig = {}

-- ==========================================
-- 1. 稀有度颜色配置 (用于 UI 与 掉落物图标)
-- ==========================================
GameConfig.RarityColors = {
	["Common"] = Color3.fromRGB(150, 150, 150),   -- 灰色 [cite: 1]
	["Uncommon"] = Color3.fromRGB(75, 180, 75),   -- 绿色 [cite: 45]
	["Rare"] = Color3.fromRGB(0, 170, 255),       -- 蓝色 [cite: 1]
	["Epic"] = Color3.fromRGB(170, 0, 255),       -- 紫色 [cite: 1]
	["Legendary"] = Color3.fromRGB(255, 170, 0)   -- 橙色 [cite: 1]
}

-- ==========================================
-- 2. 货币与回收配置 ($MTC 计数器)
-- ==========================================
GameConfig.Economy = {
	-- 回收生物质的价值：每 1 单位生物质兑换 100 $MTC
	BioMatterValue = 100, -- 教学目标 #3：100 MTC per salvage [cite: 62]
}

-- ==========================================
-- 3. 掉落物配置 (生物质与提取物)
-- ==========================================
GameConfig.Mobs = {
	-- 教学 Elite Zombie 掉落配置
	["Elite Zombie"] = {
		Name = "Elite Zombie", -- [cite: 35]

		-- 击杀后获得的生物质回收件数量
		BioMatterDrop = 3, -- 教学目标 #2：获得 3 bio-matter salvage [cite: 42]

		-- 教学目标 #2：掉落物清单 (提取物)
		Drops = {
			{ 
				ItemName = "Common Super-Soldier Extract", 
				Rarity = "Common", 
				Amount = 3  -- 3个白色(Common)提取物 [cite: 45]
			},
			{ 
				ItemName = "Uncommon Super-Soldier Extract", 
				Rarity = "Uncommon", 
				Amount = 2  -- 2个绿色(Uncommon)提取物 [cite: 45]
			}
		}
	}
}

-- 定义僵尸类型
GameConfig.Zombies = {
	Normal = {
		Name = "Normal Zombie",
		HP = 50,
		XP = 50,
		OutlineColor = Color3.fromRGB(0, 100, 255), -- 蓝色描边
		Scale = 1.0,
		Drops = {
			{Name = "CommonExtract", Color = "Blue", Count = 2},  -- 掉2个蓝色
			{Name = "RareExtract",   Color = "Green", Count = 1}, -- 掉1个绿色
		}
	},
	Elite = {
		Name = "Elite Zombie",
		HP = 150,
		XP = 300,
		OutlineColor = Color3.fromRGB(255, 0, 0), -- 红色描边
		Scale = 1.2, -- 精英怪稍微大一点
		Drops = {
			{Name = "Biomass", Color = "Red", Count = 2} -- 掉2个红色生物质
		}
	}
}

-- 计算总共需要捡多少个物品才能通关 (自动计算)
function GameConfig.GetTotalLootCount()
	local total = 0
	for _, data in pairs(GameConfig.Zombies) do
		for _, drop in ipairs(data.Drops) do
			total = total + drop.Count
		end
	end
	return total
end

return GameConfig