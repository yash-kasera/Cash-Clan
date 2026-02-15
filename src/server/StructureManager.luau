local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StructureManager = {}
local Assets = ReplicatedStorage:FindFirstChild("Assets")

-- Asset Mapping: Internal Name -> List of possible Asset Names
local AssetMap = {
	-- Nature
	Bush = {
		"Bush_01",
		"Bush_02",
		"Bush_03", -- Models_Bushes/Models
		"Bush1_01",
		"Bush1_02",
		"Bush2_01",
		"Bush2_02", -- Foliage folder
	},
	Flower = { "Blue_Flowers", "Pink_Flowers", "White_Flowers", "Yellow_Flowers" },
	Clover = { "Clover_01", "Clover_02", "Clover_03" },
	Mushroom = { "Mushroom_01", "Mushroom_02", "Mushroom_03" },
	tLog = { "Log_01", "Log_02", "Log_03" }, -- "Log" might be reserved key or part name, using tLog/LogAsset
	Lilypad = { "Lilypad_01", "Lilypad_02", "Lilypad_03", "Lilypad_04", "Lilypad_05", "Lilypad_06" },

	-- Trees
	OakTree = {
		"Tree_01",
		"Tree_02",
		"Tree_03",
		"Tree_04",
		"Tree_05",
		"Tree_06",
		"Tree_07",
		"Tree_08",
		"Tree_09",
		"Tree_10",
	},
	PineTree = {
		"Pine_01.1",
		"Pine_01.2",
		"Pine_01.3",
		"Pine_01.4",
		"Pine_02.1",
		"Pine_02.2",
		"Pine_02.3",
		"Pine_02.4",
		"Pine_03.1",
		"Pine_03.2",
		"Pine_03.3",
		"Pine_03.4",
		"Pine_04.1",
		"Pine_04.2",
		"Pine_04.3",
		"Pine_04.4",
		"Pine_05.1",
		"Pine_05.2",
		"Pine_05.3",
		"Pine_05.4",
		"Pine_06.1", -- Add more if needed
	},
	-- PalmTree = { "Palm_01" },
	Rock = {
		"Rock_01",
		"Rock_02",
		"Rock_03",
		"Rocks_04",
		"Rocks_05",
		"Rocks_06",
		"Rocks_07",
		"Rock_Preset_01",
		"Rock_Preset_02",
		"Rock_Preset_03",
		"Rock_Preset_04",
		"Rock_Preset_05",
		"Rock_Preset_06",
	},
}

-- Recursive search to find an asset by name inside any subfolder
local function findAssetRecursively(root, name)
	local found = root:FindFirstChild(name)
	if found then
		return found
	end

	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("Folder") then
			found = findAssetRecursively(child, name)
			if found then
				return found
			end
		end
	end
	return nil
end

