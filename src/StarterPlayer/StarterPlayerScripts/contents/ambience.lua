local module = {}

-- Manages sounds and some aesthetics.
-- One of the first local scripts made for Vesteria. Not clean, needs improvements
-- Author: berezaa


if game.ReplicatedStorage:FindFirstChild("overrideAmbience") then
	return
end


local network
local tween

local userSettings

local tracks = {}
local dead
local step = 1/5
local lastUpdate
local easing = Enum.EasingStyle.Linear

local camera = workspace.CurrentCamera


local function addTrack(track)
	track.Parent = camera
	table.insert(tracks,track)
	track.Volume = 0
	track.Looped = true
end

local function mergeColors(dayColor, nightColor, Brightness)
	local dr, dg, db = Color3.toHSV(dayColor)
	local nr, ng, nb = Color3.toHSV(nightColor)

	return Color3.fromHSV(nr + (dr - nr) * Brightness, ng + (dg - ng) * Brightness, nb + (db - nb) * Brightness)
end

local function lightingUpdate()
	local light = game.ReplicatedStorage:FindFirstChild("lightingSettings")

	local dayAmbient = light and light:FindFirstChild("dayAmbient") and light.dayAmbient.Value or (Color3.fromRGB(100, 100, 100))
	local nightAmbient = light and light:FindFirstChild("nightAmbient") and light.nightAmbient.Value or Color3.fromRGB(50, 50, 100)

	local ClockTime = game.Lighting.ClockTime
	local Brightness = 0
	-- Night
	if ClockTime < 5.0 or ClockTime > 18.5 then
		Brightness = 0
	-- Sunrise
	elseif ClockTime >= 5.0 and ClockTime <= 6.5 then
		local Progress = (ClockTime - 5.0) / 1.5
		Brightness = Progress
	-- Sunset
	elseif ClockTime >= 17.5 and ClockTime <= 18.5 then
		local Progress = (ClockTime - 17.5)
		Brightness = 1 - Progress
	-- Day
	else
		Brightness = 1
	end

	if lastUpdate then
		step = tick() - lastUpdate
	end

	local newTime = game.ReplicatedStorage.timeOfDay.Value

	if newTime < ClockTime then
		game.Lighting.ClockTime = newTime
	else
		tween(game.Lighting, {"ClockTime"}, newTime, step, easing)
	end


	if Brightness ~= PreviousBrightness then
		local dayFogColor = light and light:FindFirstChild("dayFogColor") and light.dayFogColor.Value or Color3.fromRGB(151, 213, 214)
		local nightFogColor = light and light:FindFirstChild("nightFogColor") and light.nightFogColor.Value or Color3.fromRGB(0, 66, 120)
		local ambientColor = mergeColors(dayAmbient, nightAmbient, Brightness)
		local fogColor = mergeColors(dayFogColor, nightFogColor, Brightness)
		tween(game.Lighting, {"Ambient", "FogColor", "ExposureCompensation"}, {ambientColor, fogColor, Brightness}, step, easing)
		tween(game.Lighting.Atmosphere, {"Density", "Color", "Haze", "Glare"}, {0.438 - 0.164 * Brightness, fogColor, 2.15 - 2.15 * Brightness, 10 * Brightness}, step, easing)
	end

	Brightness = PreviousBrightness
	lastUpdate = tick()
end


--game.Lighting:GetPropertyChangedSignal("ClockTime"):connect(lightingUpdate)



game.SoundService:GetPropertyChangedSignal("AmbientReverb"):connect(function(Value)
	if game.SoundService.AmbientReverb == Enum.ReverbType.UnderWater then
		if game.SoundService:FindFirstChild("Underwater") then
			for i, track in pairs(tracks) do
				track.SoundGroup = game.SoundService.Underwater

			end
		end
	else

		for i, track in pairs(tracks) do
			track.SoundGroup = nil
		end
	end
end)

local currentTrack = ""

local musicVolume = 0.5


local function setMusicVolume(volume)
	musicVolume = 1 * volume

	for i,track in pairs(tracks) do
		if track.Name == currentTrack then
			track.Volume = musicVolume * 0.27
		end
	end
end

