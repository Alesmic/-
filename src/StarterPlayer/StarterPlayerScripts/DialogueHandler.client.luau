-- DialogueHandler.client.luau (LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- 1. 引用事件 (已恢复 TriggerDialogueEvent)
local secondTriggerEvent = ReplicatedStorage:WaitForChild("SecondDialogueEvent") 
local triggerEvent = ReplicatedStorage:WaitForChild("TriggerDialogueEvent") -- 第一段对话事件

-- 2. 引用 UI 组件
local dialogueGui = PlayerGui:WaitForChild("DialogueGUI")
local dialogueFrame = dialogueGui:WaitForChild("Frame")
local speakerLabel = dialogueFrame:WaitForChild("SpeakerLabel") 
local textLabel = dialogueFrame:WaitForChild("TextLabel") 
local promptIndicator = dialogueFrame:WaitForChild("PromptIndicator")

local objectiveGui = PlayerGui:WaitForChild("ObjectiveGUI")
local objectiveTextLabel = objectiveGui:WaitForChild("TextLabel") 

-- 3. 常量设置
local UI_DURATION = 4.5 -- 第一段对话显示的持续时间
local OBJECTIVE_DISPLAY_TIME = 7
local SECOND_DIALOGUE_TEXT = "欢迎来到您的新实验室。您收集的生物质可以在您的回收箱中出售以换取元币。"
local OBJECTIVE_TEXT = "新目标：\n出售生物质回收物"


-- [监听器 1: 第一段对话逻辑 (新增)]
-- 触发条件：玩家捡起掉落物，服务器脚本调用 TriggerDialogueEvent
triggerEvent.OnClientEvent:Connect(function(playerId)
	-- 构建欢迎文本
	local message = "你好，" .. playerId .. "。请返回你的实验室进行指导。"

	-- 更新 UI
	speakerLabel.Text = "实验室AI顾问"
	textLabel.Text = message
	promptIndicator.Visible = false -- 第一段是自动播放，不需要点击提示
	dialogueGui.Enabled = true

	-- 等待一段时间后自动关闭
	task.wait(UI_DURATION) 
	dialogueGui.Enabled = false
end)


-- [监听器 2: 第二段对话逻辑 (保留原样)]
-- 触发条件：玩家传送完成后，服务器脚本调用 SecondDialogueEvent
secondTriggerEvent.OnClientEvent:Connect(function()
	-- 1. 显示对话 UI
	speakerLabel.Text = "实验室AI顾问"
	textLabel.Text = SECOND_DIALOGUE_TEXT
	dialogueGui.Enabled = true
	promptIndicator.Visible = true -- 显示点击提示，因为需要玩家确认

	-- 2. 监听点击以关闭
	local connection
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not gameProcessedEvent then

			if dialogueGui.Enabled then
				connection:Disconnect() -- 断开监听

				-- 关闭对话
				dialogueGui.Enabled = false
				promptIndicator.Visible = false

				-- 显示新目标
				objectiveTextLabel.Text = OBJECTIVE_TEXT
				objectiveGui.Enabled = true

				-- 几秒后关闭目标显示
				task.wait(OBJECTIVE_DISPLAY_TIME)
				objectiveGui.Enabled = false
			end
		end
	end)
end)