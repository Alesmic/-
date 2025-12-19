-- Script: PlayerDataSetup (在 ServerScriptService 中)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- !!! 配置: 数据存储名 !!!
local DATA_STORE_NAME = "Player_Data_V3_Exp" -- 建议更新版本号以防数据冲突
local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

-- !!! 配置: 默认数据 !!!
local DEFAULT_DATA = {
	Biomass = 0, 
	MTC = 0,
	Exp = 0 -- [新增] 默认经验值
}

-- [函数 1: 数据加载和Leaderstats设置]
local function loadPlayerData(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" 
	leaderstats.Parent = player

	-- 1. 生物质
	local biomassStat = Instance.new("IntValue")
	biomassStat.Name = "Biomass" 
	biomassStat.Parent = leaderstats

	-- 2. 元币 (MTC)
	local mtcStat = Instance.new("IntValue")
	mtcStat.Name = "MTC" 
	mtcStat.Parent = leaderstats

	-- 3. [新增] 经验值 (Exp)
	local expStat = Instance.new("IntValue")
	expStat.Name = "Exp" -- 名字改为 Exp
	expStat.Parent = leaderstats

	local userId = "User_" .. player.UserId
	local loadedData

	local success, err = pcall(function()
		loadedData = dataStore:GetAsync(userId)
	end)

	if success and loadedData then
		biomassStat.Value = loadedData.Biomass or DEFAULT_DATA.Biomass
		mtcStat.Value = loadedData.MTC or DEFAULT_DATA.MTC
		expStat.Value = loadedData.Exp or DEFAULT_DATA.Exp -- 读取 Exp
		print(player.Name .. "：数据加载成功。")
	else
		biomassStat.Value = DEFAULT_DATA.Biomass
		mtcStat.Value = DEFAULT_DATA.MTC
		expStat.Value = DEFAULT_DATA.Exp
		print(player.Name .. "：无存档，使用默认数据。")
	end
end

-- [函数 2: 退出时自动保存]
local function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local biomassStat = leaderstats:FindFirstChild("Biomass")
	local mtcStat = leaderstats:FindFirstChild("MTC")
	local expStat = leaderstats:FindFirstChild("Exp") -- 获取 Exp

	if biomassStat and mtcStat and expStat then
		local dataToSave = {
			Biomass = biomassStat.Value,
			MTC = mtcStat.Value,
			Exp = expStat.Value -- 保存 Exp
		}

		local userId = "User_" .. player.UserId
		local success, err = pcall(function()
			dataStore:SetAsync(userId, dataToSave)
		end)

		if success then
			print(player.Name .. "：数据保存成功。")
		else
			warn(player.Name .. "：数据保存失败！" .. tostring(err))
		end
	end
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)