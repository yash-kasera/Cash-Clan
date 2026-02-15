local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Players = game:GetService("Players")

-- Wait for the module to be available (sometimes require fails if script runs too early?)
local MapApp = require(script.Parent.ui.MapApp)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MapGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.DisplayOrder = 10 -- Ensure it's on top

print("MapController: Mounting MapApp...")

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(MapApp))
