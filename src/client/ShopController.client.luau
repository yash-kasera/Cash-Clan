local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local ShopApp = require(script.Parent.ui.ShopApp)

print("ShopController: Started")

local player = Players.LocalPlayer
local root = nil -- Cache root part

local INTERACTION_DIST = 7 -- User requested 7 studs
local LOOK_AT_DIST = 15

local rootInstance = nil
local nearbyNPC = nil
local shopOpen = false

-- Create React Root using Handle
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopSystem"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
rootInstance = ReactRoblox.createRoot(screenGui)

local function updateUI()
    if nearbyNPC then print("ShopController: Showing Prompt for", nearbyNPC) end
    rootInstance:render(React.createElement(ShopApp, {
        shopOpen = shopOpen,
        nearbyNPC = nearbyNPC,
        closeShop = function()
            shopOpen = false
            updateUI()
        end
    }))
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.E then
        if nearbyNPC then 
            shopOpen = not shopOpen
            print("ShopController: E Pressed. ShopOpen:", shopOpen)
            updateUI()
        end
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    local oldNearby = nearbyNPC
    nearbyNPC = nil
    
    if not player.Character then return end
    local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local myPos = myRoot.Position
    local npcs = CollectionService:GetTagged("Shopkeeper")
    -- print("ShopController: Tagged NPCs:", #npcs) -- Comment out to avoid spam if working, but useful for now
    
    local closestDist = math.huge
    local closestNPC = nil
    
    for _, npc in ipairs(npcs) do
        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        local head = npc:FindFirstChild("Head")
        local waist = npc:FindFirstChild("UpperTorso") and npc.UpperTorso:FindFirstChild("Waist") -- R15
        
        if npcRoot and head then
            local dist = (npcRoot.Position - myPos).Magnitude
            -- print("Dist to", npc, ":", dist)
            
            -- Look At Logic
            if dist < LOOK_AT_DIST then
                -- Whole Body Rotation (User Request)
                -- We update CFrame locally. Since it's anchored on server, this works fine on client.
                local lookPos = Vector3.new(myPos.X, npcRoot.Position.Y, myPos.Z) -- Flatten look
                local targetCF = CFrame.lookAt(npcRoot.Position, lookPos)
                
                -- Intepolate for smoothness
                npcRoot.CFrame = npcRoot.CFrame:Lerp(targetCF, 0.1)
            else
                -- Optional: Reset to default direction?
                -- Since we don't know the original seat direction easily here without storing it,
                -- we might just leave them looking at the last spot or snap back if we stored text.
                -- For now, let's leave them.
            end
            
            -- Interaction Logic
            if dist < INTERACTION_DIST then
                if dist < closestDist then
                    closestDist = dist
                    closestNPC = npcRoot -- Adornee on Root (Part is safer for BillboardGui)
                end
            end
        else
            -- print("ShopController: Invalid NPC (No Root/Head)", npc)
        end
    end
    
    nearbyNPC = closestNPC
    
    -- Update UI Only if Changed
    if nearbyNPC ~= oldNearby then
        updateUI()
    end
end)

-- Initial Render
updateUI()
