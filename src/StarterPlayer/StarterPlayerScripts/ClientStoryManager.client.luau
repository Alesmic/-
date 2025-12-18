-- 1. 在脚本最顶部引入配置
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local TweenService = game:GetService("TweenService") -- 确保有这个

-- 计算总共需要捡的数量
local TOTAL_LOOT_NEEDED = GameConfig.GetTotalLootCount() 

-- ... (中间代码保持不变) ...

-- [新增：右下角弹窗函数]
local function ShowLootNotification(itemName)
	-- 1. 创建 UI 容器 (如果没有)
	local gui = playerGui:FindFirstChild("GameGui")
	if not gui then return end

	local notifyFrame = gui:FindFirstChild("NotifyContainer")
	if not notifyFrame then
		notifyFrame = Instance.new("Frame")
		notifyFrame.Name = "NotifyContainer"
		notifyFrame.Size = UDim2.new(0, 200, 0, 300)
		notifyFrame.Position = UDim2.new(1, -220, 1, -320) -- 右下角
		notifyFrame.BackgroundTransparency = 1
		notifyFrame.Parent = gui

		-- 添加列表布局，让弹窗自动排列
		local layout = Instance.new("UIListLayout")
		layout.Parent = notifyFrame
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Padding = UDim.new(0, 5)
	end

	-- 2. 创建弹窗条
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 40)
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.Text = "+1 " .. itemName
	label.Parent = notifyFrame

	-- 3. 动画效果 (淡出销毁)
	task.delay(2, function()
		local tween = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			label:Destroy()
		end)
	end)
end

-- [修改：事件监听部分]
TutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "StartObjective1" then
		StartObjective1()

	elseif action == "MarkZombie" then
		MarkZombie(data) -- 这个函数现在会给两个僵尸都标上箭头

	elseif action == "LootPickedUp" then
		-- data 参数现在是 itemName
		local itemName = data 

		-- 1. 显示弹窗
		ShowLootNotification(itemName)

		-- 2. 计数
		lootCount = lootCount + 1
		print("捡到了 " .. lootCount .. " / " .. TOTAL_LOOT_NEEDED .. " 个物品")

		-- 3. 检查是否全部捡完
		if lootCount >= TOTAL_LOOT_NEEDED and not objective3Started then
			objective3Started = true
			InitiateObjective3() -- 触发传送流程
		end
	end
end)