local React = require(game.ReplicatedStorage.Packages.React)
local Panel = require(script.Parent.components.Panel)
local Button = require(script.Parent.components.Button)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BuyToolFunc = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BuyTool")

-- Animation Constants
local SPRING_OPTS = { dampingRatio = 0.8, frequency = 4 }

local TOOLS = {
	{ Name = "Pickaxe", Cost = 500, Icon = "rbxassetid://6031265978" }, 
	{ Name = "Axe", Cost = 800, Icon = "rbxassetid://6031265978" },
	{ Name = "Hoe", Cost = 300, Icon = "rbxassetid://6031265978" },
	{ Name = "Shovel", Cost = 250, Icon = "rbxassetid://6031265978" },
}

local function toIndianCurrency(n)
	local s = tostring(n)
	local len = #s
	if len <= 3 then return "₹" .. s end
	
	local last3 = s:sub(-3)
	local rest = s:sub(1, -4)
	
	local distinct = ""
	local count = 0
	for i = #rest, 1, -1 do
		distinct = rest:sub(i, i) .. distinct
		count = count + 1
		if count == 2 and i > 1 then
			distinct = "," .. distinct
			count = 0
		end
	end
	
	return "₹" .. distinct .. "," .. last3
end

local function useRupees()
    local balance, setBalance = React.useState(0)
    
    React.useEffect(function()
        local player = Players.LocalPlayer
        local leaderstats = player:WaitForChild("leaderstats", 10)
        local rupees = leaderstats and leaderstats:WaitForChild("Rupees", 10)
        
        if rupees then
            setBalance(rupees.Value)
            local conn = rupees:GetPropertyChangedSignal("Value"):Connect(function()
                setBalance(rupees.Value)
            end)
            return function() conn:Disconnect() end
        end
    end, {})
    
    return balance
end

local function InteractionPrompt(props)
    local adornee = props.Adornee
    local onInteract = props.OnInteract
    local visible = props.Visible
    
    -- Animation State
    local scale, setScale = React.useState(0)
    
    React.useEffect(function()
        if visible then
            setScale(1)
        else
            setScale(0)
        end
    end, {visible})
    
    if not visible and scale < 0.01 then return nil end
    
    return React.createElement("BillboardGui", {
        Adornee = adornee,
        Size = UDim2.fromOffset(180, 50), -- Wider for text
        StudsOffset = Vector3.new(0, 3.5, 0), -- Slightly higher
        AlwaysOnTop = true,
        Active = true,
    }, {
         Container = React.createElement("CanvasGroup", {
             Size = UDim2.fromScale(scale, scale), -- Animate Scale
             Position = UDim2.fromScale(0.5, 0.5),
             AnchorPoint = Vector2.new(0.5, 0.5),
             BackgroundTransparency = 0.15,
             BackgroundColor3 = Color3.fromRGB(20, 20, 25), -- Darker modern bg
             GroupTransparency = 1 - scale,
         }, {
             UICorner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }), -- Softer corners
             
             UIListLayout = React.createElement("UIListLayout", {
                 FillDirection = Enum.FillDirection.Horizontal,
                 HorizontalAlignment = Enum.HorizontalAlignment.Center,
                 VerticalAlignment = Enum.VerticalAlignment.Center,
                 Padding = UDim.new(0, 8),
             }),
             
             KeyPill = React.createElement("Frame", {
                 Size = UDim2.fromOffset(30, 30),
                 BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                 BackgroundTransparency = 0.9,
             }, {
                 UICorner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
                 UIStroke = React.createElement("UIStroke", {
                     Color = Color3.fromRGB(255, 255, 255),
                     Transparency = 0.5,
                     Thickness = 1,
                 }),
                 Label = React.createElement("TextLabel", {
                     Size = UDim2.fromScale(1, 1),
                     Text = "E",
                     TextColor3 = Color3.fromRGB(255, 255, 255),
                     TextSize = 18,
                     Font = Enum.Font.GothamBold,
                     BackgroundTransparency = 1,
                 })
             }),
             
             Text = React.createElement("TextLabel", {
                 AutomaticSize = Enum.AutomaticSize.X,
                 Size = UDim2.fromScale(0, 1),
                 Text = "to buy",
                 TextColor3 = Color3.fromRGB(255, 255, 255),
                 TextSize = 16,
                 Font = Enum.Font.GothamMedium,
                 BackgroundTransparency = 1,
             }),
             
             Padding = React.createElement("UIPadding", {
                 PaddingLeft = UDim.new(0, 12),
                 PaddingRight = UDim.new(0, 12),
             }),
             
             Stroke = React.createElement("UIStroke", {
                 Color = Color3.fromRGB(255, 255, 255),
                 Transparency = 0.8,
                 Thickness = 2,
             })
         })
    })
end

