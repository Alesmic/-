local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 引入配置
local GameConfigModule = ReplicatedStorage:WaitForChild("GameConfig", 10)
if not GameConfigModule then warn("⚠️ 警告：未找到 GameConfig，部分功能可能失效") end
local GameConfig = require(GameConfigModule)

-- 安全获取事件
local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent", 30)
if not TutorialEvent then warn("❌ 严重错误：等待 TutorialEvent 超时！") end

-- 🔥 调试开关
local TEST_MODE = false 

-- ================= 变量定义 (关键修复) =================
local lootCount = 0  -- 【修复】必须初始化为 0
local TOTAL_LOOT_NEEDED = 5 -- 默认值

-- 尝试从配置读取总数
if GameConfig and GameConfig.GetTotalLootCount then
	TOTAL_LOOT_NEEDED = GameConfig.GetTotalLootCount()
elseif GameConfig and GameConfig.Mobs and GameConfig.Mobs["Elite Zombie"] then
	-- 如果没有辅助函数，手动计算 (根据你的 Config 结构)
	local drops = GameConfig.Mobs["Elite Zombie"].Drops
	local sum = 0
	if drops then
		for _, d in ipairs(drops) do sum = sum + d.Amount end
	end
	if sum > 0 then TOTAL_LOOT_NEEDED = sum end
end

local objective3Started = false 
local weaponConnections = {}
local isSelecting = false
local SelectedWeaponIndex = 0

local WeaponData = {
	[1] = { Name = "Knight's Sword", Desc = "Speed: Medium\nDamage: Balanced", Id = "Sword" },
	[2] = { Name = "Heavy Axe",      Desc = "Speed: Slow\nDamage: High",     Id = "Axe" },
	[3] = { Name = "Elven Bow",      Desc = "Speed: Fast\nDamage: Low",      Id = "Bow" }
}

local AUDIO_CLICK = "rbxassetid://12221967"
local AUDIO_RETURN_LAB = "rbxassetid://116952830538871"
local AUDIO_VO_2_2 = "rbxassetid://9114704332"
local AUDIO_VO_4_1 = "rbxassetid://0" 

local SoundPlayer = Instance.new("Sound")
SoundPlayer.Name = "StorySoundPlayer"
SoundPlayer.Parent = script

-- ================= 1. UI 引用 (动态获取) =================
local function GetGameGui()
	return playerGui:FindFirstChild("GameGui")
end

local function GetUIElement(name, parent)
	if not parent then parent = GetGameGui() end
	if not parent then return nil end
	return parent:FindFirstChild(name, true) 
end

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

-- ================= ✨ 特效与弹窗 ✨ =================

local function ShowLootNotification(itemName)
	local gui = GetGameGui()
	if not gui then return end

	local notifyFrame = gui:FindFirstChild("NotifyContainer")
	if not notifyFrame then
		notifyFrame = Instance.new("Frame")
		notifyFrame.Name = "NotifyContainer"
		notifyFrame.Size = UDim2.new(0, 200, 0, 300)
		notifyFrame.Position = UDim2.new(1, -220, 1, -320)
		notifyFrame.BackgroundTransparency = 1
		notifyFrame.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.Parent = notifyFrame
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Padding = UDim.new(0, 5)
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 40)
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.Text = "+1 " .. tostring(itemName)
	label.Parent = notifyFrame

	task.delay(2, function()
		if label and label.Parent then
			local tween = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})
			tween:Play()
			tween.Completed:Connect(function() label:Destroy() end)
		end
	end)
end

