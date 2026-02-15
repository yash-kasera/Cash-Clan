local RunService = game:GetService("RunService")
local BuildService = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local TerrainHelper = require(game.ReplicatedStorage.Shared.TerrainHelper)

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local BiomeType = TerrainHelper.BiomeType
local currentBiome = BiomeType.Plains -- Default
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)

local function getBiomeAt(x, z)
	local _, biome = TerrainHelper.GetTerrainData(x, z)
	return biome
end

local function applyLighting(biome)
	if biome == BiomeType.Swamp or biome == BiomeType.Spruce then
		-- Gloomy
		local tween = TweenService:Create(Lighting, tweenInfo, {
			img_FogColor = Color3.fromRGB(80, 90, 80), -- Muted green/grey
			FogEnd = 200, -- Closer fog
            FogStart = 0,
            OutdoorAmbient = Color3.fromRGB(70, 70, 80),
			Brightness = 1,
            ClockTime = 18, -- Evening feel (optional, might conflict with day/night cycle if exists)
		})
        -- If Atmosphere exists
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            TweenService:Create(atm, tweenInfo, {
                Density = 0.5,
                Offset = 0,
                Color = Color3.fromRGB(100, 110, 100),
                Decay = Color3.fromRGB(50, 50, 50),
                Glare = 0,
                Haze = 2
            }):Play()
        end
		tween:Play()
	else
		-- Normal / Bright
		local tween = TweenService:Create(Lighting, tweenInfo, {
			img_FogColor = Color3.fromRGB(192, 241, 255), -- Sky blueish
			FogEnd = 10000,
            FogStart = 50,
            OutdoorAmbient = Color3.fromRGB(120, 120, 120),
			Brightness = 2,
            ClockTime = 14, -- Afternoon
		})
         local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
             TweenService:Create(atm, tweenInfo, {
                Density = 0.3,
                Offset = 0.25,
                Color = Color3.fromRGB(199, 199, 199),
                Decay = Color3.fromRGB(106, 112, 125),
                Glare = 0,
                Haze = 0
            }):Play()
        end
		tween:Play()
	end
end

RunService.Heartbeat:Connect(function()
    if not Character or not Character.Parent then
        Character = Player.Character
        return
    end
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local pos = root.Position
    local detected = getBiomeAt(pos.X, pos.Z)
    
    if detected ~= currentBiome then
        currentBiome = detected
        applyLighting(detected)
    end
end)
