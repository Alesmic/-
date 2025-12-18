local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SynthesizeEvent = ReplicatedStorage:WaitForChild("SynthesizeEvent")
local TutorialEvent = ReplicatedStorage:WaitForChild("TutorialEvent")

SynthesizeEvent.OnServerEvent:Connect(function(player)
	local ls = player:FindFirstChild("leaderstats")
	local mtc = ls and ls:FindFirstChild("MTC")

	-- 检查并扣费 300 MTC 
	if mtc and mtc.Value >= 300 then
		mtc.Value -= 300
		print("扣费成功，合成完成")

		-- 可以在这里给玩家发道具...

		-- 触发下一个目标：Objective #5 
		-- 注意：这里你可能需要先定义 Objective5 的逻辑，或者只打印提示
		print("触发 Objective #5: 升级实验台")
		-- TutorialEvent:FireClient(player, "InitiateObjective5")
	else
		print("余额不足！")
	end
end)
