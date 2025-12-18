-- Script: PlayerDataSetup (在 ServerScriptService 中，现在处理存档/读档)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- !!! 配置: 数据存储名 !!!
-- 每次修改数据结构时，建议更改版本号，以防数据冲突。
local DATA_STORE_NAME = "Player_Biomass_MTC_V2" 
local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

-- !!! 配置: 默认数据 (新玩家) !!!
local DEFAULT_DATA = {
	Biomass = 0, -- 新玩家初始生物质 (用于测试)
	MTC = 0      -- 新玩家初始元币
}

-- [函数 1: 数据加载和Leaderstats设置]
local function loadPlayerData(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" 
	leaderstats.Parent = player

	local biomassStat = Instance.new("IntValue")
	biomassStat.Name = "Biomass" 
	biomassStat.Parent = leaderstats

	local mtcStat = Instance.new("IntValue")
	mtcStat.Name = "MTC" 
	mtcStat.Parent = leaderstats

	local userId = "User_" .. player.UserId
	local loadedData

	-- 尝试加载数据
	local success, err = pcall(function()
		loadedData = dataStore:GetAsync(userId)
	end)

	if success and loadedData then
		-- 加载成功：使用存档数据
		biomassStat.Value = loadedData.Biomass or DEFAULT_DATA.Biomass
		mtcStat.Value = loadedData.MTC or DEFAULT_DATA.MTC
		print(player.Name .. "：数据加载成功。")
	else
		-- 加载失败或无存档：使用默认数据
		biomassStat.Value = DEFAULT_DATA.Biomass
		mtcStat.Value = DEFAULT_DATA.MTC
		print(player.Name .. "：无存档或加载失败，使用默认数据。")
		if not success then
			warn("数据加载时出现错误：" .. err)
		end
	end
end

-- [函数 2: 退出时自动保存数据]
local function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	-- 确保 leaderstats 存在
	if not leaderstats then
		warn("退出时找不到 Leaderstats，无法保存：" .. player.Name)
		return
	end

	local biomassStat = leaderstats:FindFirstChild("Biomass")
	local mtcStat = leaderstats:FindFirstChild("MTC")

	-- 确保两个统计数据都存在
	if not biomassStat or not mtcStat then
		warn("退出时找不到 Biomass 或 MTC，无法保存：" .. player.Name)
		return
	end

	local dataToSave = {
		Biomass = biomassStat.Value,
		MTC = mtcStat.Value
	}

	local userId = "User_" .. player.UserId

	-- 尝试保存数据
	local success, err = pcall(function()
		dataStore:SetAsync(userId, dataToSave)
	end)

	if success then
		print(player.Name .. "：数据保存成功。")
	else
		warn(player.Name .. "：数据保存失败！错误：" .. err)
	end
end

-- [连接事件]
Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)