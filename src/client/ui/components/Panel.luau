local React = require(game.ReplicatedStorage.Packages.React)

function Panel(props)
	-- Helper to merge children with our structural elements
	-- print("Panel: Rendering...")
	local children = props.children or {}
	
	-- We want to put our structural elements (Corner, Stroke, etc) AND the passed children
	-- into the same table for React.createElement's 3rd argument.
	
	-- React.createElement(type, props, children)
	
	return React.createElement("Frame", {
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(30, 30, 35),
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		ClipsDescendants = props.ClipsDescendants,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
	}, React.createElement(React.Fragment, nil, {
		UICorner = React.createElement("UICorner", {
			CornerRadius = props.CornerRadius or UDim.new(0, 12),
		}),
		UIStroke = props.Stroke and React.createElement("UIStroke", {
			Color = props.StrokeColor or Color3.fromRGB(255, 255, 255),
			Thickness = props.StrokeThickness or 2,
			Transparency = props.StrokeTransparency or 0,
		}),
		Shadow = props.Shadow and React.createElement("ImageLabel", {
			ZIndex = (props.ZIndex or 1) - 1,
			Position = UDim2.fromOffset(-15, -15),
			Size = UDim2.new(1, 30, 1, 30),
			BackgroundTransparency = 1,
			Image = "rbxassetid://6015897843",
			ImageColor3 = Color3.new(0, 0, 0),
			ImageTransparency = 0.5,
			SliceCenter = Rect.new(49, 49, 450, 450),
			ScaleType = Enum.ScaleType.Slice,
		}),
		Content = React.createElement(React.Fragment, nil, children)
	}))
end

return Panel
