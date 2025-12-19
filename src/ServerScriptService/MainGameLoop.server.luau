local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")

-- 引入配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- 事件引用
local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")
local StartLocation = Workspace:WaitForChild("TutorialStartLocation")
local ZombieSpawnPoint = Workspace:FindFirstChild("ZombieSpawnPoint")

-- [修复 1] 统一使用新的 DataStore 名称，与 PlayerDataSetup 保持一致
local DATA_STORE_NAME = "Player_Data_V3_Exp" 
local PlayerDataStore
pcall(function()
	PlayerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

local PlayerStats = {} 

-- =============================================
-- 1. 玩家数据管理
-- =============================================
Players.PlayerAdded:Connect(function(player)
	local success, savedData
	if PlayerDataStore then
		success, savedData = pcall(function() return PlayerDataStore:GetAsync("User_"..player.UserId) end)
	end

	if success and savedData then
		PlayerStats[player.UserId] = savedData

		-- [修复 2] 数据迁移保险：如果读取的是旧数据(无Exp)，强制初始化为0
		if PlayerStats[player.UserId].Exp == nil then
			PlayerStats[player.UserId].Exp = PlayerStats[player.UserId].XP or 0
		end
		-- 确保 LabInventory 存在
		if PlayerStats[player.UserId].LabInventory == nil then
			PlayerStats[player.UserId].LabInventory = {}
		end
	else
		-- 初始化新数据
		PlayerStats[player.UserId] = { Exp = 0, BioMatter = 0, LabInventory = {} }
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		if character.PrimaryPart then
			character:SetPrimaryPartCFrame(StartLocation.CFrame)
		else
			character:MoveTo(StartLocation.Position)
		end
	end)

	task.wait(2)
	TutorialEvent:FireClient(player, "StartObjective1")
	if PlayerStats[player.UserId] then
		TutorialEvent:FireClient(player, "UpdateBioMatter", PlayerStats[player.UserId].BioMatter)
		TutorialEvent:FireClient(player, "UpdateExp", PlayerStats[player.UserId].Exp)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	-- [优化] MainGameLoop 不再负责保存，交给 PlayerDataSetup 统一保存，防止冲突
	-- 这里只清理内存表
	PlayerStats[player.UserId] = nil
end)

-- =============================================
-- 2. 辅助函数：生成掉落物
-- =============================================
local function SpawnLoot(name, position, count, player, colorInfo)
	local lootFolder = ServerStorage:FindFirstChild("LootItems")
	local itemTemplate = lootFolder and lootFolder:FindFirstChild(name)

	if not itemTemplate then
		itemTemplate = Instance.new("Part")
		itemTemplate.Name = name
		itemTemplate.Size = Vector3.new(1, 1, 1)
		itemTemplate.CanCollide = true
		itemTemplate.Anchored = false
		itemTemplate.Shape = Enum.PartType.Ball
	end

	for i = 1, count do
		local loot = itemTemplate:Clone()
		loot.Position = position + Vector3.new(math.random(-3,3), 5, math.random(-3,3))
		loot.Parent = workspace

		if colorInfo then
			if typeof(colorInfo) == "Color3" then
				loot.Color = colorInfo
			elseif GameConfig.RarityColors and GameConfig.RarityColors[colorInfo] then
				loot.Color = GameConfig.RarityColors[colorInfo]
			elseif colorInfo == "Red" then
				loot.Color = Color3.fromRGB(255, 50, 50)
			elseif colorInfo == "Blue" then
				loot.Color = Color3.fromRGB(0, 170, 255)
			elseif colorInfo == "Green" then
				loot.Color = Color3.fromRGB(75, 180, 75)
			end
		end

		if loot:IsA("BasePart") then
			loot.Anchored = false
			loot.CanCollide = true
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Loot"
		prompt.ActionText = "Pick up " .. name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.Parent = loot

		prompt.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer == player then
				if PlayerStats[player.UserId] then
					table.insert(PlayerStats[player.UserId].LabInventory, name)
				end

				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					local tool = Instance.new("Tool")
					tool.Name = name
					tool.RequiresHandle = false
					tool.Parent = backpack
					tool.ToolTip = name .. " x1"
				end

				TutorialEvent:FireClient(player, "LootPickedUp", name)
				loot:Destroy()
			end
		end)

		Debris:AddItem(loot, 60)
	end
