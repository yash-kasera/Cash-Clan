local Lighting = game:GetService("Lighting")

-- Stylized Configuration
local CONFIG = {
	Ambient = Color3.fromRGB(50, 40, 70), -- Purple-ish shadows
	OutdoorAmbient = Color3.fromRGB(100, 100, 120), -- Bright ambient
	Brightness = 2.5,
	ShadowSoftness = 0.2,
	GlobalShadows = true,
	ClockTime = 14, -- Afternoon sun
	GeographicLatitude = 45,
	ExposureCompensation = 0.5,
	FogColor = Color3.fromRGB(180, 200, 220),
	FogEnd = 1000,
	FogStart = 50,
}

-- Apply Base Lighting
for prop, val in pairs(CONFIG) do
	Lighting[prop] = val
end

-- Create/Update Post-Processing Effects

-- 1. Atmosphere (Haze/Scattering)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(190, 210, 255)
atmosphere.Decay = Color3.fromRGB(100, 80, 60)
atmosphere.Glare = 0.5
atmosphere.Haze = 2
atmosphere.Parent = Lighting

-- 2. Bloom (Glow)
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity = 0.4
bloom.Size = 24
bloom.Threshold = 0.8
bloom.Parent = Lighting

-- 3. Depth of Field (Blur distance)
local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect")
dof.FarIntensity = 0.5
dof.FocusDistance = 50
dof.InFocusRadius = 30
dof.NearIntensity = 0
dof.Parent = Lighting

-- 4. Color Correction (Vibrancy)
local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
cc.Brightness = 0.05
cc.Contrast = 0.1
cc.Saturation = 0.3 -- Make colors pop!
cc.TintColor = Color3.fromRGB(255, 250, 240) -- Warm tint
cc.Parent = Lighting

-- 5. Sun Rays
local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
sunrays.Intensity = 0.2
sunrays.Spread = 0.8
sunrays.Parent = Lighting

print("Stylized Lighting Applied!")
