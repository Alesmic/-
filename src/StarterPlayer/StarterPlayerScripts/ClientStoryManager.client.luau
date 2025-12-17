local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")

-- 🔥 调试开关
local TEST_MODE = false 

-- ================= 1. UI 引用 (防卡死系统) =================
print("客户端：正在查找 UI...")
local GameGui = playerGui:WaitForChild("GameGui")

local DialogueFrame = GameGui:WaitForChild("DialogueFrame")
local DialogueText = DialogueFrame:WaitForChild("ContentText")
local PromptIcon = DialogueFrame:WaitForChild("PromptIcon")
local ObjectiveFrame = GameGui:WaitForChild("ObjectiveFrame")
local ObjectiveTitle = ObjectiveFrame:WaitForChild("Title")

local WeaponFrame = GameGui:WaitForChild("WeaponSelectionFrame")
local InfoPanel = WeaponFrame:WaitForChild("InfoPanel")
local StatsText = InfoPanel:WaitForChild("StatsText")
local SelectButton = InfoPanel:WaitForChild("SelectButton")

-- 🛑【修复】尝试查找新 UI，如果找不到，自动创建！🛑
local HotbarArrow = GameGui:FindFirstChild("HotbarArrow")
if not HotbarArrow then
	warn("⚠️ 未找到 HotbarArrow，正在自动创建...")
	HotbarArrow = Instance.new("ImageLabel")
	HotbarArrow.Name = "HotbarArrow"
	HotbarArrow.Image = "rbxassetid://6813296229" -- 红色箭头
	HotbarArrow.Size = UDim2.new(0, 50, 0, 50)
	HotbarArrow.Position = UDim2.new(0.5, -25, 0.9, -60) -- 底部居中
	HotbarArrow.BackgroundTransparency = 1
	HotbarArrow.Visible = false
	HotbarArrow.Parent = GameGui
end

local ControlsFrame = GameGui:FindFirstChild("ControlsFrame")
if not ControlsFrame then
	warn("⚠️ 未找到 ControlsFrame，正在自动创建...")
	ControlsFrame = Instance.new("Frame")
	ControlsFrame.Name = "ControlsFrame"
	ControlsFrame.Size = UDim2.new(0, 200, 0, 100)
	ControlsFrame.Position = UDim2.new(1, -220, 0.8, 0) -- 右下角
	ControlsFrame.BackgroundTransparency = 0.5
	ControlsFrame.BackgroundColor3 = Color3.new(0,0,0)
	ControlsFrame.Visible = false
	ControlsFrame.Parent = GameGui

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.TextColor3 = Color3.new(1,1,1)
	txt.Text = "M1: Attack\nM2: Block\nShift: Sprint\nSpace: Jump"
	txt.Parent = ControlsFrame
end

-- ================= 2. NPC 与按键 =================
print("客户端：正在连接 NPC...")
local NPC = workspace:WaitForChild("BattlemasterNPC")
local RootPart = NPC:WaitForChild("HumanoidRootPart")
local ProximityPrompt = RootPart:WaitForChild("ProximityPrompt", 5)

if not ProximityPrompt then
	warn("⚠️ 自动创建按键...")
	ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.Parent = RootPart
end

ProximityPrompt.ObjectText = "Battlemaster"
ProximityPrompt.ActionText = "Train"
ProximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
ProximityPrompt.RequiresLineOfSight = false 
ProximityPrompt.MaxActivationDistance = 15
ProximityPrompt.Enabled = false 

-- ================= 3. 音频与数据 =================
local SoundPlayer = Instance.new("Sound")
SoundPlayer.Parent = script

local AUDIO_CLICK = "rbxassetid://12221967"
-- Objective 1
local AUDIO_VO_1_1 = "rbxassetid://117374101600882" 
local AUDIO_VO_1_2 = "rbxassetid://89718167229984" 
local AUDIO_VO_1_3 = "rbxassetid://9114704332"
-- Objective 2
local AUDIO_VO_2_1 = "rbxassetid://9114704332" 
local AUDIO_VO_2_2 = "rbxassetid://9114704332" 

