local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 引用你精简后的 GameConfig
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local args = string.split(message, " ")
		local command = string.lower(args[1])
		local value = tonumber(args[2])

		-- 获取数据目录（假设你已在 Leaderstats 中创建了这些数值）
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		-- ==========================================
		-- 指令 1: 设置 $MTC 余额 (/mtc 数量)
		-- 对应教学中的 Metacoins 计数器 
		-- ==========================================
		if (command == "/mtc" or command == "/money") and value then
			local mtcStat = leaderstats:FindFirstChild("MTC") or leaderstats:FindFirstChild("Gold")
			if mtcStat then
				mtcStat.Value = value
				print("⚙ 管理员: $MTC 已设置为 " .. value)
			end
		end

		-- ==========================================
		-- 指令 2: 设置生物质数量 (/bio 数量)
		-- 对应教学中的 Bio-matter 计数器 [cite: 42, 61]
		-- ==========================================
		if (command == "/bio" or command == "/salvage") and value then
			local bioStat = leaderstats:FindFirstChild("BioMatter")
			if bioStat then
				bioStat.Value = value
				print("⚙ 管理员: 生物质计数器已设置为 " .. value)
			end
		end

		-- ==========================================
		-- 指令 3: 直接获得教学提取物 (/getextracts)
		-- 自动按照教学配置获得指定数量的提取物 
		-- ==========================================
		if command == "/getextracts" then
			local inventory = player:FindFirstChild("Inventory")
			if inventory then
				-- 从 GameConfig 中读取教学 Elite Zombie 的掉落配置
				local dropInfo = GameConfig.Mobs["Elite Zombie"].Drops [cite: 45]

				for _, drop in ipairs(dropInfo) do
					local item = inventory:FindFirstChild(drop.ItemName)
					if not item then
						item = Instance.new("IntValue")
						item.Name = drop.ItemName
						item.Parent = inventory
					end
					item.Value = item.Value + drop.Amount
				end
				print("🎁 管理员: 已发放教学所需的全部提取物")
			end
		end

		-- ==========================================
		-- 指令 4: 瞬间移动到实验室 (/lab)
		-- 对应教学 Objective #3 的地图转换 
		-- ==========================================
		if command == "/lab" then
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				-- 假设你的实验室地图有一个名为 "LabSpawn" 的零件
				local labSpawn = workspace:FindFirstChild("LabSpawn")
				if labSpawn then
					character.HumanoidRootPart.CFrame = labSpawn.CFrame
					print("🚀 管理员: 已传送至实验室")
				else
					warn("❌ 未找到 LabSpawn 零件")
				end
			end
		end
	end)
end)