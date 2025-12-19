local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hudGui = playerGui:WaitForChild("HUDGui")
local mainFrame = hudGui:FindFirstChild("MainFrame") or hudGui

-- ================= 辅助函数 =================
local function FindTextLabel(frame, nameForLog)
	if not frame then return nil end
	local label = frame:FindFirstChild("AmountLabel") or 
		frame:FindFirstChild("TextLabel") or 
		frame:FindFirstChild("Amount") or
		frame:FindFirstChild("Value")

	if not label then
		label = frame:FindFirstChildWhichIsA("TextLabel", true)
	end
	return label
end

-- ================= UI 引用 =================
local moneyFrame = mainFrame:FindFirstChild("MoneyFrame")
local moneyText = FindTextLabel(moneyFrame, "MoneyFrame")

local bioFrame = mainFrame:FindFirstChild("BiomassFrame")
local bioText = FindTextLabel(bioFrame, "BiomassFrame")

-- [修改] 查找 ExpFrame (兼容 XPFrame 名字)
local expFrame = mainFrame:FindFirstChild("ExpFrame") or mainFrame:FindFirstChild("XPFrame")
local expText = FindTextLabel(expFrame, "ExpFrame")

local healthFrame = mainFrame:FindFirstChild("HealthFrame")
local healthBar = healthFrame and (healthFrame:FindFirstChild("HealthBar") or healthFrame:FindFirstChild("Bar"))

-- ================= 更新函数 =================
local function UpdateMTC(value)
	if moneyText then moneyText.Text = tostring(value) end
end

local function UpdateBiomass(value)
	if bioText then bioText.Text = tostring(value) end
end

-- [修改] 更新 Exp 显示
local function UpdateExp(value)
	if expText then
		expText.Text = "Exp: " .. tostring(value)
	end
end

-- ================= 数据监听 =================
local leaderstats = player:WaitForChild("leaderstats", 10)
if leaderstats then
	local mtc = leaderstats:WaitForChild("MTC", 5)
	if mtc then
		UpdateMTC(mtc.Value)
		mtc.Changed:Connect(UpdateMTC)
	end

	local bio = leaderstats:WaitForChild("Biomass", 5)
	if bio then
		UpdateBiomass(bio.Value)
		bio.Changed:Connect(UpdateBiomass)
	end

	-- [修改] 监听 Exp
	local expStat = leaderstats:FindFirstChild("Exp") -- 查找 Exp
	if expStat then
		UpdateExp(expStat.Value)
		expStat.Changed:Connect(UpdateExp)
	end
end

local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent", 10)
if TutorialEvent then
	TutorialEvent.OnClientEvent:Connect(function(action, value)
		if action == "UpdateBioMatter" then
			UpdateBiomass(value)
		elseif action == "UpdateExp" then -- [修改] 监听 UpdateExp
			UpdateExp(value)
		end
	end)
end

-- 血量监听
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function UpdateHealth()
	if healthBar then
		local percent = humanoid.Health / humanoid.MaxHealth
		healthBar.Size = UDim2.new(percent, 0, 1, 0)
	end
end

if humanoid then
	humanoid.HealthChanged:Connect(UpdateHealth)
	UpdateHealth()
end

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(UpdateHealth)
	UpdateHealth()
end)