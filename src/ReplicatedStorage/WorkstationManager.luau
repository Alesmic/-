-- 位置: ReplicatedStorage.DialogueManager
local WorkstationManager = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local workstation = workspace:WaitForChild("ResearchWorkstation")
local prompt = workstation:WaitForChild("ProximityPrompt")
local arrowGui = workstation:WaitForChild("ArrowGui")

-- 初始化函数：在脚本加载时就绑定 E 键功能
function WorkstationManager:Init()
	-- 确保提示框始终可用
	prompt.Enabled = true 

	prompt.Triggered:Connect(function()
		local gui = playerGui:FindFirstChild("ResearchGui")
		local frame = gui and gui:FindFirstChild("MainFrame")

		if frame then
			-- 切换界面显示/隐藏
			frame.Visible = not frame.Visible 

			-- 如果打开了界面，就隐藏头顶的指引箭头（如果有的话）
			if frame.Visible and arrowGui then
				arrowGui.Enabled = false
			end
		end
	end)
	print("工作站已就绪：玩家现在可以随时按 E 交互。")
end

-- 激活指引（这个函数现在只负责显示箭头，不再控制按 E 的权限）
function WorkstationManager:Activate()
	if arrowGui then
		arrowGui.Enabled = true
		-- 可以在这里加入之前的闪烁动画逻辑
	end
end

return WorkstationManager