local Humanoid = script.Parent.Zombie 
function PwntX_X() 
local tag = Humanoid:findFirstChild("creator") 
if tag ~= nil then 
if tag.Value ~= nil then 
local Leaderstats = tag.Value:findFirstChild("leaderstats") 
if Leaderstats ~= nil then 
Leaderstats.Money.Value = Leaderstats.Money.Value + 25 --Change Money to the stat that is increased. 
wait(0.1) 
script:remove() 
end 
end 
end 
end 
Humanoid.Died:connect(PwntX_X) 