-- MapSetup.server.luau
-- Creates the ground terrain and spawn location

local Players = game:GetService("Players")

-- Create ground plane
local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Size = Vector3.new(500, 1, 500)
ground.Position = Vector3.new(0, -0.5, 0)
ground.Anchored = true
ground.Material = Enum.Material.Grass
ground.Color = Color3.fromRGB(50, 80, 35)
ground.Parent = workspace

-- Create spawn location near the Signal Fire
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(8, 0.5, 8)
spawn.Anchored = true
spawn.Material = Enum.Material.Metal
spawn.Color = Color3.fromRGB(100, 100, 110)
spawn.Transparency = 0.5
spawn.CanCollide = true
spawn.Parent = workspace

-- Disable the default spawn decal
spawn.Enabled = true

-- Set spawn point for all players
Players.CharacterAutoLoads = true

-- Add some atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.2
atmosphere.Color = Color3.fromRGB(180, 185, 195)
atmosphere.Decay = Color3.fromRGB(120, 100, 140)  -- slight purple alien tint
atmosphere.Glare = 0.2
atmosphere.Haze = 2
atmosphere.Parent = game:GetService("Lighting")

-- Sky with subtle alien undertones
local sky = Instance.new("Sky")
sky.StarCount = 3000
sky.MoonAngularSize = 8       -- smaller than Earth's moon
sky.SunAngularSize = 18       -- slightly different sun
sky.Parent = game:GetService("Lighting")

-- Bloom for fire glow
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 2
bloom.Parent = game:GetService("Lighting")

-- Color correction for alien feel
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0
colorCorrection.Contrast = 0.05
colorCorrection.Saturation = 0.1
colorCorrection.TintColor = Color3.fromRGB(255, 252, 248)  -- very subtle warm tint
colorCorrection.Parent = game:GetService("Lighting")

print("[MapSetup] Ground, spawn, and atmosphere initialized")
