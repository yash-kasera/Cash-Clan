local React = require(game.ReplicatedStorage.Packages.React)
local Minimap = require(script.Parent.RealtimeMinimap)
local WorldMap = require(script.Parent.WorldMap)

local function MapApp()
	local isWorldMapOpen, setIsWorldMapOpen = React.useState(false)

	React.useEffect(function()
		local UserInputService = game:GetService("UserInputService")
		local conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == Enum.KeyCode.M then
				setIsWorldMapOpen(function(prev) return not prev end)
			end
		end)
		return function() conn:Disconnect() end
	end, {})

	return React.createElement(React.Fragment, {}, {
		Minimap = not isWorldMapOpen and React.createElement(Minimap),
		WorldMap = isWorldMapOpen and React.createElement(WorldMap, {
			onClose = function() setIsWorldMapOpen(false) end
		})
	})
end

return MapApp
