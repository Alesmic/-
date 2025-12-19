-- Script: GameFlowController (在 ServerScriptService 中)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris") 

-- [辅助函数] 自动创建缺失的事件 (防止报错)
local function GetOrCreateEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

-- !!! 事件引用 !!!
local TutorialEvent = GetOrCreateEvent("TutorialEvent")
local sellBiomassEvent = GetOrCreateEvent("SellBiomassEvent")
local toggleWaypointEvent = GetOrCreateEvent("ToggleWaypointEvent")
local secondTriggerEvent = GetOrCreateEvent("SecondDialogueEvent")

-- !!! 场景对象 !!!
-- 确保 Workspace 里有这些名字的 Part
local labAnchor = workspace:WaitForChild("LabTeleportAnchor", 10) 
local startAnchor = workspace:WaitForChild("TutorialStartLocation", 10)

if not labAnchor then warn("⚠️ 警告: 找不到 LabTeleportAnchor") end
if not startAnchor then warn("⚠️ 警告: 找不到 TutorialStartLocation") end

-- !!! 配置 !!!
local MTC_PER_RECYCLE = 100 -- 汇率：每个生物质 100 MTC
local SECOND_VOICE_ASSET_ID = "rbxassetid://74061505906890" -- 欢迎语音
local SECOND_VO_DURATION = 7.0

-- [函数 1: 回收箱出售逻辑]
local function handleSellBiomass(player)
	print("收到 " .. player.Name .. " 的出售请求")

	-- 1. 获取 Leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		warn("❌ 找不到 leaderstats，无法交易")
		return 
	end

	-- 2. 获取数据对象
	local biomass = leaderstats:FindFirstChild("Biomass")
	local mtc = leaderstats:FindFirstChild("MTC")

	if biomass and mtc then
		print("当前生物质: " .. biomass.Value .. ", 当前 MTC: " .. mtc.Value)

		if biomass.Value > 0 then
			-- 3. 计算获得的钱
			local earnedMTC = biomass.Value * MTC_PER_RECYCLE

			-- 4. 加钱
			mtc.Value = mtc.Value + earnedMTC

			-- 5. 生物质清零
			biomass.Value = 0

			print("💰 交易成功！获得: " .. earnedMTC .. " MTC")

			-- 6. 关闭路标并推进流程
			toggleWaypointEvent:FireClient(player, false)

			-- 稍微延迟一点，确保客户端UI更新
			task.wait(1)
			TutorialEvent:FireClient(player, "StartObjective4")
		else
			print("⚠️ 玩家生物质为 0，无法出售")
		end
	else
		warn("❌ leaderstats 中缺少 Biomass 或 MTC 值")
	end
end

-- [函数 2: 到达实验室后的流程]
local function startSecondDialogue(player)
	print("触发实验室欢迎流程...")

	-- 播放语音 (如果有)
	local sound = Instance.new("Sound")
	sound.SoundId = SECOND_VOICE_ASSET_ID
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		sound.Parent = character.HumanoidRootPart
		sound:Play()
		Debris:AddItem(sound, SECOND_VO_DURATION + 1)
	end

	-- 触发客户端字幕事件
	secondTriggerEvent:FireClient(player)

	-- 等待一段时间后开启回收箱路标
	task.wait(SECOND_VO_DURATION + 1) 
	print("开启回收箱路标")
	toggleWaypointEvent:FireClient(player, true) 
end

-- [函数 3: 传送逻辑] (ClientStoryManager 请求时触发)
local function startLabObjective(player)
	print(player.Name .. " 请求进入实验室流程...")

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		-- 传送玩家
		if labAnchor then
			local targetCFrame = labAnchor.CFrame + Vector3.new(0, 3, 0)
			character:PivotTo(targetCFrame)
			print("✅ 玩家已传送到实验室")

			-- 传送后启动欢迎流程
			task.wait(1)
			startSecondDialogue(player)
		else
			warn("❌ 无法传送：缺少 LabTeleportAnchor")
		end
	end
end

-- [监听玩家加入 - 强制传送出生点]
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- 等待一下确保角色加载完成
		task.wait(0.5)
		if startAnchor and character:FindFirstChild("HumanoidRootPart") then
			-- 传送到 TutorialStartLocation
			character:PivotTo(startAnchor.CFrame + Vector3.new(0, 3, 0))
			print(player.Name .. " 已传送到初始出生点。")
		end
	end)
end)

-- [监听传送事件]
TutorialEvent.OnServerEvent:Connect(function(player, action)
	if action == "MoveToLab" then
		startLabObjective(player)
	end
end)

-- [监听出售事件]
sellBiomassEvent.OnServerEvent:Connect(handleSellBiomass)