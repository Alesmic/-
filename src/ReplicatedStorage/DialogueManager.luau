-- 位置: ReplicatedStorage.DialogueManager
local DialogueManager = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 核心函数：显示对话并监听点击
-- text: 要显示的文字
-- onCloseCallback: [可选] 对话关闭后要执行的函数
function DialogueManager:ShowAndListen(text, onCloseCallback)
	local mainGui = playerGui:FindFirstChild("MainGui")
	local dialogueBox = mainGui and mainGui:FindFirstChild("DialogueBox")
	local textLabel = dialogueBox and dialogueBox:FindFirstChild("ContentText")
	local promptIcon = dialogueBox and dialogueBox:FindFirstChild("PromptIcon") -- ∇ 图标

	if not dialogueBox or not textLabel then
		warn("DialogueManager: 未找到 UI 组件，请检查 MainGui 命名")
		return
	end

	-- 1. 初始化显示
	textLabel.Text = text
	dialogueBox.Visible = true
	if promptIcon then promptIcon.Visible = true end

	-- 2. 设置点击监听
	local connection
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- 仅在玩家点击鼠标左键或触摸屏幕时触发
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

			-- 关闭 UI
			dialogueBox.Visible = false
			if promptIcon then promptIcon.Visible = false end

			-- 核心：断开监听，防止重复点击报错
			connection:Disconnect()
			print("DialogueManager: 玩家点击，对话已关闭")

			-- 3. 执行回调函数 (例如激活工作站)
			if onCloseCallback and type(onCloseCallback) == "function" then
				onCloseCallback()
			end
		end
	end)
end

return DialogueManager