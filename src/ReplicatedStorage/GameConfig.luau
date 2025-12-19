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

return GameConfig