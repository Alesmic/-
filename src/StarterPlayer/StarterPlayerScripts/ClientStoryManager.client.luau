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

-- ================= 1. UI 引用 (动态获取) =================
-- 我们不再在脚本开头一次性死锁 UI，而是创建一个函数来动态获取
-- 这样即使玩家重生，UI 重置，脚本也能找到新的 UI
local function GetGameGui()
	return playerGui:FindFirstChild("GameGui")
end

local function GetUIElement(name, parent)
	if not parent then parent = GetGameGui() end
	if not parent then return nil end
	return parent:FindFirstChild(name, true) -- true 表示递归查找，防止层级变动找不到
end

-- 自动创建缺失 UI 的辅助函数
local function EnsureUI()
	local gui = GetGameGui()
	if not gui then return end

	-- 检查 HotbarArrow
	if not gui:FindFirstChild("HotbarArrow") then
		local arrow = Instance.new("ImageLabel")
		arrow.Name = "HotbarArrow"
		arrow.Image = "rbxassetid://6813296229"
		arrow.Size = UDim2.new(0, 50, 0, 50)
		arrow.Position = UDim2.new(0.5, -25, 0.9, -60)
		arrow.BackgroundTransparency = 1
		arrow.Visible = false
		arrow.Parent = gui
	end

	-- 检查 ControlsFrame
	if not gui:FindFirstChild("ControlsFrame") then
		local cf = Instance.new("Frame")
		cf.Name = "ControlsFrame"
		cf.Size = UDim2.new(0, 200, 0, 100)
		cf.Position = UDim2.new(1, -220, 0.8, 0)
		cf.BackgroundTransparency = 0.5
		cf.BackgroundColor3 = Color3.new(0,0,0)
		cf.Visible = false
		cf.Parent = gui

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1,0,1,0)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = Color3.new(1,1,1)
		txt.Text = "M1: Attack\nM2: Block\nShift: Sprint\nSpace: Jump"
		txt.Parent = cf
	end
end

-- ================= 2. NPC 与按键 =================
print("客户端：正在连接 NPC...")
local NPC = workspace:WaitForChild("BattlemasterNPC", 10)
if not NPC then warn("⚠️ 未找到 BattlemasterNPC！") end

local RootPart = NPC and NPC:WaitForChild("HumanoidRootPart")
local ProximityPrompt = RootPart and RootPart:WaitForChild("ProximityPrompt", 5)

if RootPart and not ProximityPrompt then
	warn("⚠️ 自动创建按键...")
	ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.Parent = RootPart
end

if ProximityPrompt then
	ProximityPrompt.ObjectText = "Battlemaster"
	ProximityPrompt.ActionText = "Train"
	ProximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	ProximityPrompt.RequiresLineOfSight = false 
	ProximityPrompt.MaxActivationDistance = 15
	ProximityPrompt.Enabled = false 
end

-- ================= 3. 音频与数据 =================
local SoundPlayer = Instance.new("Sound")
SoundPlayer.Name = "StorySoundPlayer"
SoundPlayer.Parent = script

local AUDIO_CLICK = "rbxassetid://12221967"
local AUDIO_VO_1_1 = "rbxassetid://117374101600882" 
local AUDIO_VO_1_2 = "rbxassetid://89718167229984" 
local AUDIO_VO_1_3 = "rbxassetid://9114704332"
local AUDIO_VO_2_1 = "rbxassetid://9114704332" 
local AUDIO_VO_2_2 = "rbxassetid://9114704332" 
local AUDIO_RETURN_LAB = "rbxassetid://116952830538871"
local AUDIO_VO_4_1 = "rbxassetid://0" -- 占位符

local SelectedWeaponIndex = 0
local WeaponData = {
	[1] = { Name = "Knight's Sword", Desc = "Speed: Medium\nDamage: Balanced", Id = "Sword" },
	[2] = { Name = "Heavy Axe",      Desc = "Speed: Slow\nDamage: High",     Id = "Axe" },
	[3] = { Name = "Elven Bow",      Desc = "Speed: Fast\nDamage: Low",      Id = "Bow" }
}

local weaponConnections = {}
local isSelecting = false
local objective3Started = false 

-- ================= ✨ 特效 ✨ =================
local blinkGui = nil 
local function StartBlinkingE()
	if not RootPart then return end
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
	if not zombieModel then return end
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
	local arrow = GetUIElement("HotbarArrow")
	if arrow then
		arrow.Visible = state
		if state then
			local tInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)
			TweenService:Create(arrow, tInfo, {ImageTransparency = 0.5}):Play()
		end
	end
end

-- ================= 逻辑函数 =================

