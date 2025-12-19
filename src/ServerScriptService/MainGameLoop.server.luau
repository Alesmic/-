local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")
local StartLocation = Workspace:WaitForChild("TutorialStartLocation")
-- 使用 FindFirstChild 防止如果没有这个点导致脚本卡死
local ZombieSpawnPoint = Workspace:FindFirstChild("ZombieSpawnPoint")

-- 安全获取 DataStore (防止未开启 API Access 导致脚本报错停止)
local PlayerDataStore
pcall(function()
	PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
end)

if not PlayerDataStore then
	warn("⚠️ 警告: DataStore 未加载。请在 Game Settings -> Security 中开启 'Enable Studio Access to API Services'，否则数据无法保存。")
end

-- 玩家数据模拟 (XP 和 生物残渣)
local PlayerStats = {} 

-- 1. 玩家加入
Players.PlayerAdded:Connect(function(player)
	local success, savedData
	-- 只有当 DataStore 成功加载时才尝试读取
	if PlayerDataStore then
		success, savedData = pcall(function()
			return PlayerDataStore:GetAsync(tostring(player.UserId))
		end)
	end

	if success and savedData then
		PlayerStats[player.UserId] = savedData
		print("✅ 成功加载玩家数据")
	else
		PlayerStats[player.UserId] = { XP = 0, BioMatter = 0, LabInventory = {} } -- 初始化数据
	end

	player.CharacterAdded:Wait()
	local character = player.Character

	if character and character.PrimaryPart then
		character:SetPrimaryPartCFrame(StartLocation.CFrame)
	else
		character:MoveTo(StartLocationwa.Position)
	end

	task.wait(1.5)
	TutorialEvent:FireClient(player, "StartObjective1")
	-- 初始 UI 更新
	TutorialEvent:FireClient(player, "UpdateBioMatter", PlayerStats[player.UserId].BioMatter)
	TutorialEvent:FireClient(player, "UpdateXP", PlayerStats[player.UserId].XP)
end)

-- 玩家离开时保存数据
Players.PlayerRemoving:Connect(function(player)
	local data = PlayerStats[player.UserId]
	if data and PlayerDataStore then
		pcall(function()
			PlayerDataStore:SetAsync(tostring(player.UserId), data)
		end)
	end
	PlayerStats[player.UserId] = nil
end)

-- 服务器关闭时保存所有数据 (防止数据丢失)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerStats[player.UserId]
		if data and PlayerDataStore then
			pcall(function()
				PlayerDataStore:SetAsync(tostring(player.UserId), data)
			end)
		end
	end
end)

-- 辅助函数：生成掉落物
local function SpawnLoot(name, position, count, player)
	local lootFolder = ServerStorage:FindFirstChild("LootItems")
	local itemTemplate = lootFolder and lootFolder:FindFirstChild(name)

	if not itemTemplate then 
		warn("❌ 找不到掉落物模板："..name .. " (请检查 ServerStorage/LootItems)") 
		return 
	end

	for i = 1, count do
		local loot = itemTemplate:Clone()
		-- 随机散落在尸体周围
		loot.Position = position + Vector3.new(math.random(-3,3), 2, math.random(-3,3))
		loot.Parent = workspace

		-- 确保掉落物有物理碰撞，不会掉出世界
		if loot:IsA("BasePart") then
			loot.Anchored = false
			loot.CanCollide = true
		end

		-- 添加拾取逻辑 (Touch)
		local pickedUp = false
		loot.Touched:Connect(function(hit)
			if pickedUp then return end
			local char = hit.Parent
			local hitPlayer = Players:GetPlayerFromCharacter(char)

			if hitPlayer == player then
				pickedUp = true
				print("📦 玩家捡起了: " .. name)

				-- 存入实验台库存
				table.insert(PlayerStats[player.UserId].LabInventory, name)

				-- 检查背包或手中是否已有该物品 (用于堆叠)
				local existingTool = player.Backpack:FindFirstChild(name)
				if not existingTool and player.Character then
					existingTool = player.Character:FindFirstChild(name)
				end

				if existingTool then
					-- 情况 A: 已有物品，进行堆叠
					local currentStack = existingTool:GetAttribute("Stack") or 1
					local newStack = currentStack + 1
					existingTool:SetAttribute("Stack", newStack)
					existingTool.ToolTip = name .. " x" .. newStack -- 更新鼠标悬停提示

					loot:Destroy() -- 销毁地上的物体
				else
					-- 情况 B: 新物品，放入背包
					local tool
					if loot:IsA("Tool") then
						tool = loot
						tool.Parent = player.Backpack
					else
						-- 如果掉落物只是 Part，创建一个 Tool 容器放入背包
						tool = Instance.new("Tool")
						tool.Name = name
						tool.RequiresHandle = false -- 不需要手持模型，仅作为物品栏图标
						tool.Parent = player.Backpack

						loot:Destroy()
					end

					-- 初始化堆叠数据
					tool:SetAttribute("Stack", 1)
					tool.ToolTip = name .. " x1"
				end

				-- 通知客户端拾取进度
				TutorialEvent:FireClient(player, "LootPickedUp", 1) 
			end
		end)
	end