local function MarkZombie(zombieModel)
	if not zombieModel then return end
	local arrow = Instance.new("BillboardGui")
	arrow.Name = "ZombieArrow"
	arrow.Size = UDim2.new(0,60,0,60)
	arrow.StudsOffset = Vector3.new(0, 5, 0)
	arrow.AlwaysOnTop = true
	arrow.Parent = zombieModel.PrimaryPart or zombieModel:FindFirstChild("Head")

	local img = Instance.new("ImageLabel", arrow)
	img.Size, img.BackgroundTransparency = UDim2.new(1,0,1,0), 1
	img.Image = "rbxassetid://6813296229" 
	img.ImageColor3 = Color3.fromRGB(255, 50, 50)

	local tInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(arrow, tInfo, {StudsOffset = Vector3.new(0, 4, 0)}):Play()
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
	if not dFrame then return end

	local dText = dFrame:FindFirstChild("ContentText")
	local pIcon = dFrame:FindFirstChild("PromptIcon")

	dFrame.Visible = true
	dFrame.AnchorPoint = Vector2.new(0.5, 1)
	dFrame.Position = UDim2.new(0.5, 0, 0.9, 0)

	if dText then
		dText.Text = "Battlemaster Dialogue Box：\n" .. text
		dText.AnchorPoint = Vector2.new(0.5, 0.5)
		dText.Position = UDim2.new(0.5, 0, 0.5, 0)
		dText.Size = UDim2.new(0.95, 0, 0.9, 0)
		dText.TextXAlignment = Enum.TextXAlignment.Center
	end

	if pIcon then pIcon.Visible = false end

	if audioId and audioId ~= "rbxassetid://0" then
		SoundPlayer.SoundId = audioId
		if not SoundPlayer.IsLoaded then ContentProvider:PreloadAsync({SoundPlayer}) end
		SoundPlayer:Play()
		local duration = SoundPlayer.TimeLength
		if duration > 0 then task.wait(duration) else task.wait(2) end
	end

	if pauseAfter > 0 then task.wait(pauseAfter) end

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
	PlayDialogue("Excellent work. Please return to the lab.", AUDIO_RETURN_LAB, 3, false)
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

	PlayDialogue("Practice using your weapon on the Zombies...", AUDIO_VO_2_2, 0, true)
	if dFrame then dFrame.Visible = false end

	local objFrame = GetUIElement("ObjectiveFrame")
	if objFrame then
		local title = objFrame:FindFirstChild("Title")
		if title then title.Text = "NEW OBJECTIVE\nEliminate Hostiles" end
		objFrame.Visible = true
	end

	TutorialEvent:FireServer("SpawnZombie")
	local ctrlFrame = GetUIElement("ControlsFrame")
	if ctrlFrame then ctrlFrame.Visible = true end
end

-- ================= 武器选择按钮逻辑 =================
local function SetupWeaponButtons()
	local WeaponFrame = GetUIElement("WeaponSelectionFrame")
	if not WeaponFrame then warn("❌ UI 错误：找不到 WeaponSelectionFrame") return end

	local InfoPanel = WeaponFrame:FindFirstChild("InfoPanel", true)
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
		local btn = WeaponFrame:FindFirstChild("Weapon"..i, true)
		if btn and btn:IsA("GuiButton") then
			btn.BorderSizePixel = 0
			local conn = btn.MouseButton1Click:Connect(function()
				SelectedWeaponIndex = i
				SoundPlayer.SoundId = AUDIO_CLICK
				SoundPlayer:Play()

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
			StartObjective2()
		end)
		table.insert(weaponConnections, selectConn)
	end
end

-- ================= 主流程 (无音频速通版) =================
local function StartObjective1()
	print("🚀 目标 #1 流程启动 (无音频版)")
	EnsureUI() 

	task.wait(0.5)

	local WeaponFrame = GetUIElement("WeaponSelectionFrame")
	if WeaponFrame then
		local objFrame = GetUIElement("ObjectiveFrame")
		if objFrame then objFrame.Visible = false end

		WeaponFrame.Visible = true
		SetupWeaponButtons()
		print("✅ 已自动跳过对话，直接打开武器选择界面。")
	else
		warn("❌ 自动弹窗失败：找不到 WeaponSelectionFrame")
	end
end

-- ================= 事件监听 =================
TutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "StartObjective1" then
		StartObjective1()

	elseif action == "MarkZombie" then
		MarkZombie(data)

	elseif action == "StartObjective4" then
		StartObjective4()

	elseif action == "LootPickedUp" then
		-- data 现在是物品名称 (String)
		local itemName = data
		ShowLootNotification(itemName)

		lootCount = lootCount + 1 -- 【修复】变量现在已定义，不会报错
		print("捡到了 " .. lootCount .. " / " .. TOTAL_LOOT_NEEDED .. " 个物品")

		if lootCount >= TOTAL_LOOT_NEEDED and not objective3Started then
			objective3Started = true
			InitiateObjective3()
		end
	end
end)