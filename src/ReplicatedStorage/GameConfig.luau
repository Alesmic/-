local GameConfig = {}

-- ==========================================
-- 1. 基础设置 (颜色与稀有度)
-- ==========================================
GameConfig.RarityColors = {
	["Common"]    = Color3.fromRGB(150, 150, 150), -- 灰色
	["Uncommon"]  = Color3.fromRGB(75, 180, 75),   -- 绿色
	["Rare"]      = Color3.fromRGB(0, 170, 255),   -- 蓝色
	["Epic"]      = Color3.fromRGB(170, 0, 255),   -- 紫色
	["Legendary"] = Color3.fromRGB(255, 170, 0)    -- 橙色
}

-- ==========================================
-- 2. 经济系统 ($MTC 与 回收)
-- ==========================================
GameConfig.Economy = {
	BioMatterValue = 100,  -- 生物质回收单价
	StartingMTC    = 0,    -- 初始金钱
	StartingBio    = 0     -- 初始生物质
}

-- ==========================================
-- 3. 玩家属性配置
-- ==========================================
GameConfig.Player = {
	MaxHealth = 100,
	WalkSpeed = 16,
	RunSpeed = 24,       -- Shift 跑步速度
	JumpPower = 50,
	RespawnTime = 5      -- 重生等待时间
}

-- ==========================================
-- 4. 武器属性配置 (Damage & Stats)
-- ==========================================
GameConfig.Weapons = {
	["Sword"] = {
		Name = "Knight's Sword",
		BaseDamage = 10,
		SlashDamage = 25,
		LungeDamage = 40,
		Cooldown = 0.5,
		Description = "Speed: Medium\nDamage: Balanced"
	},
	["Axe"] = {
		Name = "Heavy Axe",
		BaseDamage = 15,
		SlashDamage = 35,
		LungeDamage = 50,
		Cooldown = 1.0,
		Description = "Speed: Slow\nDamage: High"
	},
	["Bow"] = {
		Name = "Elven Bow",
		BaseDamage = 20,    -- 蓄力满伤害
		HeadshotMult = 1.5, -- 爆头倍率
		Cooldown = 0.8,
		Description = "Speed: Fast\nDamage: Low"
	}
}

-- ==========================================
-- 5. 生物与掉落配置 (Mobs & Drops)
-- ==========================================
GameConfig.Mobs = {
	["Normal Zombie"] = {
		Name = "Normal Zombie",
		HP = 50,
		XP = 50,
		BioMatterDrop = 1,
		OutlineColor = Color3.fromRGB(0, 100, 255), -- 蓝色描边
		Drops = {
			{ ItemName = "CommonExtract", Rarity = "Common", Amount = 1, Chance = 1.0 }
		}
	},
	["Elite Zombie"] = {
		Name = "Elite Zombie",
		HP = 150,
		XP = 300,            -- 击杀经验
		BioMatterDrop = 3,   -- 击杀生物质
		OutlineColor = Color3.fromRGB(255, 0, 0),   -- 红色描边

		-- 掉落物列表
		Drops = {
			{ 
				ItemName = "CommonExtract", 
				Rarity = "Common", 
				Amount = 3,  --
				Color = "Blue"
			},
			{ 
				ItemName = "RareExtract", 
				Rarity = "Rare", 
				Amount = 2,  --
				Color = "Green"
			}
		}
	}
}

-- ==========================================
-- 6. 辅助函数
-- ==========================================
function GameConfig.GetTotalLootCount()
	local total = 0
	for _, mob in pairs(GameConfig.Mobs) do
		if mob.Drops then
			for _, drop in ipairs(mob.Drops) do
				total = total + drop.Amount
			end
		end
	end
	return total
end

return GameConfig