local React = require(game.ReplicatedStorage.Packages.React)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TerrainHelper = require(game.ReplicatedStorage.Shared.TerrainHelper)
local Panel = require(script.Parent.components.Panel)
local MapState = require(script.Parent.MapState) -- Assuming sibling

local SIZE = 240
local RANGE_STUDS = 480 -- Total width covered
local PIXEL_SIZE = 4 -- Smaller pixels for sharper look (Retina-ish)
local GRID_RES = 120 -- 120x120 grid = 480 pixels width coverage
local VISITED_CHUNK_SIZE = 64

function Minimap()
	print("Minimap: Rendering...")
	-- We need a ref to the Grid Container to rotate it
	local containerRef = React.useRef(nil)
	
	React.useEffect(function()
		print("Minimap: Mounted / Effect Running")
        -- Init Grid Frames (One time)
        local container = containerRef.current
        local frames = {}
        
        -- Increase Grid Resolution to cover rotation gaps
        -- If visible area is 240px, diagonal is ~340px. 
        -- If pixel size is 8, we need at least 43x43 grid. 
        -- Current GRID_RES is 60 -> 60*8 = 480px. This should be enough.
        -- BUT, we anchor the grid at center.
        -- Let's change Background to black to hide gaps.
        
        if container then
             for x = 0, GRID_RES - 1 do
                frames[x] = {}
                for y = 0, GRID_RES - 1 do
                    local f = Instance.new("Frame")
                    f.Size = UDim2.fromOffset(PIXEL_SIZE + 1, PIXEL_SIZE + 1)
                    f.BorderSizePixel = 0
                    f.Parent = container

                    -- Center the grid in the container
                    -- Grid Size = GRID_RES * PIXEL_SIZE
                    -- We want the center of the grid (GRID_RES/2, GRID_RES/2) to be at 0,0 if container is anchored 0.5,0.5
                    -- or just do simple offset:
                    local xOffset = (x * PIXEL_SIZE) - (GRID_RES * PIXEL_SIZE * 0.5)
                    local yOffset = (y * PIXEL_SIZE) - (GRID_RES * PIXEL_SIZE * 0.5)
                    
                    f.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(xOffset, yOffset) 
                    
                    frames[x][y] = f
                end
            end
        end
        
		local connection = RunService.Heartbeat:Connect(function()
			local player = Players.LocalPlayer
			local char = player.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then return end
			
			local root = char.HumanoidRootPart
			local pos = root.Position
            local look = root.CFrame.LookVector
            
            -- ROTATION LOGIC (Track Up)
            -- We rotate the Grid Container OPPOSITE to the player's rotation.
            local angle = math.atan2(look.X, look.Z) -- Radians
            local angleDeg = math.deg(angle)
            
            if container then
                container.Rotation = angleDeg -- Rotate the world around the center
            end
            
            -- UPDATE VISITED STATE
            local cx = math.floor(pos.X / VISITED_CHUNK_SIZE)
            local cz = math.floor(pos.Z / VISITED_CHUNK_SIZE)
            -- Mark immediate area
            for i = -3, 3 do
                for j = -3, 3 do
                    MapState.addVisited(cx+i, cz+j)
                end
            end
            
			-- GRID UPDATE
            -- The grid centers on the player.
            -- Start World Coord:
            local startX = pos.X - (RANGE_STUDS/2)
            local startZ = pos.Z - (RANGE_STUDS/2)
            
            -- Snap to grid to reduce jitter
            startX = math.floor(startX / PIXEL_SIZE) * PIXEL_SIZE
            startZ = math.floor(startZ / PIXEL_SIZE) * PIXEL_SIZE
            
            if container then
                for x = 0, GRID_RES - 1 do
                    for y = 0, GRID_RES - 1 do
                        local wx = startX + (x * PIXEL_SIZE)
                        local wz = startZ + (y * PIXEL_SIZE)
                        
						-- Color logic
                        local _, biome = TerrainHelper.GetTerrainData(wx, wz)
                        local color = TerrainHelper.BiomeColors[biome] or Color3.new(0,0,0)
                        
                        -- Minimap usually shows "what's around you" regardless of memory?
                        -- Actually, let's show everything on Minimap (LIDAR style) but World Map has fog.
                        -- Or adhere to Fog.
                        -- Let's stick to Fog for consistency.
                        local chX = math.floor(wx / VISITED_CHUNK_SIZE)
                        local chZ = math.floor(wz / VISITED_CHUNK_SIZE)
                        
						if MapState.isVisited(chX, chZ) then
							frames[x][y].BackgroundColor3 = color
                            frames[x][y].BackgroundTransparency = 0
						else
                            -- Unvisited: Show Darkened Terrain (Ghost)
                            local r, g, b = color.R, color.G, color.B
                            frames[x][y].BackgroundColor3 = Color3.new(r*0.2, g*0.2, b*0.2)
                            frames[x][y].BackgroundTransparency = 0
						end
					end
				end
			else
				print("Minimap: Container is nil!")
			end
		end)
		
		return function() 
            connection:Disconnect() 
            if container then container:ClearAllChildren() end
        end
	end, {})

	return React.createElement("CanvasGroup", {
		Size = UDim2.fromOffset(SIZE, SIZE),
		Position = UDim2.new(1, -SIZE - 20, 0, 20),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
        GroupTransparency = 0,
        ClipsDescendants = true,
        ZIndex = 10,
	}, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Stroke = React.createElement("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 3,
        }),
        
		-- Map Container that rotates
		MapContainer = React.createElement("Frame", {
            ref = containerRef,
			Size = UDim2.fromOffset(SIZE * 1.5, SIZE * 1.5), -- Larger to cover corners when rotating
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}),
        
        -- Player Arrow (Fixed Up)
        PlayerIcon = React.createElement("ImageLabel", {
            -- Arrow Icon
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031243319", -- Generic arrow or triangle
            Rotation = 0, -- Always points UP if map rotates
            ZIndex = 20,
        })
	})
end

return Minimap