local function PlayDialogue(text, audioId, pauseAfter, needClick)
	local dFrame = GetUIElement("DialogueFrame")
	if not dFrame then warn("UI丢失: DialogueFrame") return end

	local dText = dFrame:FindFirstChild("ContentText")
	local pIcon = dFrame:FindFirstChild("PromptIcon")

	-- 强制修正位置
	dFrame.Visible = true
	dFrame.AnchorPoint = Vector2.new(0.5, 1)
	dFrame.Position = UDim2.new(0.5, 0, 0.9, 0)

	local fullText = "Battlemaster Dialogue Box：\n" .. text

	if dText then
		dText.Text = "" -- 清空文本，准备打字机效果
		-- 强制修正文字位置
		dText.AnchorPoint = Vector2.new(0.5, 0.5)
		dText.Position = UDim2.new(0.5, 0, 0.5, 0)
		dText.Size = UDim2.new(0.95, 0, 0.9, 0)
		dText.TextXAlignment = Enum.TextXAlignment.Center
		dText.TextYAlignment = Enum.TextYAlignment.Center
	end

	if pIcon then pIcon.Visible = false end

	-- 播放音频
	local duration = 0
	if audioId then
		SoundPlayer.SoundId = audioId
		if not SoundPlayer.IsLoaded then ContentProvider:PreloadAsync({SoundPlayer}) end
		SoundPlayer:Play()
		duration = SoundPlayer.TimeLength
		if duration <= 0 then duration = 2 end
	end

	-- 监听点击跳过
	local isSkipping = false
	local skipConn
	skipConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isSkipping = true
		end
	end)

	-- 1. 打字机效果
	if dText then
		for i = 1, #fullText do
			if isSkipping then
				dText.Text = fullText
				break
			end
			dText.Text = string.sub(fullText, 1, i)
			task.wait(0.03)
		end
	end

	-- 重置跳过状态 (防止一次点击跳过所有阶段)
	if isSkipping then
		isSkipping = false
		task.wait(0.1) 
	end

	-- 2. 等待音频/暂停 (支持跳过)
	local totalWait = duration + pauseAfter
	local timer = 0
	while timer < totalWait do
		if isSkipping then
			if SoundPlayer.IsPlaying then SoundPlayer:Stop() end
			break
		end
		local dt = task.wait()
		timer = timer + dt
	end

	if skipConn then skipConn:Disconnect() end

	if needClick and pIcon then
		pIcon.Visible = true
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

-- ================= 流程函数 =================

local function InitiateObjective3()
	print(">>> 目标 #2 完成，进入过渡阶段 <<<")
	PlayDialogue("Hello, example. Please return to your lab for instruction.", AUDIO_RETURN_LAB, 4, false)
	task.wait(1)
	TutorialEvent:FireServer("MoveToLab")

	local objFrame = GetUIElement("ObjectiveFrame")
	local ctrlFrame = GetUIElement("ControlsFrame")
	if objFrame then objFrame.Visible = false end
	if ctrlFrame then ctrlFrame.Visible = false end
end

local function StartObjective4()
	print("🚀 目标 #4 流程启动")
	PlayDialogue("Your collected mutagen extracts can be synthesized...", AUDIO_VO_4_1, 0, true)

	local dFrame = GetUIElement("DialogueFrame")
	if dFrame then dFrame.Visible = false end

	local objFrame = GetUIElement("ObjectiveFrame")
	if objFrame then
		local title = objFrame:FindFirstChild("Title")
		if title then title.Text = "NEW OBJECTIVE\nSynthesize Extracts" end
		objFrame.Visible = true
	end
end

local function StartObjective2()
	print("🚀 目标 #2 流程启动")
	PlayDialogue("Before engaging the enemy, be ready to draw your weapon at any moment.", AUDIO_VO_2_1, 0, true)

	local dFrame = GetUIElement("DialogueFrame")
	if dFrame then dFrame.Visible = false end

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

	PlayDialogue("Practice using your weapon on the Zombie we captured...", AUDIO_VO_2_2, 0, true)
	if dFrame then dFrame.Visible = false end

	local objFrame = GetUIElement("ObjectiveFrame")
	if objFrame then
		local title = objFrame:FindFirstChild("Title")
		if title then title.Text = "NEW OBJECTIVE\nKill and loot Zombie" end
		objFrame.Visible = true
	end

	TutorialEvent:FireServer("SpawnZombie")
	local ctrlFrame = GetUIElement("ControlsFrame")
	if ctrlFrame then ctrlFrame.Visible = true end
end