end

-- 2. 事件监听
TutorialEvent.OnServerEvent:Connect(function(player, action, data)
	-- 发武器 (Objective 1)
	if action == "GiveWeapon" then
		local weaponFolder = ServerStorage:FindFirstChild("WeaponTools")
		if weaponFolder then
			local weapon = weaponFolder:FindFirstChild(data)
			if weapon then
				weapon:Clone().Parent = player.Backpack
				weapon:Clone().Parent = player.StarterGear
			end
		end

		-- 生成僵尸 (Objective 2)
	elseif action == "SpawnZombie" then
		print("🧟 服务器：正在生成精英僵尸...")

		if not ZombieSpawnPoint then
			warn("❌ 错误：Workspace 里没有 ZombieSpawnPoint，无法定位僵尸位置")
			return
		end

		local enemyFolder = ServerStorage:FindFirstChild("Enemies")
		local zombieTemplate = enemyFolder and enemyFolder:FindFirstChild("EliteZombie")

		if zombieTemplate then
			local zombie = zombieTemplate:Clone()
			zombie.Parent = workspace

			-- 🛑 自动修复 PrimaryPart (防止移动报错)
			if not zombie.PrimaryPart then
				local root = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso") or zombie:FindFirstChild("Head")
				if root then zombie.PrimaryPart = root end
			end

			-- 移动僵尸
			if zombie.PrimaryPart then
				zombie:SetPrimaryPartCFrame(ZombieSpawnPoint.CFrame)
			else
				zombie:MoveTo(ZombieSpawnPoint.Position)
			end

			-- 通知客户端标记这个僵尸 (加箭头)
			TutorialEvent:FireClient(player, "MarkZombie", zombie)

			-- 监听僵尸死亡
			local humanoid = zombie:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					print("💀 僵尸已死亡！发放奖励...")

					-- 1. 加 XP 和 生物残渣
					local stats = PlayerStats[player.UserId]
					stats.XP = stats.XP + 300
					stats.BioMatter = stats.BioMatter + 3
					print("玩家获得 300 XP, 当前总量: " .. stats.XP)

					-- 更新客户端 UI
					TutorialEvent:FireClient(player, "UpdateBioMatter", stats.BioMatter)
					TutorialEvent:FireClient(player, "UpdateXP", stats.XP)

					-- 2. 掉落物品 (🛑 修复点：使用更安全的方式获取位置)
					local dropPos = zombie:GetPivot().Position -- 这样写无论有没有RootPart都能找到位置

					SpawnLoot("CommonExtract", dropPos, 3, player) -- 3个普通
					SpawnLoot("RareExtract", dropPos, 2, player)   -- 2个罕见

					-- 3. 清理尸体 (延迟)
					game:GetService("Debris"):AddItem(zombie, 5)
				end)
			end
		else
			warn("❌ 错误：ServerStorage/Enemies 里没找到 EliteZombie 模型！")
		end
	end
end)