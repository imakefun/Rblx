--!strict
-- DayNightCycle.luau
-- Server-authoritative day/night cycle with smooth TweenService transitions.
--
-- The server drives Lighting.ClockTime and ambient colors. Because Lighting is
-- a replicated service, ALL clients see the exact same sky automatically.
-- No client-side scripts are needed for the cycle itself.
--
-- ARCHITECTURE:
--   GameManager calls DayNightCycle.Update(dt) each Heartbeat.
--   DayNightCycle owns Lighting state and sol counting.
--   Other modules register callbacks via OnSolChanged / OnNightChanged.
--
-- Place in: ServerScriptService

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local DayNightCycle = {}

-------------------------------------------------------------------------------
-- Constants (derived from Config)
-------------------------------------------------------------------------------

local DAY_LENGTH: number = Config.DAY_LENGTH     -- 360s (6 min real time)
local NIGHT_LENGTH: number = Config.NIGHT_LENGTH  -- 240s (4 min real time)
local TOTAL_CYCLE: number = Config.CYCLE_LENGTH   -- 600s
local DAWN_HOUR: number = Config.DAWN_HOUR        -- 6.0 ClockTime
local DUSK_HOUR: number = Config.DUSK_HOUR        -- 18.0 ClockTime
local MAX_SOL: number = Config.MAX_SOL            -- 99

-- TweenInfo for ambient color transitions between day/night
local COLOR_TWEEN_INFO: TweenInfo = TweenInfo.new(
	8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
)

-------------------------------------------------------------------------------
-- Lighting presets
-- Day = warm Earth-like. Night = cold alien purple. Dawn = warm amber.
-------------------------------------------------------------------------------

local DAY_PRESET = {
	Brightness = 2,
	Ambient = Color3.fromRGB(135, 135, 128),
	OutdoorAmbient = Color3.fromRGB(128, 128, 128),
	ColorShift_Top = Color3.fromRGB(128, 128, 128),
	ColorShift_Bottom = Color3.fromRGB(77, 77, 77),
	FogColor = Color3.fromRGB(192, 200, 206),
	FogEnd = 1500,
}

local NIGHT_PRESET = {
	Brightness = 0,
	Ambient = Color3.fromRGB(20, 15, 35),
	OutdoorAmbient = Color3.fromRGB(15, 10, 30),
	ColorShift_Top = Color3.fromRGB(0, 0, 25),
	ColorShift_Bottom = Color3.fromRGB(0, 0, 13),
	FogColor = Color3.fromRGB(10, 8, 20),
	FogEnd = 200,
}

local DAWN_PRESET = {
	Brightness = 1,
	Ambient = Color3.fromRGB(100, 80, 70),
	OutdoorAmbient = Color3.fromRGB(120, 90, 70),
	ColorShift_Top = Color3.fromRGB(180, 100, 50),
	ColorShift_Bottom = Color3.fromRGB(50, 30, 20),
	FogColor = Color3.fromRGB(160, 110, 80),
	FogEnd = 800,
}

-------------------------------------------------------------------------------
-- Internal state
-------------------------------------------------------------------------------

local currentSol: number = 1
local timeInCycle: number = 0
local isNight: boolean = false
local activeTween: Tween? = nil

local solChangedCallbacks: { (sol: number) -> () } = {}
local nightChangedCallbacks: { (night: boolean) -> () } = {}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--- Smoothly tween all Lighting properties to a preset.
local function tweenToPreset(preset: { [string]: any }, tweenInfo: TweenInfo?)
	if activeTween then
		activeTween:Cancel()
	end

	local info = tweenInfo or COLOR_TWEEN_INFO
	activeTween = TweenService:Create(Lighting, info, {
		Brightness = preset.Brightness,
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		ColorShift_Top = preset.ColorShift_Top,
		ColorShift_Bottom = preset.ColorShift_Bottom,
		FogColor = preset.FogColor,
		FogEnd = preset.FogEnd,
	})
	activeTween:Play()

	-- Also tween Atmosphere if present (volumetric fog)
	local atmosphere: Atmosphere? = Lighting:FindFirstChildOfClass("Atmosphere") :: Atmosphere?
	if atmosphere then
		local density: number = if preset == NIGHT_PRESET then 0.5 else 0.25
		TweenService:Create(atmosphere, info, {
			Density = density,
			Color = preset.FogColor,
		}):Play()
	end
end

--- Apply a preset instantly (no animation). Used at startup.
local function applyPresetInstant(preset: { [string]: any })
	for key, value in preset do
		(Lighting :: any)[key] = value
	end
end

--- Map timeInCycle to ClockTime (0-24 hours).
local function computeClockTime(t: number): (number, boolean)
	if t < DAY_LENGTH then
		local dayProgress = t / DAY_LENGTH
		local ct = lerp(DAWN_HOUR, DUSK_HOUR, dayProgress)
		return ct, false
	else
		local nightProgress = (t - DAY_LENGTH) / NIGHT_LENGTH
		local ct = DUSK_HOUR + nightProgress * (24 - DUSK_HOUR + DAWN_HOUR)
		if ct >= 24 then ct -= 24 end
		return ct, true
	end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function DayNightCycle.GetSol(): number
	return currentSol
end

function DayNightCycle.IsNight(): boolean
	return isNight
end

function DayNightCycle.GetClockTime(): number
	return Lighting.ClockTime
end

function DayNightCycle.GetTimeInCycle(): number
	return timeInCycle
end

function DayNightCycle.OnSolChanged(callback: (sol: number) -> ())
	table.insert(solChangedCallbacks, callback)
end

function DayNightCycle.OnNightChanged(callback: (isNight: boolean) -> ())
	table.insert(nightChangedCallbacks, callback)
end

--- Initialize to dawn of Sol 1.
function DayNightCycle.Init()
	currentSol = 1
	timeInCycle = 0
	isNight = false
	Lighting.ClockTime = DAWN_HOUR
	applyPresetInstant(DAY_PRESET)
end

--- Advance the cycle by dt seconds. Called by GameManager each Heartbeat.
function DayNightCycle.Update(dt: number): boolean
	timeInCycle += dt

	-- Check for cycle wrap (new sol)
	if timeInCycle >= TOTAL_CYCLE then
		timeInCycle -= TOTAL_CYCLE
		currentSol = math.min(currentSol + 1, MAX_SOL)
		for _, cb in solChangedCallbacks do
			task.spawn(cb, currentSol)
		end
	end

	-- Set ClockTime
	local ct: number
	local nightNow: boolean
	ct, nightNow = computeClockTime(timeInCycle)
	Lighting.ClockTime = ct

	-- Detect transitions
	local wasNight = isNight
	isNight = nightNow

	if isNight ~= wasNight then
		if isNight then
			tweenToPreset(NIGHT_PRESET)
		else
			-- Brief amber dawn, then transition to full daylight
			tweenToPreset(DAWN_PRESET, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
			task.delay(5, function()
				if not isNight then
					tweenToPreset(DAY_PRESET)
				end
			end)
		end

		for _, cb in nightChangedCallbacks do
			task.spawn(cb, isNight)
		end
	end

	return isNight
end

return DayNightCycle
