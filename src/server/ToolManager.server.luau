local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder")
Remotes.Name = "Shared"
Remotes.Parent = ReplicatedStorage

local BuyToolFunction = Remotes:FindFirstChild("BuyTool") or Instance.new("RemoteFunction")
BuyToolFunction.Name = "BuyTool"
BuyToolFunction.Parent = Remotes

-- Tool Definitions (or load from config)
local TOOLS = {
	Pickaxe = { Price = 0, AssetId = 0 }, -- Placeholder ID or create locally
	Axe = { Price = 0, AssetId = 0 },
	Hoe = { Price = 0, AssetId = 0 },
	Shovel = { Price = 0, AssetId = 0 },
}

local function giveTool(player, toolName)
    if not TOOLS[toolName] then return false, "Tool not found" end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false, "No Backpack" end
    
    -- Check if already has?
    if backpack:FindFirstChild(toolName) then
        return false, "You already have this!"
    end
    
    -- Create Tool
    local tool = Instance.new("Tool")
    tool.Name = toolName
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 4, 1)
    handle.Color = Color3.fromRGB(150, 75, 0) -- Wood handle generic
    handle.Parent = tool
    
    -- Specialized Appearance (Simple)
    if toolName == "Pickaxe" then
        local head = Instance.new("Part")
        head.Size = Vector3.new(3, 1, 1)
        head.Color = Color3.fromRGB(100, 100, 100)
        head.CFrame = handle.CFrame * CFrame.new(0, 1.5, 0)
        head.Parent = tool
        local w = Instance.new("WeldConstraint")
        w.Part0 = handle
        w.Part1 = head
        w.Parent = handle
    elseif toolName == "Axe" then
         local head = Instance.new("Part")
        head.Size = Vector3.new(1.5, 2, 0.5)
        head.Color = Color3.fromRGB(150, 150, 150)
        head.CFrame = handle.CFrame * CFrame.new(0.5, 1.5, 0)
        head.Parent = tool
        local w = Instance.new("WeldConstraint")
        w.Part0 = handle
        w.Part1 = head
        w.Parent = handle
    end
    
    tool.Parent = backpack
    return true, "Bought " .. toolName
end

BuyToolFunction.OnServerInvoke = function(player, toolName)
    print(player.Name, "buying", toolName)
    return giveTool(player, toolName)
end
