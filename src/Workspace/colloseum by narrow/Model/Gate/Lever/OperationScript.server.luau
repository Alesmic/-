local divs = 32
local time = 0.5
local dist = math.pi / 2

local progress = 0
local direction = 1

function positionLever(angle)
	local base = script.Parent.LeverBase.CFrame
	local transform = CFrame.fromEulerAnglesXYZ(angle, 0, 0) * CFrame.new(0, -0.4, 0)

	script.Parent.Lever.CFrame = (base * CFrame.new(0, 0.5, 0)) * transform
end

local ang = math.pi / 4
positionLever(ang)
script.Parent.Lever.ClickDetector.MouseClick:connect(function()
	if progress ~= 0 then return end

	direction = -direction

	while true do
		if progress >= divs then
			script.Parent.UpDown.Value = not script.Parent.UpDown.Value
			progress = 0 
			break 
		end
script.Parent.Lever.Sound:Play()


		progress = progress + 1

		ang = ang + ((dist / divs) * direction)
		positionLever(ang)

		wait(time / divs)



	end
end)