print("Hello world!")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent -- 获取 HUDGui

-- ==========================================
-- 1. 获取 UI 引用 (根据你的结构)
-- ==========================================
-- 确保这些 Frame 都在 HUDGui 下面
local moneyFrame = gui:WaitForChild("MoneyFrame")
local moneyText = moneyFrame:WaitForChild("ValueText") -- 假设显示文字的 Label 叫 ValueText

local expFrame = gui:WaitForChild("ExpFrame")
local expText = expFrame:WaitForChild("ValueText")

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

-- 更新金钱和经验 (监听 leaderstats)
local function updateStats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	-- 获取数据对象
	local moneyObj = leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("BioMatter") -- 兼容你的变量名
	local expObj = leaderstats:FindFirstChild("XP") or leaderstats:FindFirstChild("Experience")
	local levelObj = leaderstats:FindFirstChild("Level") -- 假设有等级

	-- 1. 更新金钱
	if moneyObj then
		moneyText.Text = "Money: " .. moneyObj.Value
	else
		moneyText.Text = "Money: --"
	end

	-- 2. 更新经验
	-- 这里根据你的需求，如果只想显示数字：
	if expObj then
		local val = expObj.Value
		-- 如果有等级，一起显示
		if levelObj then
			expText.Text = "Level " .. levelObj.Value .. " | Exp: " .. val
		else
			expText.Text = "Exp: " .. val
		end
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

-- 监听数据变化 (Money / Exp)
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 999)
	if not leaderstats then return end

	-- 监听所有子对象的变化
	for _, stat in pairs(leaderstats:GetChildren()) do
		stat.Changed:Connect(updateStats)
	end

	-- 初始更新一次
	updateStats()
end)