local SelectedWeaponIndex = 0
local WeaponData = {
	[1] = { Name = "Knight's Sword", Desc = "Speed: Medium\nDamage: Balanced", Id = "Sword" },
	[2] = { Name = "Heavy Axe",      Desc = "Speed: Slow\nDamage: High",     Id = "Axe" },
	[3] = { Name = "Elven Bow",      Desc = "Speed: Fast\nDamage: Low",      Id = "Bow" }
}

-- ================= ✨ 特效 ✨ =================
local blinkGui = nil 
local function StartBlinkingE()
	if blinkGui then blinkGui:Destroy() end
	blinkGui = Instance.new("BillboardGui")
	blinkGui.Name = "BlinkingE"
	blinkGui.Size = UDim2.new(0, 50, 0, 50)
	blinkGui.StudsOffset = Vector3.new(0, 3.5, 0)
	blinkGui.AlwaysOnTop = true
	blinkGui.Parent = RootPart

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1,0,1,0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "E"
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.Parent = blinkGui

	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(textLabel, tweenInfo, {TextTransparency = 0.7}):Play()
end

local function StopBlinkingE()
	if blinkGui then blinkGui:Destroy() blinkGui = nil end
end

local zombieArrow = nil
local function MarkZombie(zombieModel)
	if zombieArrow then zombieArrow:Destroy() end
	zombieArrow = Instance.new("BillboardGui")
	zombieArrow.Size = UDim2.new(0,60,0,60)
	zombieArrow.StudsOffset = Vector3.new(0, 5, 0)
	zombieArrow.AlwaysOnTop = true
	zombieArrow.Parent = zombieModel.PrimaryPart or zombieModel:FindFirstChild("Head")

	local img = Instance.new("ImageLabel", zombieArrow)
	img.Size, img.BackgroundTransparency = UDim2.new(1,0,1,0), 1
	img.Image = "rbxassetid://6813296229" 
	img.ImageColor3 = Color3.fromRGB(255, 50, 50)

	local tInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(zombieArrow, tInfo, {StudsOffset = Vector3.new(0, 4, 0)}):Play()
end

local function ToggleHotbarArrow(state)
	if HotbarArrow then
		HotbarArrow.Visible = state
		if state then
			local tInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)
			TweenService:Create(HotbarArrow, tInfo, {ImageTransparency = 0.5}):Play()
		end
	end
end

-- ================= 逻辑函数 =================

local function PlayDialogue(text, audioId, pauseAfter, needClick)
	DialogueFrame.Visible = true
	PromptIcon.Visible = false
	DialogueText.Text = "Battlemaster Dialogue Box：\n" .. text

	if audioId then
		SoundPlayer.SoundId = audioId
		if not SoundPlayer.IsLoaded then ContentProvider:PreloadAsync({SoundPlayer}) end
		SoundPlayer:Play()
		local duration = SoundPlayer.TimeLength
		if duration > 0 then task.wait(duration) else task.wait(2) end
	end

	if pauseAfter > 0 then task.wait(pauseAfter) end

	if needClick then
		PromptIcon.Visible = true
		local clicked = false
		local con
		con = UserInputService.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				clicked = true
				con:Disconnect()
			end
		end)
		repeat task.wait() until clicked
	end
end

-- ================= 目标 2 =================
local lootCount = 0
local function InitiateObjective3()
	print(">>> 进入目标 #3 <<<")
	ObjectiveTitle.Text = "NEW OBJECTIVE\nCraft at Lab Bench"
	ObjectiveFrame.Visible = true
	if ControlsFrame then ControlsFrame.Visible = false end
end