-- Helper to try placing an asset (supports random variants)
local function tryPlaceAsset(internalName, cframe, parent)
	if not Assets then
		return false
	end

	-- Determine target asset name(s)
	local targets = AssetMap[internalName] or { internalName }

	-- Pick one randomly if it's a list
	local targetName = targets[math.random(1, #targets)]

	-- Search
	local model = findAssetRecursively(Assets, targetName)

	if model then
		local clone = model:Clone()
		clone:PivotTo(cframe)
		clone.Parent = parent
		return true
	end

	return false
end

-- Utility to create parts
local function makePart(size, color, material, cframe, parent, shape)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.CFrame = cframe
	p.Anchored = true
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- --- TREES ---

function StructureManager.PlaceOakTree(cframe, parent)
	if tryPlaceAsset("OakTree", cframe, parent) then
		return
	end
end

function StructureManager.PlacePineTree(cframe, parent)
	if tryPlaceAsset("PineTree", cframe, parent) then
		return
	end
end

function StructureManager.PlacePalmTree(cframe, parent)
	if tryPlaceAsset("PalmTree", cframe, parent) then
		return
	end
end

-- --- PROPS ---

function StructureManager.PlaceRock(cframe, parent)
	if tryPlaceAsset("Rock", cframe, parent) then
		return
	end

	local sz = math.random(2, 5)
	local p = makePart(
		Vector3.new(sz, sz * 0.8, sz),
		Color3.fromRGB(100, 100, 100),
		Enum.Material.Slate,
		cframe * CFrame.Angles(math.random(), math.random(), math.random()),
		parent
	)
	p.Name = "Rock"
end

function StructureManager.PlaceBush(cframe, parent)
	if tryPlaceAsset("Bush", cframe, parent) then
		return
	end

	local sz = math.random(3, 5)
	local p = makePart(
		Vector3.new(sz, sz, sz),
		Color3.fromRGB(50, 120, 50),
		Enum.Material.Grass,
		cframe,
		parent,
		Enum.PartType.Ball
	)
	p.Name = "Bush"
end

function StructureManager.PlaceClover(cframe, parent)
	-- Rotate 90 degrees on X to lie flat, and random Y rotation
	local rotatedCFrame = cframe * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	
	if tryPlaceAsset("Clover", rotatedCFrame, parent) then
		return
	end
	-- No procedural fallback for detailing, just skip
end

function StructureManager.PlaceMushroom(cframe, parent)
	if tryPlaceAsset("Mushroom", cframe, parent) then
		return
	end
end

function StructureManager.PlaceFlower(cframe, parent)
	if tryPlaceAsset("Flower", cframe, parent) then
		return
	end
end

function StructureManager.PlaceLog(cframe, parent)
	if tryPlaceAsset("tLog", cframe, parent) then
		return
	end
	-- Procedural Log Fallback
	local sz = math.random(6, 10)
	local p = makePart(
		Vector3.new(2, 2, sz),
		Color3.fromRGB(90, 60, 30),
		Enum.Material.Wood,
		cframe * CFrame.Angles(0, math.random() * math.pi, 0),
		parent,
		Enum.PartType.Cylinder
	)
	p.Name = "Log"
	p.CFrame = p.CFrame * CFrame.Angles(0, 0, math.pi / 2) -- Rotate cylinder
end

function StructureManager.PlaceLilypad(cframe, parent)
	-- Rotate 90 degrees on X to lie flat, and random Y rotation
	local rotatedCFrame = cframe * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	
	if tryPlaceAsset("Lilypad", rotatedCFrame, parent) then
		return
	end
end

-- --- BUILDINGS ---

function StructureManager.PlaceBank(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "Bank"
	-- Stone Pillar Bank
	local w, h, d = 24, 18, 28

	-- Foundation
	makePart(
		Vector3.new(w, 1, d),
		Color3.fromRGB(50, 50, 50),
		Enum.Material.Concrete,
		cframe * CFrame.new(0, 0.5, 0),
		model
	)
	-- Walls
	makePart(
		Vector3.new(w - 4, h, d - 4),
		Color3.fromRGB(220, 220, 220),
		Enum.Material.SmoothPlastic,
		cframe * CFrame.new(0, h / 2, 0),
		model
	)
	-- Pillars Front
	makePart(
		Vector3.new(2, h, 2),
		Color3.fromRGB(240, 240, 240),
		Enum.Material.Concrete,
		cframe * CFrame.new(w / 2 - 2, h / 2, d / 2 - 2),
		model
	)
	makePart(
		Vector3.new(2, h, 2),
		Color3.fromRGB(240, 240, 240),
		Enum.Material.Concrete,
		cframe * CFrame.new(-w / 2 + 2, h / 2, d / 2 - 2),
		model
	)
	-- Roof
	makePart(
		Vector3.new(w + 2, 2, d + 2),
		Color3.fromRGB(80, 80, 90),
		Enum.Material.Slate,
		cframe * CFrame.new(0, h + 1, 0),
		model
	)

	-- Sign
	makePart(
		Vector3.new(10, 3, 1),
		Color3.fromRGB(50, 255, 50),
		Enum.Material.Neon,
		cframe * CFrame.new(0, h + 3, d / 2),
		model
	)

	model.Parent = parent
end

function StructureManager.PlaceShop(cframe, parent)
	-- Small wooden shop
	local model = Instance.new("Model")
	model.Name = "Shop"

	local w, h, d = 20, 14, 20
	makePart(
		Vector3.new(w, 1, d),
		Color3.fromRGB(139, 69, 19),
		Enum.Material.WoodPlanks,
		cframe * CFrame.new(0, 0.5, 0),
		model
	)
	-- Box
	makePart(
		Vector3.new(w, h, d),
		Color3.fromRGB(200, 150, 100),
		Enum.Material.Wood,
		cframe * CFrame.new(0, h / 2, 0),
		model
	)
	-- Glazed Front
	makePart(
		Vector3.new(w - 2, h - 2, 1),
		Color3.fromRGB(200, 240, 255),
		Enum.Material.Glass,
		cframe * CFrame.new(0, h / 2, d / 2 + 0.1),
		model
	)

	model.Parent = parent
end

function StructureManager.PlaceRoad(cframe, parent)
	local p = makePart(
		Vector3.new(16, 1, 16),
		Color3.fromRGB(60, 60, 60),
		Enum.Material.Concrete,
		cframe * CFrame.new(0, 0.4, 0),
		parent
	)
	p.Name = "Road"
end

return StructureManager
