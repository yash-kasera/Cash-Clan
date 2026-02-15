local React = require(game.ReplicatedStorage.Packages.React)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SIZE = 240
local VIEW_RANGE = 400 -- Diameter of view in studs
local CAMERA_HEIGHT = 400

function RealtimeMinimap()
	local containerRef = React.useRef(nil)
	local viewportRef = React.useRef(nil)
	local worldModelRef = React.useRef(nil)
	local cameraRef = React.useRef(nil)
	
	-- Keep track of cloned objects to clean up
	local clonedObjects = React.useRef({}) 
	
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then return end
		
		-- Create WorldModel for physics/rendering context
		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = viewport
		worldModelRef.current = worldModel
		
		-- Create Camera
		local cam = Instance.new("Camera")
		cam.FieldOfView = 1 -- Orthographic-ish trick: Low FOV, High Distance
		cam.Parent = viewport
		viewport.CurrentCamera = cam
		cameraRef.current = cam
		
		-- Create Ground Plane (Green)
		local ground = Instance.new("Part")
		ground.Size = Vector3.new(2048, 1, 2048)
		ground.Position = Vector3.new(0, -2, 0) -- Slightly below 0
		ground.Anchored = true
		ground.CanCollide = false
		ground.Color = Color3.fromRGB(90, 160, 90) -- Map Green
		ground.Material = Enum.Material.Plastic
		ground.Parent = worldModel
		
		-- Create Water Plane (Blue)
		local water = Instance.new("Part")
		water.Size = Vector3.new(2048, 1, 2048)
		water.Position = Vector3.new(0, -6, 0) -- Below ground
		water.Anchored = true
		water.CanCollide = false
		water.Color = Color3.fromRGB(60, 120, 200) -- Map Blue
		water.Material = Enum.Material.Plastic
		water.Transparency = 0.5
		water.Parent = worldModel

		-- Helper to clone objects
		local function cloneObject(obj)
			if not obj:IsA("Model") and not obj:IsA("BasePart") then return end
			if obj.Name == "Terrain" then return end -- Don't clone Terrain
			
			-- Clone only if likely visible structure
			-- Filter small debris if needed
			
			local clone = obj:Clone()
			
			-- Strip scripts/physics to save perf
			for _, child in ipairs(clone:GetDescendants()) do
				if child:IsA("Script") or child:IsA("LocalScript") then
					child:Destroy()
				elseif child:IsA("BasePart") then
					child.Anchored = true
					child.CanCollide = false
					child.CastShadow = false -- Expensive shadow map in Viewport?
				end
			end
			
			clone.Parent = worldModel
			clonedObjects.current[obj] = clone
			
			-- Cleanup on source removal
			obj.AncestryChanged:Connect(function(_, parent)
				if not parent then
					if clonedObjects.current[obj] then
						clonedObjects.current[obj]:Destroy()
						clonedObjects.current[obj] = nil
					end
				end
			end)
		end
		
		-- Initial Clone of Structures
		local structuresFolder = workspace:FindFirstChild("Structures")
		if structuresFolder then
			for _, child in ipairs(structuresFolder:GetChildren()) do
				task.spawn(function() cloneObject(child) end)
			end
			
			-- Listen for new structures
			structuresFolder.ChildAdded:Connect(cloneObject)
		end
		
		-- Render Loop
		local connection = RunService.RenderStepped:Connect(function()
			local player = Players.LocalPlayer
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			if root and cam then
				local pos = root.Position
				
				-- Position Camera above player
				-- Use strict Top-Down
				local camPos = Vector3.new(pos.X, CAMERA_HEIGHT, pos.Z)
				cam.CFrame = CFrame.new(camPos, pos)
				
				-- Adjust FOV for "Zoom"? Or Altitude?
				-- Since we use FOV 1 trick, distance needs to be huge
				-- Tan(0.5 deg) * Dist = Visible Radius
				-- 0.0087 * Dist = 200 (Radius 400/2)
				-- Dist = 200 / 0.0087 = ~22,900 studs
				-- Let's just use normal perspective for now: FOV 30, Dist 500
				
				cam.FieldOfView = 50 -- Standard perspective but high up
				cam.CFrame = CFrame.new(Vector3.new(pos.X, 400, pos.Z), pos)
				
				-- Rotate Container? No, ViewportFrame inside container rotates?
				-- User wants "Camera always moves with player". Rotation? 
				-- Usually minimaps rotate so "Up" is "Forward".
				-- If so, we rotate the CAMERA CFrame to match Player Heading.
				
				local look = root.CFrame.LookVector
				local heading = math.atan2(look.X, look.Z)
				
				-- To rotate map: We rotate the Camera AROUND the Z axis? No.
				-- We rotate the Camera so its "Up" vector matches player forward?
				-- Actually, if we want the map to rotate, we rotate the CAMERA CFrame.
				
				-- Standard Top Down with Rotation:
				-- Position: Above player.
				-- LookAt: Player.
				-- UpVector: Player's LookVector. (So "Up" on screen is "Forward" in world)
				
				local upVec = Vector3.new(look.X, 0, look.Z).Unit
				-- But LookAt is (0, -1, 0). Up cannot be (0, -1, 0).
				-- CFrame.lookAt(pos, lookAt, up)
				
				cam.CFrame = CFrame.lookAt(
					Vector3.new(pos.X, 400, pos.Z), -- Eye
					pos, -- Target
					-root.CFrame.LookVector -- Up vector for camera? Testing needed.
				)
				
				-- Adjust Ground Plane to follow player (infinite ground illusion)
				if ground then
					ground.Position = Vector3.new(pos.X, -2, pos.Z)
				end
				if water then
					water.Position = Vector3.new(pos.X, -6, pos.Z)
				end
			end
		end)
		
		return function()
			connection:Disconnect()
			if worldModel then worldModel:Destroy() end
			clonedObjects.current = {}
		end
	end, {})

	return React.createElement("CanvasGroup", {
		Size = UDim2.fromOffset(SIZE, SIZE),
		Position = UDim2.new(1, -SIZE - 20, 0, 20),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5, -- Semi-transparent per user request
		BorderSizePixel = 0,
		GroupTransparency = 0,
        ClipsDescendants = true,
		ZIndex = 10,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }), -- Rounded Square
		
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 3,
			Transparency = 0,
		}),
		
		Viewport = React.createElement("ViewportFrame", {
			ref = viewportRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Ambient = Color3.fromRGB(255, 255, 255), -- Maximum Ambient
			LightColor = Color3.fromRGB(255, 255, 255),
			LightDirection = Vector3.new(0, -1, 0),
		}),
		
		-- Center Icon (Player)
		-- Since map rotates, player is fixed UP?
		-- Or if map is fixed North, player rotates?
		-- Code above rotates Camera to align with Player.
		-- So Map rotates. Player stays "Up".
		-- Wait, CFrame.lookAt up vector controls rotation.
		-- If we align Camera Up with Player Forward, then World Forward is "Up" on screen.
		-- So Player Icon should point UP.
		
		PlayerIcon = React.createElement("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://6031243319", -- Arrow
			Rotation = 0, -- Points Update
			ZIndex = 20,
		})
	})
end

return RealtimeMinimap
