-- 脚本名: duihua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueManager = require(ReplicatedStorage:WaitForChild("DialogueManager"))
local WorkstationManager = require(ReplicatedStorage:WaitForChild("WorkstationManager"))

local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")

-- 【关键修改】游戏一启动就初始化工作站，不等待任何事件
WorkstationManager:Init()

TutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "TriggerObjective4" then
		-- 弹出对话，对话关闭后仅激活“箭头指引”，不影响按 E 功能
		DialogueManager:ShowAndListen(data, function()
			print("对话结束，显示工作站位置箭头")
			WorkstationManager:Activate() 
		end)
	end
end)