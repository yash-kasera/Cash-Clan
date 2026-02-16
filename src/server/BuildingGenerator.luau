local BuildingGenerator = {}

-- Utility
local function makePart(size, color, material, cframe, parent)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material
	p.CFrame = cframe
	p.Anchored = true
	p.Parent = parent
	return p
end

-- local function makeWall(p1, p2, height, color, material, parent)
-- 	local center = (p1 + p2) / 2
-- 	local dist = (p1 - p2).Magnitude
-- 	local cf = CFrame.lookAt(center, p2)
-- 	makePart(Vector3.new(0.5, height, dist), color, material, cf * CFrame.new(0, height / 2, 0), parent)
-- end

-- Building Definitions
local BuildingConfigs = {
	CarShowroom = {
		Size = Vector3.new(60, 20, 80),
		Rooms = { "ShowroomFloor", "Office", "ServiceBay", "Reception" },
		Color = Color3.fromRGB(255, 255, 255),
		WindowColor = Color3.fromRGB(200, 240, 255),
	},
	BikeShowroom = {
		Size = Vector3.new(40, 15, 50),
		Rooms = { "ShowroomFloor", "ServiceBay", "Counter" },
		Color = Color3.fromRGB(200, 50, 50),
	},
	TruckShowroom = {
		Size = Vector3.new(80, 30, 100),
		Rooms = { "LargeShowroom", "HeavyServiceBay", "Office" },
		Color = Color3.fromRGB(100, 100, 100),
	},
	Nursery = {
		Size = Vector3.new(40, 12, 40),
		Rooms = { "Greenhouse", "ShopFloor", "Storage" },
		Color = Color3.fromRGB(100, 200, 100),
		Material = Enum.Material.Wood,
	},
	ToolsShop = {
		Size = Vector3.new(30, 12, 30),
		Rooms = { "DisplayArea", "Counter" },
		Color = Color3.fromRGB(150, 75, 0),
	},
	Restaurant = {
		Size = Vector3.new(50, 15, 50),
		Rooms = { "DiningArea", "Kitchen", "Restroom", "Storage" },
		Color = Color3.fromRGB(255, 200, 150),
	},
	Cafe = {
		Size = Vector3.new(30, 12, 30),
		Rooms = { "Seating", "Counter", "Kitchenette" },
		Color = Color3.fromRGB(200, 180, 160),
	},
	Hotel = {
		Size = Vector3.new(60, 50, 60), -- Tall
		Rooms = { "Lobby", "Rooms_L1", "Rooms_L2", "Rooms_L3" },
		Color = Color3.fromRGB(220, 220, 240),
	},
	Apartment = {
		Size = Vector3.new(50, 40, 50),
		Rooms = { "Lobby", "Flats" },
		Color = Color3.fromRGB(200, 200, 200),
	},
	Factory = {
		Size = Vector3.new(80, 25, 100),
		Rooms = { "AssemblyLine", "Warehouse", "Office" },
		Color = Color3.fromRGB(80, 80, 80),
		Material = Enum.Material.Metal,
	},
	BuilderCompany = {
		Size = Vector3.new(40, 20, 40),
		Rooms = { "Office", "MeetingRoom", "Reception" },
		Color = Color3.fromRGB(255, 150, 50),
	},
	Bank = {
		Size = Vector3.new(50, 25, 60),
		Rooms = { "Lobby", "Tellers", "Vault", "ManagerOffice" },
		Color = Color3.fromRGB(230, 230, 230),
		Material = Enum.Material.Concrete,
	},
	Hospital = {
		Size = Vector3.new(70, 40, 70),
		Rooms = { "ER", "Wards", "Reception", "Pharmacy" },
		Color = Color3.fromRGB(250, 250, 255),
	},
	School = {
		Size = Vector3.new(80, 20, 60),
		Rooms = { "Classrooms", "Office", "Playground", "Restrooms" },
		Color = Color3.fromRGB(255, 255, 220),
	},
	Mall = {
		Size = Vector3.new(100, 30, 100),
		Rooms = { "Atrium", "Shops", "FoodCourt" },
		Color = Color3.fromRGB(240, 200, 240),
	},
	PoliceStation = {
		Size = Vector3.new(50, 20, 50),
		Rooms = { "Reception", "Cells", "Office", "Armory" },
		Color = Color3.fromRGB(50, 50, 150),
	},
}