local function StartObjective2()
	print("🚀 目标 #2 流程启动")
	PlayDialogue("Before engaging the enemy, be ready to draw your weapon at any moment.", AUDIO_VO_2_1, 0, true)
	DialogueFrame.Visible = false

	ToggleHotbarArrow(true)

	local character = player.Character or player.CharacterAdded:Wait()
	local weaponEquipped = false

	if character:FindFirstChildWhichIsA("Tool") then weaponEquipped = true end
	if not weaponEquipped then
		local equipConn
		equipConn = character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then weaponEquipped = true equipConn:Disconnect() end
		end)
		repeat task.wait() until weaponEquipped
	end

	ToggleHotbarArrow(false)

	PlayDialogue("Practice using your weapon on the Zombie we captured. Once eliminated, look for mutation extracts and collect all bio-matter for salvage. ∇", AUDIO_VO_2_2, 0, true)
	DialogueFrame.Visible = false

	ObjectiveTitle.Text = "NEW OBJECTIVE\nKill and loot Zombie"
	ObjectiveFrame.Visible = true

	TutorialEvent:FireServer("SpawnZombie")
	if ControlsFrame then ControlsFrame.Visible = true end
end

-- ================= 目标 1 =================
local function SetupWeaponButtons()
	for i = 1, 3 do
		local btn = WeaponFrame:FindFirstChild("Weapon"..i)
		if btn then
			btn.BorderSizePixel = 0
			btn.MouseButton1Click:Connect(function()
				SelectedWeaponIndex = i
				SoundPlayer.SoundId = AUDIO_CLICK
				if not SoundPlayer.IsLoaded then ContentProvider:PreloadAsync({SoundPlayer}) end
				SoundPlayer:Play()
				for j = 1, 3 do
					local other = WeaponFrame:FindFirstChild("Weapon"..j)
					if other then other.BorderSizePixel = 0 end
				end
				btn.BorderSizePixel = 5
				btn.BorderColor3 = Color3.fromRGB(255, 215, 0)
				InfoPanel.Visible = true
				local data = WeaponData[i]
				StatsText.Text = data.Name .. "\n\n" .. data.Desc
			end)
		end
	end

	SelectButton.MouseButton1Click:Connect(function()
		if SelectedWeaponIndex == 0 then return end
		SoundPlayer.SoundId = AUDIO_CLICK
		SoundPlayer:Play()

		WeaponFrame.Visible = false
		InfoPanel.Visible = false
		TutorialEvent:FireServer("GiveWeapon", WeaponData[SelectedWeaponIndex].Id)

		PlayDialogue("A fine weapon choice. As you grow in power, so will your mastery with your weapon. ∇", AUDIO_VO_1_3, 0, true)
		DialogueFrame.Visible = false

		StartObjective2()
	end)
end

-- ================= 主流程 =================
local function StartObjective1()
	print("🚀 目标 #1 流程启动")

	if not TEST_MODE then
		PlayDialogue("Welcome young exemplar. You will need to rely on weapons against the Reavers until you are strong enough.", AUDIO_VO_1_1, 3, false)
		PlayDialogue("Your weapon defines your combat style and will be part of your identity. Each weapon has its own pros and cons. So, choose carefully. ∇", AUDIO_VO_1_2, 0, true)
		DialogueFrame.Visible = false
		SoundPlayer:Stop()
	end

	ObjectiveTitle.Text = "NEW OBJECTIVE\nChoose Your Weapon"
	ObjectiveFrame.Visible = true

	if ProximityPrompt then
		ProximityPrompt.Enabled = true
		StartBlinkingE()
		print("✅ E 键高亮闪烁已激活")
	end
end

-- ================= 事件监听 =================
if ProximityPrompt then
	ProximityPrompt.Triggered:Connect(function()
		ObjectiveFrame.Visible = false
		ProximityPrompt.Enabled = false 
		StopBlinkingE()
		WeaponFrame.Visible = true
		SetupWeaponButtons()
	end)
end

TutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "StartObjective1" then
		StartObjective1()
	elseif action == "MarkZombie" then
		MarkZombie(data)
	elseif action == "LootPickedUp" then
		lootCount = lootCount + 1
		print("捡到了 " .. lootCount .. " 个物品")
		if lootCount >= 5 then
			InitiateObjective3()
		end
	end
end)