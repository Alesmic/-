-- DialogueHandler.client.luau (原 LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- 引用事件
local secondTriggerEvent = ReplicatedStorage:WaitForChild("SecondDialogueEvent") 
-- local triggerEvent = ReplicatedStorage:WaitForChild("TriggerDialogueEvent") -- 第一段对话不再需要

-- 引用 UI 组件
local dialogueGui = PlayerGui:WaitForChild("DialogueGUI")
local dialogueFrame = dialogueGui:WaitForChild("Frame")
local speakerLabel = dialogueFrame:WaitForChild("SpeakerLabel") 
local textLabel = dialogueFrame:WaitForChild("TextLabel") 
local promptIndicator = dialogueFrame:WaitForChild("PromptIndicator")

local objectiveGui = PlayerGui:WaitForChild("ObjectiveGUI")
local objectiveTextLabel = objectiveGui:WaitForChild("TextLabel") 

local OBJECTIVE_DISPLAY_TIME = 7
local SECOND_DIALOGUE_TEXT = "欢迎来到您的新实验室。您收集的生物质可以在您的回收箱中出售以换取元币。"
local OBJECTIVE_TEXT = "新目标：\n出售生物质回收物"

-- [监听器: 当服务器通知“欢迎来到实验室”时触发]
secondTriggerEvent.OnClientEvent:Connect(function()
	-- 1. 显示对话 UI
	speakerLabel.Text = "实验室AI顾问"
	textLabel.Text = SECOND_DIALOGUE_TEXT
	dialogueGui.Enabled = true
	promptIndicator.Visible = true -- 显示点击提示

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