-- Simple Room Layout Generator (Recursive Split)
-- Splits a rect (x, z, w, d) into sub-rects
local function generateLayout(x, z, w, d, depth)
	if depth <= 0 or (w < 15 and d < 15) then
		return { { X = x, Z = z, W = w, D = d } }
	end

	local rooms = {}
	-- Split horizontally or vertically
	local splitHorz = w > d

	if splitHorz then
		local splitRatio = 0.4 + math.random() * 0.2 -- 0.4 to 0.6
		local w1 = math.floor(w * splitRatio)
		local w2 = w - w1
		for _, r in ipairs(generateLayout(x, z, w1, d, depth - 1)) do
			table.insert(rooms, r)
		end
		for _, r in ipairs(generateLayout(x + w1, z, w2, d, depth - 1)) do
			table.insert(rooms, r)
		end
	else
		local splitRatio = 0.4 + math.random() * 0.2
		local d1 = math.floor(d * splitRatio)
		local d2 = d - d1
		for _, r in ipairs(generateLayout(x, z, w, d1, depth - 1)) do
			table.insert(rooms, r)
		end
		for _, r in ipairs(generateLayout(x, z + d1, w, d2, depth - 1)) do
			table.insert(rooms, r)
		end
	end
	return rooms
end

function BuildingGenerator.Generate(buildingType: string, cframe: CFrame, parent: Instance)
	local config = BuildingConfigs[buildingType]
	if not config then
		-- Fallback to generic shop if not found
		config = BuildingConfigs.ToolsShop
	end

    -- Check for Custom Asset (User Request: ToolShop)
    local assets = game.ReplicatedStorage:FindFirstChild("Assets")
    local townAssets = assets and assets:FindFirstChild("Town")
    
    -- Map Internal Name -> Asset Name
    local assetName = buildingType
    if buildingType == "ToolsShop" then assetName = "ToolShop" end
    
    local template = townAssets and townAssets:FindFirstChild(assetName)
    
    if template then
        local model = template:Clone()
        model.Name = buildingType
        model.Parent = parent
        
        -- Position Model: Adjust for Bounding Box
        local cf, size = model:GetBoundingBox()
        -- Move up by half height so bottom sits on terrain
        local targetCF = cframe * CFrame.new(0, size.Y / 2, 0)
        
        if model.PrimaryPart then
            model:SetPrimaryPartCFrame(targetCF)
        else
            model:PivotTo(targetCF)
        end
        
        -- Spawn Shopkeeper if ToolShop
        if buildingType == "ToolsShop" then
            task.spawn(function()
                -- Find Chair -> Seat
                -- User: "model named Chair which has a part named Seat"
                local chair = model:FindFirstChild("Chair", true) -- Recursive search for model named Chair?
                -- Or just search descendants
                local seat
                if chair then
                    seat = chair:FindFirstChild("Seat")
                else
                    -- Fallback: Search any Seat
                     for _, d in ipairs(model:GetDescendants()) do
                        if d.Name == "Seat" and d:IsA("Seat") then
                            seat = d
                            break
                        end
                    end
                end
                
                if seat then
                    -- Create Dummy NPC
                    pcall(function() 
                        local npc = game.Players:CreateHumanoidModelFromUserId(1) -- Roblox Default
                        npc.Name = "Shopkeeper"
                        npc.Parent = model
                        
                        -- Tag for Client Interaction
                        game:GetService("CollectionService"):AddTag(npc, "Shopkeeper")
                        print("BuildingGenerator: Tagged Shopkeeper", npc)
                        
                        -- Ensure NPC components exist
                        local hum = npc:FindFirstChild("Humanoid")
                        local root = npc:FindFirstChild("HumanoidRootPart")
                        if hum and root then
                             -- Anchor Root to prevent physics issues
                             root.Anchored = true
                             root.CFrame = seat.CFrame * CFrame.new(0, 1.3, 0) -- Adjust height for sit
                             
                             -- Play Sit Animation (Visual only)
                             local anim = Instance.new("Animation")
                             anim.AnimationId = "rbxassetid://2506281703" -- R15 Sit
                             local track = hum:LoadAnimation(anim)
                             track.Looped = true
                             track:Play()
                        end
                    end)
                else
                    print("Warning: Seat not found in ToolShop model")
                end
            end)
        end
        
        return -- Skip procedural gen
    end

	local model = Instance.new("Model")
	model.Name = buildingType
	model.Parent = parent

	local w, h, d = config.Size.X, config.Size.Y, config.Size.Z

	-- Foundation
	makePart(
		Vector3.new(w + 2, 1, d + 2),
		Color3.fromRGB(50, 50, 50),
		Enum.Material.Concrete,
		cframe * CFrame.new(0, 0.5, 0),
		model
	)

	-- Exterior Walls
	-- Front (Glass?)
	local isShowroom = string.find(buildingType, "Showroom") or buildingType == "Mall" or buildingType == "Cafe"

	if isShowroom then
		-- Glass Front
		makePart(
			Vector3.new(w, h, 0.5),
			config.WindowColor or Color3.fromRGB(200, 240, 255),
			Enum.Material.Glass,
			cframe * CFrame.new(0, h / 2 + 1, d / 2),
			model
		)
	else
		makePart(
			Vector3.new(w, h, 1),
			config.Color,
			config.Material or Enum.Material.Concrete,
			cframe * CFrame.new(0, h / 2 + 1, d / 2),
			model
		)
	end

	-- Back
	makePart(
		Vector3.new(w, h, 1),
		config.Color,
		config.Material or Enum.Material.Concrete,
		cframe * CFrame.new(0, h / 2 + 1, -d / 2),
		model
	)
	-- Left
	makePart(
		Vector3.new(1, h, d),
		config.Color,
		config.Material or Enum.Material.Concrete,
		cframe * CFrame.new(-w / 2, h / 2 + 1, 0),
		model
	)
	-- Right
	makePart(
		Vector3.new(1, h, d),
		config.Color,
		config.Material or Enum.Material.Concrete,
		cframe * CFrame.new(w / 2, h / 2 + 1, 0),
		model
	)

	-- Roof
	makePart(
		Vector3.new(w + 2, 1, d + 2),
		Color3.fromRGB(80, 80, 80),
		Enum.Material.Slate,
		cframe * CFrame.new(0, h + 1, 0),
		model
	)

	-- Floors (for Shells with multiple floors e.g. Hotel)
	if buildingType == "Hotel" or buildingType == "Apartment" then
		for i = 1, 3 do
			local y = (h / 4) * i
			makePart(
				Vector3.new(w, 1, d),
				Color3.fromRGB(150, 150, 150),
				Enum.Material.WoodPlanks,
				cframe * CFrame.new(0, y + 1, 0),
				model
			)
		end
	end

	-- Interior Layout
	-- Generate rooms
	local rooms = generateLayout(-w / 2 + 1, -d / 2 + 1, w - 2, d - 2, 2)

	-- Assign room types from config (roughly)
	for i, r in ipairs(rooms) do
		local roomName = config.Rooms[(i - 1) % #config.Rooms + 1] or "Room"

		-- Place Label?
		-- For now, just create walls around the room
		-- Walls need to be inside the building

		-- Center of room
		local cx = r.X + r.W / 2
		local cz = r.Z + r.D / 2
		-- local cy = 1 + 2 -- Floor level

		-- Internal walls (low height 10 studs)
		-- We only draw walls if they aren't on the border?
		-- The `generateLayout` returns non-overlapping rects covering the space.
		-- So adjacent rooms share a boundary.
		-- We can just draw the -X and -Z walls of each room (unless it's the building border)

		local wallH = 10
		if h < 12 then
			wallH = h - 2
		end

		-- Wall -X side
		-- if r.X > (-w / 2 + 2) then
		-- 	makePart(Vector3.new(0.5, wallH, r.D), Color3.new(0.9,0.9,0.9), Enum.Material.SmoothPlastic, cframe * CFrame.new(r.X, wallH/2 + 1, cz), model)
		-- end

		-- Instead of complex wall logic which might Z-fight, let's just place a "Prop" in the center to signify usage
		if roomName == "ShowroomFloor" then
			-- Place a Podium
			makePart(
				Vector3.new(8, 1, 8),
				Color3.new(0.2, 0.2, 0.2),
				Enum.Material.Metal,
				cframe * CFrame.new(cx, 1.5, cz),
				model
			)
		elseif roomName == "Office" then
			-- Desk
			makePart(
				Vector3.new(4, 3, 2),
				Color3.fromRGB(139, 69, 19),
				Enum.Material.Wood,
				cframe * CFrame.new(cx, 1.5, cz),
				model
			)
		elseif roomName == "Restroom" then
			-- Small box
			makePart(
				Vector3.new(3, 3, 3),
				Color3.fromRGB(255, 255, 255),
				Enum.Material.SmoothPlastic,
				cframe * CFrame.new(cx, 1.5, cz),
				model
			)
		end

		-- Actually draw internal walls for "Realism"
		-- Check X boundary
		if math.abs(r.X - (-w / 2 + 1)) > 1 then -- Not left border
			makePart(
				Vector3.new(1, wallH, r.D),
				Color3.new(0.9, 0.9, 0.9),
				Enum.Material.SmoothPlastic,
				cframe * CFrame.new(r.X, wallH / 2 + 1, cz),
				model
			)
		end
		-- Check Z boundary
		if math.abs(r.Z - (-d / 2 + 1)) > 1 then -- Not back border
			makePart(
				Vector3.new(r.W, wallH, 1),
				Color3.new(0.9, 0.9, 0.9),
				Enum.Material.SmoothPlastic,
				cframe * CFrame.new(cx, wallH / 2 + 1, r.Z),
				model
			)
		end
	end

	-- Signage
	makePart(
		Vector3.new(w * 0.6, 4, 1),
		Color3.new(1, 1, 1),
		Enum.Material.Neon,
		cframe * CFrame.new(0, h + 4, d / 2),
		model
	)
	-- Text generation is tricky without TextGui, but Neon block works for "Sign"
end

return BuildingGenerator
