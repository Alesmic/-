print("Hello world!")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")
local player = Players.LocalPlayer
local gui = script.Parent -- 获取 HUDGui

-- ==========================================
-- 1. 获取 UI 引用 (根据你的结构)
-- ==========================================
-- 确保这些 Frame 都在 HUDGui 下面
local expFrame = gui:WaitForChild("ExpFrame")
local expText = expFrame:WaitForChild("ValueText")

local biomassFrame = gui:WaitForChild("BiomassFrame")
local biomassText = biomassFrame:WaitForChild("ValueText")

-- 尝试获取血条 (如果没做，脚本会自动创建临时的以免报错，但建议你手动做好)
local healthFrame = gui:FindFirstChild("HealthFrame")
local healthFill, healthText

if not healthFrame then
	warn("⚠️ 警告：未找到 HealthFrame，正在自动创建临时血条...")
	healthFrame = Instance.new("Frame", gui)
	healthFrame.Name = "HealthFrame"
	healthFrame.Size = UDim2.new(0, 200, 0, 25)
	healthFrame.Position = UDim2.new(0.5, -100, 0.85, 0) -- 屏幕底部居中
	healthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

	healthFill = Instance.new("Frame", healthFrame)
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- 红色
	healthFill.BorderSizePixel = 0

	healthText = Instance.new("TextLabel", healthFrame)
	healthText.Name = "ValueText"
	healthText.Size = UDim2.new(1,0,1,0)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.new(1,1,1)
	healthText.Font = Enum.Font.GothamBold
else
	healthFill = healthFrame:WaitForChild("Fill")
	healthText = healthFrame:WaitForChild("ValueText")
end

-- ==========================================
-- 2. 更新函数
-- ==========================================

-- 更新血量
local function updateHealth()
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")

	if humanoid then
		local hp = math.max(0, math.floor(humanoid.Health))
		local maxHp = math.floor(humanoid.MaxHealth)

		-- 动画过渡血条长度
		TweenService:Create(healthFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = UDim2.new(hp / maxHp, 0, 1, 0)
		}):Play()

		healthText.Text = "HP: " .. hp .. " / " .. maxHp
	end
end

-- ==========================================
-- 3. 事件监听
-- ==========================================

-- 监听角色重生 (重连 Humanoid)
player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.HealthChanged:Connect(updateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
		updateHealth()
	end
end)

-- 初始角色检查
if player.Character then
	local hum = player.Character:FindFirstChild("Humanoid")
	if hum then
		hum.HealthChanged:Connect(updateHealth)
		updateHealth()
	end
end

-- 监听服务器事件 (BioMatter 更新)
TutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "UpdateBioMatter" then
		biomassText.Text = tostring(data)
	elseif action == "UpdateXP" then
		expText.Text = "Exp: " .. tostring(data)
	end
end)