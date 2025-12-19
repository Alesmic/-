-- Script: UnifiedDialogueSystem.client.luau
-- 统一美化对话系统 (白金半透明版)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================= 白金配色配置 =================
local CONFIG = {
	TypewriterSpeed = 0.03,
	UI = {
		CornerRadius = UDim.new(0, 12),
		StrokeThickness = 2, -- 边框稍微细一点，更精致

		-- [修改] 背景色：极浅的银灰色 (白金感)
		BackgroundColor = Color3.fromRGB(245, 245, 250), 

		-- [修改] 边框色：金属银
		BorderColor = Color3.fromRGB(160, 160, 170),    

		-- [修改] 正文颜色：深灰色 (在亮背景上对比度更高)
		TextColor = Color3.fromRGB(40, 40, 50),

		-- [修改] 名字颜色：深银色或深蓝灰
		NameColor = Color3.fromRGB(20, 20, 30),

		Font = Enum.Font.GothamMedium,
		BoldFont = Enum.Font.GothamBold,
	},
	Sound = {
		TypeSoundId = "rbxassetid://9114704332",
		ClickSoundId = "rbxassetid://12221967",
	}
}

-- ================= 状态变量 =================
local dialogueQueue = {}
local isPlaying = false
local currentDialogue = nil
local isTyping = false
local skipRequested = false

-- ================= UI 创建逻辑 =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UnifiedDialogueGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = playerGui

-- 主框架
local MainFrame = Instance.new("Frame")
MainFrame.Name = "DialogueFrame"
MainFrame.Size = UDim2.new(0.6, 0, 0.25, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.88, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 1)
MainFrame.BackgroundColor3 = CONFIG.UI.BackgroundColor
MainFrame.BackgroundTransparency = 0.15 -- 保持半透明
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = CONFIG.UI.CornerRadius
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = CONFIG.UI.BorderColor
UIStroke.Thickness = CONFIG.UI.StrokeThickness
UIStroke.Transparency = 0.3
UIStroke.Parent = MainFrame

-- [修改] 渐变：从纯白到浅银灰
local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 230, 240))
}
UIGradient.Rotation = 90
UIGradient.Parent = MainFrame

-- 名字标签背景
local NameFrame = Instance.new("Frame")
NameFrame.Name = "NameFrame"
NameFrame.Size = UDim2.new(0, 200, 0, 40)
NameFrame.Position = UDim2.new(0, 0, 0, -35)
NameFrame.BackgroundColor3 = CONFIG.UI.BackgroundColor
NameFrame.BackgroundTransparency = 0.1 -- 名字框稍微不透明一点
NameFrame.BorderSizePixel = 0
NameFrame.Parent = MainFrame

local NameCorner = Instance.new("UICorner")
NameCorner.CornerRadius = UDim.new(0, 8)
NameCorner.Parent = NameFrame

local NameStroke = Instance.new("UIStroke")
NameStroke.Color = CONFIG.UI.BorderColor
NameStroke.Thickness = 2
NameStroke.Transparency = 0.3
NameStroke.Parent = NameFrame

local NameLabel = Instance.new("TextLabel")
NameLabel.Name = "NameLabel"
NameLabel.Size = UDim2.new(1, 0, 1, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Font = CONFIG.UI.BoldFont
NameLabel.TextSize = 20
NameLabel.TextColor3 = CONFIG.UI.NameColor
NameLabel.Text = "Speaker"
NameLabel.Parent = NameFrame

local ContentLabel = Instance.new("TextLabel")
ContentLabel.Name = "ContentLabel"
ContentLabel.Size = UDim2.new(0.95, 0, 0.8, 0)
ContentLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
ContentLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ContentLabel.BackgroundTransparency = 1
ContentLabel.Font = CONFIG.UI.Font
ContentLabel.TextSize = 22
ContentLabel.TextColor3 = CONFIG.UI.TextColor
ContentLabel.TextWrapped = true
ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
ContentLabel.RichText = true
ContentLabel.Parent = MainFrame

local PromptIcon = Instance.new("ImageLabel")
PromptIcon.Name = "PromptIcon"
PromptIcon.Size = UDim2.new(0, 30, 0, 30)
PromptIcon.Position = UDim2.new(1, -40, 1, -40)
PromptIcon.BackgroundTransparency = 1
PromptIcon.Image = "rbxassetid://6813296229"
PromptIcon.ImageColor3 = Color3.fromRGB(50, 50, 60) -- 图标改成深色以适应亮背景
PromptIcon.Visible = false
PromptIcon.Parent = MainFrame

local TypeSound = Instance.new("Sound")
TypeSound.SoundId = CONFIG.Sound.TypeSoundId
TypeSound.Volume = 0.5
TypeSound.Parent = ScreenGui

local ClickSound = Instance.new("Sound")
ClickSound.SoundId = CONFIG.Sound.ClickSoundId
ClickSound.Parent = ScreenGui

-- ================= 核心功能 (保持不变) =================
local function PlayDialogueStep(data)
	currentDialogue = data
	NameLabel.Text = data.Name or "System"
	ContentLabel.Text = data.Text or "..."
	ContentLabel.MaxVisibleGraphemes = 0

	MainFrame.Visible = true
	PromptIcon.Visible = false

	MainFrame.Size = UDim2.new(0.5, 0, 0.2, 0)
	TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0.6, 0, 0.25, 0)}):Play()

	isTyping = true
	skipRequested = false

	local textLength = utf8.len(ContentLabel.ContentText)
	for i = 1, textLength do
		if skipRequested then
			ContentLabel.MaxVisibleGraphemes = -1
			break
		end
		ContentLabel.MaxVisibleGraphemes = i
		if i % 3 == 0 then TypeSound:Play() end
		task.wait(CONFIG.TypewriterSpeed)
	end

	isTyping = false
	ContentLabel.MaxVisibleGraphemes = -1
	PromptIcon.Visible = true

	if data.Duration and data.Duration > 0 then
		task.wait(data.Duration)
	else
		local conn
		local continued = false
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
				input.UserInputType == Enum.UserInputType.Touch or 
				input.KeyCode == Enum.KeyCode.E then
				if isTyping then
					skipRequested = true
				else
					continued = true
					conn:Disconnect()
					ClickSound:Play()
				end
			end
		end)
		repeat task.wait() until continued
	end
end

local function ProcessQueue()
	if isPlaying then return end
	isPlaying = true
	while #dialogueQueue > 0 do
		local data = table.remove(dialogueQueue, 1)
		PlayDialogueStep(data)
	end
	TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.6, 0, 0, 0)}):Play()
	task.wait(0.2)
	MainFrame.Visible = false
	isPlaying = false
end

_G.ShowDialogue = function(text, name, duration)
	table.insert(dialogueQueue, {
		Text = text,
		Name = name,
		Duration = duration or 0
	})
	ProcessQueue()
end

local Event = Instance.new("BindableEvent")
Event.Name = "ShowDialogueEvent"
Event.Parent = ReplicatedStorage
Event.Event:Connect(function(text, name, duration)
	_G.ShowDialogue(text, name, duration)
end)

print("✅ UnifiedDialogueSystem (白金版) 已加载")