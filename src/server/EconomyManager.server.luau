local Players = game:GetService("Players")

local STARTING_BALANCE = 1500

local function onPlayerAdded(player)
    -- Create Leaderstats Folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    -- Create Money Value (Rupees)
    local rupees = Instance.new("IntValue")
    rupees.Name = "Rupees"
    rupees.Value = STARTING_BALANCE
    rupees.Parent = leaderstats
    
    print(player.Name .. " has joined with ₹" .. rupees.Value)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle existing players (for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