-- ================= 修复：武器选择按钮逻辑 =================
local function SetupWeaponButtons()
	-- 重新获取 UI 引用 (防止 nil)
	local WeaponFrame = GetUIElement("WeaponSelectionFrame")
	if not WeaponFrame then warn("❌ UI 错误：找不到 WeaponSelectionFrame") return end

	local InfoPanel = WeaponFrame:FindFirstChild("InfoPanel", true) -- 递归查找
	if not InfoPanel then warn("❌ UI 错误：找不到 InfoPanel") return end

	local StatsText = InfoPanel:FindFirstChild("StatsText")
	local SelectButton = InfoPanel:FindFirstChild("SelectButton")

	-- 1. 断开旧连接
	for _, conn in pairs(weaponConnections) do
		if conn then conn:Disconnect() end
	end
	weaponConnections = {}
	isSelecting = false 

	-- 2. 绑定武器按钮
	for i = 1, 3 do
		local btn = WeaponFrame:FindFirstChild("Weapon"..i, true) -- 递归查找，确保能找到
		if btn and btn:IsA("GuiButton") then
			btn.BorderSizePixel = 0
			local conn = btn.MouseButton1Click:Connect(function()
				SelectedWeaponIndex = i
				SoundPlayer.SoundId = AUDIO_CLICK
				SoundPlayer:Play()

				-- UI 更新
				for j = 1, 3 do
					local other = WeaponFrame:FindFirstChild("Weapon"..j, true)
					if other then other.BorderSizePixel = 0 end
				end
				btn.BorderSizePixel = 5
				btn.BorderColor3 = Color3.fromRGB(255, 215, 0)

				InfoPanel.Visible = true
				if StatsText then
					local data = WeaponData[i]
					StatsText.Text = data.Name .. "\n\n" .. data.Desc
				end
			end)
			table.insert(weaponConnections, conn)
		else
			warn("⚠️ 警告：找不到 Weapon"..i.." 或者它不是按钮")
		end
	end

	-- 3. 绑定确认按钮
	if SelectButton then
		local selectConn = SelectButton.MouseButton1Click:Connect(function()
			if isSelecting then return end
			if SelectedWeaponIndex == 0 then return end

			isSelecting = true 
			SoundPlayer.SoundId = AUDIO_CLICK
			SoundPlayer:Play()

			WeaponFrame.Visible = false
			InfoPanel.Visible = false
			TutorialEvent:FireServer("GiveWeapon", WeaponData[SelectedWeaponIndex].Id)

			PlayDialogue("A fine weapon choice...", AUDIO_VO_1_3, 0, true)

			local dFrame = GetUIElement("DialogueFrame")
			if dFrame then dFrame.Visible = false end

			StartObjective2()
		end)
		table.insert(weaponConnections, selectConn)
	else
		warn("❌ 错误：找不到 SelectButton")
	end
end

-- ================= 主流程 =================
local function StartObjective1()
	print("🚀 目标 #1 流程启动")
	EnsureUI() -- 确保 UI 存在

	if not TEST_MODE then
		PlayDialogue("Welcome young exemplar...", AUDIO_VO_1_1, 3, false)
		PlayDialogue("Your weapon defines your combat style...", AUDIO_VO_1_2, 0, true)
		local dFrame = GetUIElement("DialogueFrame")
		if dFrame then dFrame.Visible = false end
		SoundPlayer:Stop()
	end

	local objFrame = GetUIElement("ObjectiveFrame")
	if objFrame then
		local title = objFrame:FindFirstChild("Title")
		if title then title.Text = "NEW OBJECTIVE\nChoose Your Weapon" end
		objFrame.Visible = true
	end

	if ProximityPrompt then
		ProximityPrompt.Enabled = true
		StartBlinkingE()
		print("✅ E 键高亮闪烁已激活")
	end
end

-- ================= 事件监听 =================
if ProximityPrompt then
	ProximityPrompt.Triggered:Connect(function()
		local objFrame = GetUIElement("ObjectiveFrame")
		if objFrame then objFrame.Visible = false end

		ProximityPrompt.Enabled = false 
		StopBlinkingE()

		local WeaponFrame = GetUIElement("WeaponSelectionFrame")
		if WeaponFrame then
			WeaponFrame.Visible = true
			SetupWeaponButtons() -- 现在这里很安全
		else
			warn("❌ 触发失败：WeaponSelectionFrame 不存在")
		end
	end)
end

TutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "StartObjective1" then
		StartObjective1()
	elseif action == "MarkZombie" then
		MarkZombie(data)
	elseif action == "StartObjective4" then
		StartObjective4()
	elseif action == "LootPickedUp" then
		lootCount = lootCount + 1
		print("捡到了 " .. lootCount .. " 个物品")
		if lootCount >= 5 and not objective3Started then
			objective3Started = true
			InitiateObjective3()
		end
	end
end)