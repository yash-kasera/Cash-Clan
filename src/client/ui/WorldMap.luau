local React = require(game.ReplicatedStorage.Packages.React)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TerrainHelper = require(game.ReplicatedStorage.Shared.TerrainHelper)
local Panel = require(script.Parent.components.Panel)
local Button = require(script.Parent.components.Button)
local MapState = require(script.Parent.MapState)

local WORLD_RES = 100 
local BASE_RANGE = 4000
local VISITED_CHUNK_SIZE = 64

function WorldMap(props)
    local containerRef = React.useRef(nil)
    local playerDotRef = React.useRef(nil)
    local state = React.useRef({ zoom = 1, offset = Vector2.new(0,0), dragging = false, dragStart = Vector2.new(0,0) })
    
    local onInputBegan = function(rbx, input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state.current.dragging = true
            state.current.dragStart = input.Position
        end
    end
    
    local onInputChanged = function(rbx, input)
         if input.UserInputType == Enum.UserInputType.MouseWheel then
            state.current.zoom = math.clamp(state.current.zoom + (input.Position.Z * 0.2), 0.5, 5)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and state.current.dragging and state.current.mapCenter then
            local delta = input.Position - state.current.dragStart
            -- Dragging moves the MAP, so Center moves OPPOSITE to Delta?
            -- Actually, if I drag Mouse Left, I expect Map to move Left (revealing Right side).
            -- So `mapCenter` should move LEFT (-Delta).
            -- Scale factor: Screen Pixels -> World Studs.
            -- Width = 800px (approx Canvas size).
            -- Range = BASE_RANGE / zoom. (e.g. 4000 studs).
            -- 1 px = Range / 800 studs.
            local range = BASE_RANGE / state.current.zoom
            -- Assuming Canvas is roughly ~760px wide (800 - 40 padding)
            local scale = range / 760 
            
            local worldDelta = Vector2.new(delta.X, delta.Y) * scale
            state.current.mapCenter = state.current.mapCenter - worldDelta
            
            state.current.dragStart = input.Position
        end
    end
    
    local onInputEnded = function(rbx, input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state.current.dragging = false
        end
    end
    
    React.useEffect(function()
        local container = containerRef.current
        if not container then return end
        
        -- Init Grid
        local frames = {}
        for x = 0, WORLD_RES - 1 do
            frames[x] = {}
            for y = 0, WORLD_RES - 1 do
                local f = Instance.new("Frame")
                f.BorderSizePixel = 0
                f.Parent = container
                frames[x][y] = f
            end
        end
        
        local conn = RunService.RenderStepped:Connect(function()
             local s = state.current
             local range = BASE_RANGE / s.zoom
             
             -- Initialize mapCenter if not set
             if not s.mapCenter then
                 local p = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                 if p then
                     s.mapCenter = Vector2.new(p.Position.X, p.Position.Z)
                 else
                     s.mapCenter = Vector2.new(0, 0)
                 end
             end
             
             local centerPose = s.mapCenter
             -- Dragging updates s.offset, which we should apply to mapCenter?
             -- Actually, let's make Drag update mapCenter DIRECTLY in InputChanged to avoid complex offsets.
             -- But for now, let's just use s.offset as the "delta" from initial center?
             -- Better: Let InputChanged modify s.mapCenter directly.
             -- For this RenderStep, we assume s.mapCenter IS the center.
             
             local startX = centerPose.X - range/2
             local startZ = centerPose.Y - range/2
             local step = range / WORLD_RES
             
             for x = 0, WORLD_RES - 1 do
                for y = 0, WORLD_RES - 1 do
                     local wx = startX + (x * step)
                     local wz = startZ + (y * step)
                     
                     local f = frames[x][y]
                     -- Scale grid cells to fill the view
                     f.Size = UDim2.fromScale(1/WORLD_RES, 1/WORLD_RES)
                     f.Position = UDim2.fromScale(x/WORLD_RES, y/WORLD_RES)
                     
                     local cx = math.floor(wx / VISITED_CHUNK_SIZE)
                     local cz = math.floor(wz / VISITED_CHUNK_SIZE)
                     
                     local cx = math.floor(wx / VISITED_CHUNK_SIZE)
                     local cz = math.floor(wz / VISITED_CHUNK_SIZE)
                     
                     local _, biome = TerrainHelper.GetTerrainData(wx, wz)
                     local color = TerrainHelper.BiomeColors[biome] or Color3.new(0,0,0)

                     if MapState.isVisited(cx, cz) then
                         f.BackgroundColor3 = color
                     else
                         -- Ghost Mode for World Map too
                         local r, g, b = color.R, color.G, color.B
                         f.BackgroundColor3 = Color3.new(r*0.2, g*0.2, b*0.2)
                     end
                end
             end
             
             -- Update Player Dot
             local p = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
             if playerDotRef.current and p then
                 local px = p.Position.X
                 local pz = p.Position.Z
                 
                 local xPct = (px - startX) / range
                 local yPct = (pz - startZ) / range
                 
                 playerDotRef.current.Position = UDim2.fromScale(xPct, yPct)
                 
                 -- Show only if within bounds (optional, but good for UI)
                 if xPct >= 0 and xPct <= 1 and yPct >= 0 and yPct <= 1 then
                     playerDotRef.current.Visible = true
                 else
                     playerDotRef.current.Visible = false
                 end
             elseif playerDotRef.current then
                 playerDotRef.current.Visible = false
             end
        end)
        
        return function()
            conn:Disconnect()
            if container then container:ClearAllChildren() end
        end
    end, {})
    
    return React.createElement("Frame", {
         Size = UDim2.fromScale(1, 1),
         BackgroundTransparency = 1,
         ZIndex = 100,
         [React.Event.InputBegan] = onInputBegan,
         [React.Event.InputChanged] = onInputChanged,
         [React.Event.InputEnded] = onInputEnded, 
    }, {
         Blur = React.createElement("BlurEffect", { Size = 15 }),
         
         MainPanel = React.createElement(Panel, {
             Size = UDim2.fromOffset(800, 600),
             Position = UDim2.fromScale(0.5, 0.5),
             AnchorPoint = Vector2.new(0.5, 0.5),
             BackgroundColor3 = Color3.fromRGB(30, 30, 35),
             Stroke = true,
             Shadow = true,
             ClipsDescendants = true,
         }, {
             Title = React.createElement("TextLabel", {
                 Text = "World Map",
                 Size = UDim2.new(1, 0, 0, 50),
                 BackgroundTransparency = 1,
                 TextColor3 = Color3.new(1,1,1),
                 Font = Enum.Font.GothamBold,
                 TextSize = 24,
                 ZIndex = 200,
             }),
             
             CloseBtn = React.createElement(Button, {
                  Text = "Close",
                  Size = UDim2.fromOffset(80, 32),
                  Position = UDim2.new(1, -20, 0, 10),
                  AnchorPoint = Vector2.new(1, 0),
                  BackgroundColor3 = Color3.fromRGB(200, 60, 60),
                  OnClick = props.onClose,
                  ZIndex = 210,
             }),
             Canvas = React.createElement("Frame", {
                 ref = containerRef,
                 Size = UDim2.new(1, -40, 1, -80),
                 Position = UDim2.fromOffset(20, 60),
                 BackgroundTransparency = 1,
                 ClipsDescendants = true,
             }, {
                 PlayerDot = React.createElement("Frame", {
                     ref = playerDotRef,
                     Size = UDim2.fromOffset(10, 10),
                     AnchorPoint = Vector2.new(0.5, 0.5),
                     BackgroundColor3 = Color3.new(1, 0, 0), -- Red Dot
                     ZIndex = 5,
                 }, {
                     Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
                 })
             })
         })
    })
end

return WorldMap