local function ShopItem(props)
    local item = props.Item
    local onBuy = props.OnBuy
    
    local hovered, setHovered = React.useState(false)
    
    return React.createElement(Button, {
        Size = UDim2.fromOffset(100, 120),
        BackgroundColor3 = hovered and Color3.fromRGB(60, 60, 65) or Color3.fromRGB(50, 50, 55),
        OnClick = function() onBuy(item.Name) end,
        OnHover = function(h) setHovered(h) end,
    }, {
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromOffset(60, 60),
            Position = UDim2.fromScale(0.5, 0.3),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = item.Icon,
        }),
        Name = React.createElement("TextLabel", {
             Text = item.Name,
             Size = UDim2.new(1, 0, 0, 20),
             Position = UDim2.fromScale(0.5, 0.7),
             AnchorPoint = Vector2.new(0.5, 0.5),
             TextColor3 = Color3.new(1,1,1),
             BackgroundTransparency = 1,
             Font = Enum.Font.GothamBold,
        }),
        Cost = React.createElement("TextLabel", {
             Text = toIndianCurrency(item.Cost),
             Size = UDim2.new(1, 0, 0, 20),
             Position = UDim2.fromScale(0.5, 0.9),
             AnchorPoint = Vector2.new(0.5, 0.5),
             TextColor3 = Color3.fromRGB(100, 255, 100),
             BackgroundTransparency = 1,
             Font = Enum.Font.Gotham,
        })
    })
end

local function ShopApp(props)
    -- Props from Controller
    local shopOpen = props.shopOpen
    local closeShop = props.closeShop
    local nearbyNPC = props.nearbyNPC -- logic handled in Controller
    
    local transparency, setTransparency = React.useState(1)
    local balance = useRupees()
    
    React.useEffect(function()
        if shopOpen then
            setTransparency(0)
        else
            setTransparency(1)
        end
    end, {shopOpen})
    
    local onBuy = function(toolName)
        print("Buying", toolName)
        -- Call Server
        task.spawn(function() 
            local success, msg = BuyToolFunc:InvokeServer(toolName)
            print(success, msg)
            -- Show notification?
        end)
    end
    
    return React.createElement(React.Fragment, {}, {
        -- Interaction Prompt (Billboard)
        Prompt = nearbyNPC and React.createElement(InteractionPrompt, {
            Adornee = nearbyNPC,
            Visible = not shopOpen, -- Hide prompt if shop is open
        }),
        
        -- Shop GUI (ScreenGui)
        ShopInterface = React.createElement("ScreenGui", {
            Enabled = shopOpen or transparency < 1,
            ResetOnSpawn = false,
        }, {
            Overlay = React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0,0,0),
                BackgroundTransparency = 0.5 + (transparency * 0.5), -- Fade in background
                Active = true, -- Block input
            }, {
                Container = React.createElement(Panel, {
                    Size = UDim2.fromOffset(400, 300),
                    Position = UDim2.fromScale(0.5, 0.5), -- Center
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                    BackgroundTransparency = transparency,
                }, {
                    Title = React.createElement("TextLabel", {
                        Text = "Tools Shop",
                         Size = UDim2.new(1, 0, 0, 50),
                         BackgroundTransparency = 1,
                         TextColor3 = Color3.new(1,1,1),
                         Font = Enum.Font.GothamBlack,
                         TextSize = 28,
                    }),
                    
                    Balance = React.createElement("TextLabel", {
                        Text = "Balance: " .. toIndianCurrency(balance),
                        Size = UDim2.new(0, 150, 0, 30),
                        Position = UDim2.new(1, -50, 0, 10), -- Moved left to avoid CloseX
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(255, 220, 100), -- Gold color
                        Font = Enum.Font.GothamBold,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Right,
                    }),
                    
                    Grid = React.createElement("ScrollingFrame", {
                         Size = UDim2.new(1, -20, 1, -70),
                         Position = UDim2.fromOffset(10, 60),
                         BackgroundTransparency = 1,
                         ScrollBarThickness = 4,
                    }, {
                        Layout = React.createElement("UIGridLayout", {
                            CellSize = UDim2.fromOffset(110, 130),
                            CellPadding = UDim2.fromOffset(10, 10),
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        }),
                        
                        -- Render Items
                        React.createElement(React.Fragment, {}, 
                            table.unpack(
                                 -- Map tools to elements
                                 (function()
                                     local elements = {}
                                     for _, t in ipairs(TOOLS) do
                                         table.insert(elements, React.createElement(ShopItem, { 
                                             Item = t,
                                             OnBuy = onBuy
                                         }))
                                     end
                                     return elements
                                 end)()
                            )
                        )
                    }),
                    
                    CloseX = React.createElement(Button, {
                        Text = "X",
                        Size = UDim2.fromOffset(30, 30),
                        Position = UDim2.new(1, -10, 0, 10),
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                        OnClick = closeShop,
                        Visible = false, -- Kept hidden as per previous state, but fixing overlap providing optionality
                    }) 
                })
            })
        })
    })
end

return ShopApp

