-- LocalScript (flash): 控制所有客户端交互、对话流程、路标闪烁和 E 键提示
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- !!! 远程事件引用 !!!
local triggerEvent = ReplicatedStorage:WaitForChild("TriggerDialogueEvent")    
local secondTriggerEvent = ReplicatedStorage:WaitForChild("SecondDialogueEvent") 
local toggleWaypointEvent = ReplicatedStorage:WaitForChild("ToggleWaypointEvent") 
local sellBiomassEvent = ReplicatedStorage:WaitForChild("SellBiomassEvent")      

-- !!! UI 和对象引用 !!!
local TARGET_NAME = "recycling bin"
local targetPart = workspace:WaitForChild(TARGET_NAME) 

-- Dialogue GUI 组件
local dialogueGui = PlayerGui:WaitForChild("DialogueGUI")
local dialogueFrame = dialogueGui:WaitForChild("Frame")
local speakerLabel = dialogueFrame:WaitForChild("SpeakerLabel") 
local textLabel = dialogueFrame:WaitForChild("TextLabel") 
local promptIndicator = dialogueFrame:WaitForChild("PromptIndicator")

-- Objective GUI 组件
local objectiveGui = PlayerGui:WaitForChild("ObjectiveGUI")
local objectiveTextLabel = objectiveGui:WaitForChild("TextLabel") 

-- Recycling GUI 组件
local recyclingGui = PlayerGui:WaitForChild("RecyclingGUI")
local yesButton = recyclingGui:WaitForChild("Frame"):WaitForChild("YesButton")
local noButton = recyclingGui:WaitForChild("Frame"):WaitForChild("NoButton")

-- Waypoint 组件
local billboardGui = targetPart:WaitForChild("BillboardGui")
local indicator = billboardGui:WaitForChild("WaypointIndicator")

-- 新增：交互提示 GUI 组件
local promptGui = PlayerGui:WaitForChild("PromptGUI")
local interactPrompt = promptGui:WaitForChild("InteractPrompt")


-- !!! 可调整项 !!!
local UI_DURATION = 4.5 
local OBJECTIVE_DISPLAY_TIME = 5 
local INTERACT_DISTANCE = 10     -- E 键交互范围 (Studs)

-- 对话文本
local SECOND_DIALOGUE_TEXT = "欢迎来到您的新实验室。您收集的生物质可以在您的回收箱中出售以换取元币。"
local OBJECTIVE_TEXT = "新目标：\n出售生物质回收物"

-- *** 闪烁动画逻辑 ***
local BLINK_SPEED = 5; local MIN_ALPHA = 0.3; local MAX_ALPHA = 1.0; local connection 

local function updateBlink(time)
	local sineWave = math.sin(time * BLINK_SPEED)
	local alphaRange = MAX_ALPHA - MIN_ALPHA
	local alpha = MIN_ALPHA + ((sineWave + 1) / 2) * alphaRange
	indicator.TextTransparency = alpha
end

local function toggleBlink(enabled)
	if enabled and not connection then
		connection = RunService.Heartbeat:Connect(updateBlink)
	elseif not enabled and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- 监听服务器事件，控制路标的开关
toggleWaypointEvent.OnClientEvent:Connect(function(visible)
	billboardGui.Enabled = visible 
	toggleBlink(visible)            
end)
toggleBlink(false) 


-- *** 对话监听器 ***

-- [函数 1: 初始对话监听器]
triggerEvent.OnClientEvent:Connect(function(playerId)
	local message = "你好，" .. playerId .. "。请返回你的实验室进行指导。"
	speakerLabel.Text = "实验室AI顾问"
	textLabel.Text = message
	promptIndicator.Visible = false 
	dialogueGui.Enabled = true
	task.wait(UI_DURATION) 
	dialogueGui.Enabled = false
end)


-- [函数 2: 第二次对话监听器和点击关闭]
local dialogueEndConnection -- 用于存储点击监听器
secondTriggerEvent.OnClientEvent:Connect(function()
	speakerLabel.Text = "实验室AI顾问"
	textLabel.Text = SECOND_DIALOGUE_TEXT
	dialogueGui.Enabled = true
	promptIndicator.Visible = true

	dialogueEndConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not gameProcessedEvent then
			if dialogueGui.Enabled then
				dialogueEndConnection:Disconnect()

				-- 关闭对话框
				dialogueGui.Enabled = false
				promptIndicator.Visible = false

				-- 显示新目标
				objectiveTextLabel.Text = OBJECTIVE_TEXT
				objectiveGui.Enabled = true

				-- 目标显示一段时间后自动关闭
				task.wait(OBJECTIVE_DISPLAY_TIME)
				objectiveGui.Enabled = false
			end
		end
	end)
end)


-- *** 回收箱 UI 逻辑 (不锁定摄像机) ***

local function closeRecyclingGUI()
	recyclingGui.Enabled = false
	-- 确保玩家点击 '否' 或 '是' 后，交互提示能再次出现 (如果玩家仍在范围内)
end

noButton.MouseButton1Click:Connect(closeRecyclingGUI)

yesButton.MouseButton1Click:Connect(function()
	-- 通知服务器执行出售和更新数据
	sellBiomassEvent:FireServer()
	closeRecyclingGUI()
	-- 关闭路标动画 
	toggleBlink(false) 
end)


-- *** E 键交互逻辑 ***

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	-- 仅在按下 E 键、不是被其他系统处理、且回收 UI 未打开时检测
	if input.KeyCode == Enum.KeyCode.E and not gameProcessedEvent and not recyclingGui.Enabled then

		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		-- 检查玩家是否在交互范围内
		if rootPart and (rootPart.Position - targetPart.Position).Magnitude < INTERACT_DISTANCE then

			-- 开启回收箱 UI (不锁定摄像机)
			recyclingGui.Enabled = true

			-- 同时隐藏 E 键提示
			promptGui.Enabled = false
		end
	end
end)


-- *** 实时距离检测和 E 键提示显示 ***
local isPlayerInRange = false

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then return end

	local distance = (rootPart.Position - targetPart.Position).Magnitude
	local isInRange = distance < INTERACT_DISTANCE

	-- 1. 检查是否在范围内，且回收 UI 和对话 UI 都没有打开
	if isInRange and not recyclingGui.Enabled and not dialogueGui.Enabled then
		if not isPlayerInRange then
			-- 玩家刚进入范围：显示提示
			promptGui.Enabled = true
			isPlayerInRange = true
		end
	else
		if isPlayerInRange then
			-- 玩家刚离开范围，或打开了 UI：隐藏提示
			promptGui.Enabled = false
			isPlayerInRange = false
		end
	end
end)