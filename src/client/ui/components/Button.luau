local React = require(game.ReplicatedStorage.Packages.React)

function Button(props)
    local hovered, setHovered = React.useState(false)
    
    return React.createElement("TextButton", {
        Text = props.Text or "",
        Size = props.Size or UDim2.fromOffset(120, 40),
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        BackgroundColor3 = hovered and (props.HoverColor or Color3.fromRGB(50, 50, 60)) or (props.BackgroundColor3 or Color3.fromRGB(40, 40, 50)),
        TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255),
        Font = props.Font or Enum.Font.GothamBold,
        TextSize = props.TextSize or 18,
        AutoButtonColor = true,
        ZIndex = props.ZIndex,
        
        [React.Event.MouseEnter] = function() setHovered(true) end,
        [React.Event.MouseLeave] = function() setHovered(false) end,
        [React.Event.Activated] = props.OnClick,
    }, {
        UICorner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Content = React.createElement(React.Fragment, nil, props.children)
    })
end

return Button
