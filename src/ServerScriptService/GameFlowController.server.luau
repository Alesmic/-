-- Script: GameFlowController (在 ServerScriptService 中)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris") 

-- !!! 语音 ID 配置 !!!
local VOICE_ASSET_ID = "rbxassetid://116952830538871"         -- "你好，a。请返回你的实验室进行指导。"
local SECOND_VOICE_ASSET_ID = "rbxassetid://74061505906890"  -- "欢迎来到您的新实验室..."

-- !!! 事件和对象引用 !!!
local triggerEvent = ReplicatedStorage:WaitForChild("TriggerDialogueEvent")
local secondTriggerEvent = ReplicatedStorage:WaitForChild("SecondDialogueEvent")
local toggleWaypointEvent = ReplicatedStorage:WaitForChild("ToggleWaypointEvent")
local sellBiomassEvent = ReplicatedStorage:WaitForChild("SellBiomassEvent") -- 新增
local labAnchor = workspace:WaitForChild("LabTeleportAnchor") 

-- !!! 可调整项 !!!
local VO_DURATION = 5    -- 初始语音播放时长
local SECOND_VO_DURATION = 7.0 -- 第二次语音播放时长
local MTC_PER_RECYCLE = 100 -- 每次回收获得的元币


-- [函数 1: 第二次对话和高亮路标]
local function startSecondDialogue(player)
	print("玩家已到达，准备触发实验室欢迎语音...")

	-- 1. 稍微等待一下，让客户端加载周围环境 (可选，0.5到1秒即可)
	task.wait(1) 

	-- 2. 服务器播放“欢迎”语音
	local sound = Instance.new("Sound")
	sound.SoundId = SECOND_VOICE_ASSET_ID
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		sound.Parent = character.HumanoidRootPart
		sound:Play()
		Debris:AddItem(sound, SECOND_VO_DURATION + 1)
	end

	-- 3. 触发客户端事件：显示“欢迎来到新实验室”字幕和∇提示符
	secondTriggerEvent:FireClient(player)

	print("已触发欢迎对话，等待玩家点击。")

	-- 4. 开启路标 (等待语音播放完毕后)
	task.wait(SECOND_VO_DURATION)

	-- 5. 开启回收箱路标
	toggleWaypointEvent:FireClient(player, true) 
	print("回收箱路标已开启。")
end


-- [函数 2: 初始对话和传送逻辑]
local function startLabObjective(player)
	local character = player.Character

	-- 确保角色存在
	if character and character:FindFirstChild("HumanoidRootPart") then

		-- 1. 【核心修改】立即传送玩家到实验室锚点
		local targetCFrame = labAnchor.CFrame + Vector3.new(0, 2, 0)
		character:PivotTo(targetCFrame)
		print(player.Name .. " 已传送到实验室。")

		-- 2. 【核心修改】传送完成后，直接启动欢迎流程
		-- 我们跳过了原本的“第一段对话”，因为玩家已经被强制传送到目的地了
		startSecondDialogue(player)
	end
end

-- [函数 3: 回收箱出售逻辑]
local function handleSellBiomass(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local biomass = leaderstats:FindFirstChild("Biomass")
	local mtc = leaderstats:FindFirstChild("MTC")

	if biomass and mtc and biomass.Value > 0 then
		-- 执行出售
		local earnedMTC = biomass.Value * MTC_PER_RECYCLE
		mtc.Value = mtc.Value + earnedMTC

		-- 生物质归零
		biomass.Value = 0

		print(player.Name .. " 成功出售，获得 " .. earnedMTC .. " MTC。")

		-- 可选：出售完成后关闭路标
		toggleWaypointEvent:FireClient(player, false)
	end
end

-- [触发逻辑]
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- 玩家进入游戏 2 秒后直接传送并开始介绍
		task.wait(2)
		startLabObjective(player)
	end)
end)

-- 监听客户端的出售请求
sellBiomassEvent.OnServerEvent:Connect(handleSellBiomass)