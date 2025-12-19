local progress = 0
local direction = -1.7

local divs = 256
local time = 5
local distance = 10

script.Parent.Open.Changed:connect(function(value)
	if script.Parent.Open.Value == false then return end
	script.Parent.Open.Value = false

	if progress ~= 0 then return end

	direction = -direction

	local now_direction = direction
	while true do

		if now_direction ~= direction then break end
		if progress >= divs then progress = 0 break end

		progress = progress + 1
		
		local move_amount = distance / divs
		for _,v in ipairs(script.Parent.Portcullis:GetChildren()) do
			v.CFrame = v.CFrame + Vector3.new(0, move_amount * direction, 0)
		end
		
		wait(target_time)
	end
end)