local function playTrack(trackName)
	if currentTrack ~= trackName then
		currentTrack = trackName
		for _, track in pairs(tracks) do
			if track.Name == trackName then

					track:Play()
					track.Volume = musicVolume * 0.27
			elseif track.Volume > 0 then

					track:Stop()
					track.Volume = 0
			end
		end
	end
end

local overriden = false

local function overrideTrack(track)
	if not overriden then
		overriden = true
		addTrack(track)
		playTrack(track.Name)
	end
end

if game.ReplicatedStorage:FindFirstChild("backgroundMusic") then
	overrideTrack(game.ReplicatedStorage.backgroundMusic)
else
	playTrack("Village")
end
game.ReplicatedStorage.ChildAdded:connect(function(child)
	if child.Name == "backgroundMusic" then
		overrideTrack(child)
	end
end)


local noise = Instance.new("Sound")
noise.Parent = script
noise.Volume = 0.1
noise.Looped = true
noise.Name = "noise"

local function setNoise(soundId)
	if noise.SoundId ~= soundId then
		noise:Stop()
		noise.SoundId = soundId
		noise:Play()
	end
end

local function backgroundNoise()
	if game.PlaceId == 3232913902 or game.PlaceId == 2544075708 then return end -- crabby den and shiprock bottom. no crickets at these places

	if game.Lighting.ClockTime <= 6.5 or game.Lighting.ClockTime >= 18 then
		setNoise("rbxassetid://"..2049803364)
		noise.Volume = 0.27
	else
		if workspace:FindFirstChild("forest") then
			setNoise("rbxassetid://"..2050179392)
			noise.Volume = 0.4
		else
			setNoise("rbxassetid://"..2050176819)
			noise.Volume = 0.75
		end
	end
end




local function onDataUpdate(key, value)
	if key == "userSettings" then
		userSettings = value
		setMusicVolume(value.musicVolume or 0.5)
	end
end


local function isNight()
	return game.Lighting.ClockTime < 5.9 or game.Lighting.ClockTime > 18.6
end

-- Sunrise: 5.6 - 6.6
-- Sunset: 17.6 - 18.6
local function timeOfDayPitch()
	if game.Lighting.ClockTime < 5.9 or game.Lighting.ClockTime > 18.6 then
		return 1--0.8
	elseif game.Lighting.ClockTime >= 5.6 and game.Lighting.ClockTime <= 6.6 then
		return 1--0.8 + 0.2 * (game.Lighting.ClockTime - 5.6)
	elseif game.Lighting.ClockTime >= 17.6 and game.Lighting.ClockTime <= 18.6 then
		return 1-- - 0.2 * (game.Lighting.ClockTime - 17.6)
	else
		return 1
	end
end


local function setIsDead(isDead)
	dead = isDead
	for i,track in pairs(tracks) do
		track.PlaybackSpeed = (dead and 0.4 or timeOfDayPitch())
	end
end

local function main()
	workspace:WaitForChild("Camera")
	local assetFolder = script.Parent.Parent:WaitForChild("assets")
	camera = workspace.CurrentCamera
	for _, child in pairs(assetFolder.tracks:GetChildren()) do
		addTrack(child)
	end
	if userSettings.musicVolume then
		setMusicVolume(userSettings.musicVolume or 0.5)
	end
	game.ReplicatedStorage.timeOfDay.Changed:connect(lightingUpdate)
	assetFolder.tracks.ChildAdded:Connect(addTrack)
	lightingUpdate()
	backgroundNoise()
	game.Lighting:GetPropertyChangedSignal("ClockTime"):connect(backgroundNoise)
	while wait(1) do
		for i,track in pairs(tracks) do
			track.PlaybackSpeed = (dead and 0.4 or timeOfDayPitch())
		end
	end
end


function module.init(Modules)
	network = Modules.network
	tween = Modules.tween

	userSettings = network:invoke("getCacheValueByNameTag", "userSettings")

	network:create("musicVolumeChanged", "BindableEvent", "Event", setMusicVolume)
	network:create("ambienceSetIsDead", "BindableFunction", "OnInvoke", setIsDead)
	network:connect("propogationRequestToSelf", "Event", onDataUpdate)

	spawn(main)
end

return module