end

-- =============================================
-- 3. 辅助函数：生成指定僵尸
-- =============================================
local function SpawnSpecificZombie(player, zombieType, offset)
	local config = GameConfig.Mobs[zombieType]
	if not config then 
		warn("❌ GameConfig 中找不到怪物配置: " .. tostring(zombieType))
		return 
	end

	local enemyFolder = ServerStorage:FindFirstChild("Enemies")
	local zombieTemplate = enemyFolder and enemyFolder:FindFirstChild("EliteZombie")

	if zombieTemplate then
		local zombie = zombieTemplate:Clone()
		zombie.Name = config.Name
		zombie.Parent = workspace

		if player.Character then
			local pivot = player.Character:GetPivot()
			zombie:PivotTo(pivot * CFrame.new(offset, 0, -20))
		end

		local humanoid = zombie:WaitForChild("Humanoid")
		humanoid.MaxHealth = config.HP
		humanoid.Health = config.HP

		if config.OutlineColor then
			local hl = Instance.new("Highlight")
			hl.FillTransparency = 1
			hl.OutlineColor = config.OutlineColor
			hl.Parent = zombie
		end

		TutorialEvent:FireClient(player, "MarkZombie", zombie)

		humanoid.Died:Connect(function()
			print("💀 " .. config.Name .. " 已死亡")

			-- [修复 3] 使用 (config.XP or 0) 防止配置缺失报错
			local xpReward = config.XP or 0
			local bioReward = config.BioMatterDrop or 0

			-- 更新内存数据
			if PlayerStats[player.UserId] then
				local stats = PlayerStats[player.UserId]
				-- 确保 stats.Exp 不是 nil
				stats.Exp = (stats.Exp or 0) + xpReward
				stats.BioMatter = (stats.BioMatter or 0) + bioReward

				TutorialEvent:FireClient(player, "UpdateBioMatter", stats.BioMatter)
				TutorialEvent:FireClient(player, "UpdateExp", stats.Exp)
			end

			-- 同步更新 Leaderstats
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local bioVal = leaderstats:FindFirstChild("Biomass")
				if bioVal then bioVal.Value = bioVal.Value + bioReward end

				local expVal = leaderstats:FindFirstChild("Exp")
				if expVal then expVal.Value = expVal.Value + xpReward end
			end

			-- 生成掉落物
			local dropPos = zombie:GetPivot().Position
			if config.Drops then
				for _, dropData in ipairs(config.Drops) do
					SpawnLoot(dropData.ItemName, dropPos, dropData.Amount, player, dropData.Rarity or dropData.Color)
				end
			end

			Debris:AddItem(zombie, 5)
		end)
	end
end

-- =============================================
-- 4. 事件监听
-- =============================================
TutorialEvent.OnServerEvent:Connect(function(player, action, data)
	if action == "GiveWeapon" then
		local weaponFolder = ServerStorage:FindFirstChild("WeaponTools")
		if weaponFolder then
			local weapon = weaponFolder:FindFirstChild(data)
			if weapon then
				weapon:Clone().Parent = player.Backpack
				weapon:Clone().Parent = player.StarterGear
			end
		end

	elseif action == "SpawnZombie" then
		print("🧟 服务器：正在生成僵尸波次...")
		if not ZombieSpawnPoint then 
			SpawnSpecificZombie(player, "Normal Zombie", -6)
			SpawnSpecificZombie(player, "Elite Zombie", 6)
		else
			SpawnSpecificZombie(player, "Normal Zombie", -6)
			SpawnSpecificZombie(player, "Elite Zombie", 6)
		end
	end
end)