local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SynthesizeEvent = ReplicatedStorage:WaitForChild("SynthesizeEvent")

local frame = script.Parent:WaitForChild("MainFrame")
local leftPanel = frame:WaitForChild("LeftPanel")
local rightPanel = frame:WaitForChild("RightPanel")
local synthBtn = frame:WaitForChild("SynthesizeButton")

local filledSlots = 0

-- 高亮特效函数 
local function highlight(obj, color)
	local stroke = Instance.new("UIStroke", obj)
	stroke.Color = color
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local t = TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.5})
	t:Play()
end

-- 初始化高亮
for i = 1, 3 do
	local item = leftPanel:FindFirstChild("Item"..i)
	if item then highlight(item, Color3.new(1,1,1)) end -- 左侧白色高亮
	local slot = rightPanel:FindFirstChild("Slot"..i)
	if slot then highlight(slot, Color3.fromRGB(255, 255, 0)) end -- 右侧黄色高亮
end

-- 物品点击逻辑 (模拟拖入) 
local function setupItem(item)
	item.MouseButton1Click:Connect(function()
		if filledSlots < 3 and item.Visible then
			filledSlots += 1
			item.Visible = false -- 隐藏左侧

			-- 填充右侧
			local slot = rightPanel:FindFirstChild("Slot"..filledSlots)
			slot.ImageColor3 = item.ImageColor3
			-- 移除空槽位高亮
			if slot:FindFirstChild("UIStroke") then slot.UIStroke:Destroy() end

			-- 检查是否满了
			if filledSlots == 3 then
				synthBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- 按钮变绿
				highlight(synthBtn, Color3.fromRGB(0, 255, 0)) -- 按钮高亮
			end
		end
	end)
end

for i = 1, 3 do
	if leftPanel:FindFirstChild("Item"..i) then setupItem(leftPanel["Item"..i]) end
end

-- 合成按钮逻辑 
synthBtn.MouseButton1Click:Connect(function()
	if filledSlots == 3 then
		SynthesizeEvent:FireServer() -- 通知服务器
		frame.Visible = false -- 关闭界面
		print("请求合成...")
	end
end)