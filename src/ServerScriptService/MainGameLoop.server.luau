local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- 引入配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- 事件引用
local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")
local ToggleWaypointEvent = ReplicatedStorage:WaitForChild("ToggleWaypointEvent")

-- 预制件引用
local ZombieTemplate = game.ServerStorage.Enemies:WaitForChild("EliteZombie")
local LootTemplate = game.ServerStorage:FindFirstChild("LootPart") 
-- 注意：如果 ServerStorage 里没有 LootPart，请创建一个简单的 Part 叫 "LootPart" 并放入 ServerStorage

-- [修改后的掉落生成函数：支持颜色]
local function SpawnLoot(itemName, position, count, player, colorType)
	for i = 1, count do
		local loot = LootTemplate:Clone()
		if not loot then -- 如果没有模板，创建一个临时的
			loot = Instance.new("Part")
			loot.Size = Vector3.new(1, 1, 1)
			loot.Anchored = false
			loot.CanCollide = true
			loot.Shape = Enum.PartType.Ball
		end

		loot.Name = itemName
		-- 随机散开一点
		loot.Position = position + Vector3.new(math.random(-3,3), 5, math.random(-3,3))
		loot.Parent = workspace

		-- 设置颜色
		if colorType == "Red" then
			loot.Color = Color3.fromRGB(255, 50, 50)     -- 红色 (生物质)
		elseif colorType == "Green" then
			loot.Color = Color3.fromRGB(50, 255, 50)     -- 绿色
		else
			loot.Color = Color3.fromRGB(50, 150, 255)    -- 蓝色 (普通提取物)
		end

		-- 添加接近提示 (E键拾取)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Loot"
		prompt.ActionText = "Pick up " .. itemName
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.Parent = loot

		prompt.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer == player then
				-- 发送捡起事件给客户端 (包含名字，用于弹窗)
				TutorialEvent:FireClient(player, "LootPickedUp", itemName)
				loot:Destroy()
			end
		end)

		Debris:AddItem(loot, 60) -- 60秒后自动消失
	end
end

-- [修改后的生成单个僵尸函数]
local function SpawnSpecificZombie(player, zombieType, offset)
	local config = GameConfig.Zombies[zombieType]
	if not config then return end

	local zombie = ZombieTemplate:Clone()
	zombie.Name = config.Name
	zombie.Parent = workspace

	-- 1. 设置位置 (在玩家前方 + 偏移)
	local character = player.Character
	if character then
		local pivot = character:GetPivot()
		zombie:PivotTo(pivot * CFrame.new(offset, 0, -20)) -- 偏移位置
	end

	-- 2. 设置属性 (血量、大小)
	local humanoid = zombie:WaitForChild("Humanoid")
	humanoid.MaxHealth = config.HP
	humanoid.Health = config.HP

	-- 3. 添加描边 (Highlight)
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1 -- 内部透明
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = config.OutlineColor
	highlight.Adornee = zombie
	highlight.Parent = zombie

	-- 4. 标记给客户端 (显示箭头)
	TutorialEvent:FireClient(player, "MarkZombie", zombie)

	-- 5. 死亡逻辑
	humanoid.Died:Connect(function()
		print("💀 " .. config.Name .. " 已死亡")

		-- 给奖励 (XP, MTC 等)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			-- 这里可以根据 config.XP 加经验，暂略
			local bio = leaderstats:FindFirstChild("Biomass")
			-- 如果是精英怪，可以加数据
			if zombieType == "Elite" and bio then
				bio.Value = bio.Value + 3
			end
		end

		-- 生成掉落物
		local dropPos = zombie:GetPivot().Position
		for _, dropData in ipairs(config.Drops) do
			SpawnLoot(dropData.Name, dropPos, dropData.Count, player, dropData.Color)
		end

		Debris:AddItem(zombie, 5)
	end)
end

-- [主监听]
TutorialEvent.OnServerEvent:Connect(function(player, action, data)
	if action == "SpawnZombie" then
		print("🧟 开始生成双僵尸波次...")
		-- 生成普通僵尸 (蓝色，左边)
		SpawnSpecificZombie(player, "Normal", -5)

		-- 生成精英僵尸 (红色，右边)
		SpawnSpecificZombie(player, "Elite", 5)

	elseif action == "MoveToLab" then
		-- (这部分代码保持你原本的 GameFlowController 逻辑，或者如果在这里也有处理，请保留)
		-- 这里如果不处理传送，就在 GameFlowController 里处理
	end
end)