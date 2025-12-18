-- Script: GameFlowController (在 ServerScriptService 中)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris") 

-- !!! 语音 ID 配置 !!!
local VOICE_ASSET_ID = "rbxassetid://116952830538871"         -- "你好，a。请返回你的实验室进行指导。"
local SECOND_VOICE_ASSET_ID = "rbxassetid://74061505906890"  -- "欢迎来到您的新实验室..."

-- !!! 事件和对象引用 !!!
-- 1. [新增] 引用 TutorialEvent (如果不存在则等待)
local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")

local triggerEvent = ReplicatedStorage:WaitForChild("TriggerDialogueEvent")
local secondTriggerEvent = ReplicatedStorage:WaitForChild("SecondDialogueEvent")
local toggleWaypointEvent = ReplicatedStorage:WaitForChild("ToggleWaypointEvent")
local sellBiomassEvent = ReplicatedStorage:WaitForChild("SellBiomassEvent")
local labAnchor = workspace:WaitForChild("LabTeleportAnchor") 

-- !!! 可调整项 !!!
local VO_DURATION = 5    -- 初始语音播放时长
local SECOND_VO_DURATION = 7.0 -- 第二次语音播放时长
local MTC_PER_RECYCLE = 100 -- 每次回收获得的元币


-- [函数 1: 第二次对话和高亮路标] (到达实验室后触发)
local function startSecondDialogue(player)
	print("触发第二次对话计时器...")

	-- 1. 等待 1.5 秒 (传送后延迟)
	task.wait(1.5)

	-- 2. 服务器播放第二次语音
	local sound = Instance.new("Sound")
	sound.SoundId = SECOND_VOICE_ASSET_ID
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		sound.Parent = character.HumanoidRootPart
		sound:Play()
		Debris:AddItem(sound, SECOND_VO_DURATION + 1)
	end

	-- 3. 触发第二次对话事件，告知客户端显示 UI 和提示符
	secondTriggerEvent:FireClient(player)

	print("已触发第二次对话，等待客户端点击结束。")

	-- 4. 延迟开启路标 (假设玩家在语音播放完毕后 3 秒内点击)
	task.wait(SECOND_VO_DURATION + 3)

	-- 5. 开启路标：通知 flash 脚本在客户端显示回收箱箭头
	toggleWaypointEvent:FireClient(player, true) 
	print("回收箱路标已开启。")
end


-- [函数 2: 初始对话和传送逻辑] (被调用时才执行)
local function startLabObjective(player)
	print(player.Name .. " 请求进入实验室流程...")
	local playerId = player.DisplayName

	-- 播放第一次语音
	local sound = Instance.new("Sound")
	sound.SoundId = VOICE_ASSET_ID

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		sound.Parent = character.HumanoidRootPart
		sound:Play()
		Debris:AddItem(sound, VO_DURATION + 1)
	end

	-- 通知客户端显示第一次对话
	triggerEvent:FireClient(player, playerId)

	-- 等待语音播放完毕
	task.wait(VO_DURATION)

	-- 传送
	if character and character:FindFirstChild("HumanoidRootPart") then
		-- +Vector3.new(0, 3, 0) 防止卡在地里
		local targetCFrame = labAnchor.CFrame + Vector3.new(0, 3, 0)
		character:PivotTo(targetCFrame)
		print("玩家已传送。")

		-- 在传送完成后，立即启动第二次对话流程
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

		-- 出售完成后关闭路标
		toggleWaypointEvent:FireClient(player, false)

		-- 触发下一个目标 (Target 4)
		task.wait(1)
		TutorialEvent:FireClient(player, "StartObjective4")
	end
end

-- [修改关键点]：删除原有的 PlayerAdded 自动传送，改为监听事件
TutorialEvent.OnServerEvent:Connect(function(player, action)
	if action == "MoveToLab" then
		startLabObjective(player) -- 只有收到客户端的 MoveToLab 信号才传送
	end
end)

-- 监听客户端的出售请求
sellBiomassEvent.OnServerEvent:Connect(handleSellBiomass)