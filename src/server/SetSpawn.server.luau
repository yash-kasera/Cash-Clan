local Workspace = game:GetService("Workspace")

local spawnLoc = Workspace:FindFirstChild("SpawnLocation") or Instance.new("SpawnLocation")
spawnLoc.Name = "SpawnLocation"
spawnLoc.Position = Vector3.new(0, 50, 0) -- High up, fall down
spawnLoc.Anchored = true
spawnLoc.CanCollide = false
spawnLoc.Transparency = 1
spawnLoc.Parent = Workspace
