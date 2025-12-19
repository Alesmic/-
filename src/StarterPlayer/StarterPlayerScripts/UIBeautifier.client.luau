-- Script: UIBeautifier.client.luau
-- 全局 UI 美化脚本 (白金半透明版)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================= 白金美化配置 =================
local STYLE = {
	CornerRadius = UDim.new(0, 10),

	-- [修改] 边框色：金属银
	StrokeColor = Color3.fromRGB(180, 180, 190),
	StrokeThickness = 2,

	-- [修改] 背景色：亮白/极浅灰
	BackgroundColor = Color3.fromRGB(245, 245, 250),

	-- [修改] 透明度：玻璃感
	BackgroundTransparency = 0.2,

	-- [修改] 文字适配：深色文字 (用于替换原来的浅色文字)
	DarkTextColor = Color3.fromRGB(40, 40, 50) 
}

local TARGET_GUIS = {
	"HUDGui", 
	"ResearchGui", 
	"GameGui",
	"RecyclingGUI" 
}

-- ================= 美化函数 =================
local function BeautifyFrame(guiElement)
	if guiElement:FindFirstChild("IsBeautified") then return end

	-- 标记已处理
	local tag = Instance.new("BoolValue")
	tag.Name = "IsBeautified"
	tag.Parent = guiElement

	-- 1. 处理 Frame (背景板)
	if guiElement:IsA("Frame") and guiElement.BackgroundTransparency ~= 1 then

		-- 应用圆角
		if not guiElement:FindFirstChildOfClass("UICorner") then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = STYLE.CornerRadius
			corner.Parent = guiElement
		end

		-- 应用描边
		if not guiElement:FindFirstChildOfClass("UIStroke") then
			local stroke = Instance.new("UIStroke")
			stroke.Color = STYLE.StrokeColor
			stroke.Thickness = STYLE.StrokeThickness
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Transparency = 0.3
			stroke.Parent = guiElement
		end

		-- 智能背景替换
		-- 如果背景是深色或灰色，替换为白金风格
		-- 如果是鲜艳颜色(如红色血条)，则保留
		local h, s, v = guiElement.BackgroundColor3:ToHSV()
		if s < 0.2 then 
			guiElement.BackgroundColor3 = STYLE.BackgroundColor
			guiElement.BackgroundTransparency = STYLE.BackgroundTransparency

			-- 白金渐变 (亮白 -> 银白)
			if not guiElement:FindFirstChildOfClass("UIGradient") then
				local gradient = Instance.new("UIGradient")
				gradient.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 225, 235))
				}
				gradient.Rotation = 60
				gradient.Parent = guiElement
			end
		end
	end

	-- 2. 处理 TextLabel/TextButton (文字适配)
	-- 因为背景变亮了，原来的白色文字可能会看不清，需要变成深色
	if (guiElement:IsA("TextLabel") or guiElement:IsA("TextButton")) then
		local color = guiElement.TextColor3
		-- 如果文字是白色或浅灰，改为深灰色
		if color.R > 0.8 and color.G > 0.8 and color.B > 0.8 then
			guiElement.TextColor3 = STYLE.DarkTextColor
		end

		-- 给按钮也加圆角
		if guiElement:IsA("TextButton") and guiElement.BackgroundTransparency ~= 1 then
			if not guiElement:FindFirstChildOfClass("UICorner") then
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = guiElement
			end
		end
	end
end

-- ================= 初始化与监听 =================
local function Init()
	task.wait(1) 

	for _, guiName in ipairs(TARGET_GUIS) do
		local gui = playerGui:WaitForChild(guiName, 5)
		if gui then
			print("🎨 正在应用白金主题: " .. guiName)

			for _, desc in pairs(gui:GetDescendants()) do
				BeautifyFrame(desc)
			end

			gui.DescendantAdded:Connect(BeautifyFrame)
		end
	end
end

Init()