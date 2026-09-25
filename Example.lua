local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Overlay"))
local Signal = Library.Signal

Library.Hidden = true --// Makes the ui harder to read
Library.LibraryDebugs = true --// Enables error calling

Library:SetIconPack("Solar") --// https://github.com/Footagesus/Icons

local IsMobile = Library.IsMobile
local IsStudio = Library.IsStudio

Library:SetGlobal("Waves", "rbxassetid://82295031952284")
local Global = Library.Global

local Notify = Signal.New()
Notify:Connect(function(Title, Content)
	local Notification = Library:Notify({
		Title = Title,
		Content = Content,
		Icon = "Info",
		Background = Global.Waves,
		Close = "Body Click",
	})
end)

local Window, Body = Library:Window({
	TITLE = "Overlay Window Example",
	subtitle = "Made by severitysvc | Version 1.1",

	WindowSize = UDim2.fromOffset(700, 500),
	UIScale = 1,

	Minimized = false,
	MinimizeKeybind = Enum.KeyCode.RightShift,

	Theme = "Dark",
	BackgroundImage = "",

	Profile = {
		AnonymousScreenshot = false,
		UserAnonym = true,
		DisplayAnonym = true,
		Transparent = true,
	},
})

Window:SetBackgroundImage("rbxassetid://82295031952284")
Window:SetBackgroundImageTransparency(0.9)

local Title = Window.Title
local Subtitle = Window.SubTitle

Title.TextSize = 17
Title.TextTransparency = 0.4

local OnMinimize = Window.OnMinimize
local OnDestroy = Window.OnDestroy

OnMinimize:Connect(function()
	Notify:Fire("Library Action", "Use " .. Window.MinimizeKeybind.Name .. " to open the ui")
end)

local Overview = Window:Section({
	Title = "Overview",
	Transparency = "Max",
	Opened = true,
})

local Dashboard = Overview:Tab({
	Title = "Dashboard",
	Description = "Manage you client",
	Icon = "rbxassetid://91164200324199",
})

local Personalization = Overview:Tab({
	Title = "Personalization",
	Description = "Customiza the interface",
	Icon = "rbxassetid://89335485534775",
	Section = {
		ShowIcon = false,
	},
})

Dashboard:Select()

task.spawn(function() --// Themes
	Library:CreateTheme({
		Name = "Slate",
		BackgroundColor = Color3.fromRGB(13, 16, 23),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(88, 166, 255),
		TextColor = Color3.fromRGB(230, 237, 243),
		IconColor = Color3.fromRGB(160, 175, 195),
	})

	Library:CreateTheme({
		Name = "Ember",
		BackgroundColor = Color3.fromRGB(25, 18, 15),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(255, 135, 50),
		TextColor = Color3.fromRGB(245, 240, 235),
		IconColor = Color3.fromRGB(195, 160, 140),
	})

	Library:CreateTheme({
		Name = "Forest",
		BackgroundColor = Color3.fromRGB(13, 23, 16),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(50, 200, 100),
		TextColor = Color3.fromRGB(235, 245, 240),
		IconColor = Color3.fromRGB(150, 180, 160),
	})

	Library:CreateTheme({
		Name = "Aqua",
		BackgroundColor = Color3.fromRGB(10, 20, 25),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(0, 220, 255),
		TextColor = Color3.fromRGB(230, 245, 250),
		IconColor = Color3.fromRGB(140, 180, 195),
	})

	Library:CreateTheme({
		Name = "Blossom",
		BackgroundColor = Color3.fromRGB(25, 15, 22),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(255, 105, 180),
		TextColor = Color3.fromRGB(250, 235, 245),
		IconColor = Color3.fromRGB(195, 150, 175),
	})

	Library:CreateTheme({
		Name = "Verdant",
		BackgroundColor = Color3.fromRGB(10, 28, 18),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(30, 230, 90),
		TextColor = Color3.fromRGB(205, 250, 220),
		IconColor = Color3.fromRGB(100, 220, 140),
	})

	Library:CreateTheme({
		Name = "Acvatic",
		BackgroundColor = Color3.fromRGB(5, 25, 32),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(0, 240, 255),
		TextColor = Color3.fromRGB(195, 245, 255),
		IconColor = Color3.fromRGB(90, 215, 240),
	})

	Library:CreateTheme({
		Name = "Rose Light",
		BackgroundColor = Color3.fromRGB(250, 242, 245),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(240, 130, 175),
		TextColor = Color3.fromRGB(45, 35, 42),
		IconColor = Color3.fromRGB(160, 105, 130),
	})

	Library:CreateTheme({
		Name = "Cherry Light",
		BackgroundColor = Color3.fromRGB(252, 242, 243),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(235, 75, 90),
		TextColor = Color3.fromRGB(48, 32, 35),
		IconColor = Color3.fromRGB(165, 90, 100),
	})

	Library:CreateTheme({
		Name = "Sky Light",
		BackgroundColor = Color3.fromRGB(240, 246, 252),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(45, 135, 235),
		TextColor = Color3.fromRGB(30, 40, 55),
		IconColor = Color3.fromRGB(110, 145, 175),
	})

	Library:CreateTheme({
		Name = "Amber Light",
		BackgroundColor = Color3.fromRGB(253, 248, 240),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(225, 140, 30),
		TextColor = Color3.fromRGB(50, 42, 35),
		IconColor = Color3.fromRGB(160, 125, 90),
	})

	Library:CreateTheme({
		Name = "Blossom ++",
		BackgroundColor = Color3.fromRGB(30, 10, 24),
		BackgroundTransparency = 0.15,
		AccentColor = Color3.fromRGB(255, 75, 180),
		TextColor = Color3.fromRGB(255, 210, 238),
		IconColor = Color3.fromRGB(240, 120, 190),
	})
end)

task.spawn(function() --// Dashboard
	local OnSelect = Dashboard.OnSelect
	local OnDeselect = Dashboard.OnDeselect

	Dashboard.OnDeselect:Connect(function()
		Notify:Fire("Action", "Left dashboard tab")
	end)

	Dashboard:Label({
		Title = "Welcome, " .. Library.Player.DisplayName,
	})

	local Banner, Body = Dashboard:ProfileBanner()

	local Main = Dashboard:Section({
		Blank = true,
		Transparency = "Max",
		Opened = true,
		ElementPadding = 0,
		ElementCornerSize = 0,
	})

	Main:Label({
		Title = "Script Info",
	})

	Main:BodyLabel({
		Title = "Discord Invite",
		Stroke = false,
		Transparency = "Min",
		Desc = "Click to copy invite",
		Value = "https://discord.gg/AVrAKebE9",
	})

	Main:BodyLabel({
		Title = "Script version",
		Stroke = false,
		Transparency = "Min",
		Desc = "Current version of the script",
		Value = "version 1.0.5",
	})

	Main:BodyLabel({
		Title = "Executor Name",
		Stroke = false,
		Transparency = "Min",
		Desc = "Name of the executor you're using",
		Value = "Potassium",
	})

	Main:BodyLabel({
		Title = "Server Region",
		Stroke = false,
		Transparency = "Min",
		Desc = "Current server region",
		Value = "US-East",
	})

	Main:Label({
		Title = "Game Info",
	})

	Main:BodyLabel({
		Title = "Game Name",
		Stroke = false,
		Transparency = "Min",
		Desc = "Name of the game",
		Value = "Rivals",
	})

	Main:BodyLabel({
		Title = "Job ID",
		Desc = "Click to copy",
		Stroke = false,
		Transparency = "Min",
		Value = game.JobId,
		Callback = function()
			Notify:Fire("Dashboard", "Copied the game job id.")
		end,
	})

	Main:BodyLabel({
		Title = "Players",
		Stroke = false,
		Transparency = "Min",
		Desc = "Number of players in-game.",
		Value = "1 / 20",
	})

	Main:BodyLabel({
		Title = "Server Region",
		Stroke = false,
		Transparency = "Min",
		Desc = "Current server region",
		Value = "US-East",
	})
end)

task.spawn(function() --// Personalization
	local Animation = ""
	local Theme = Library:GetTheme()

	Personalization:Keybind({
		Title = "UI Minimize Keybind",
		Description = "Click to change the minimize keybind",
		Value = Window.MinimizeKeybind,
		Callback = function(Keybind)
			Window.MinimizeKeybind = Keybind
		end,

		KeyPressCallback = function()
			Notify:Fire("Action", "Toggled the window.")
		end,
	})

	local Themes = Personalization:Section({
		Transparency = "Max",
		Opened = true,
		Blank = true,
		ElementPadding = 0,
		ElementCornerSize = 0,
	})

	Themes:Label({
		Title = "Themes",
	})

	Themes:Dropdown({
		Title = "Themes",
		Description = "Select the theme you want",
		Icon = "solar:pallete-2-bold",
		Values = Library:GetThemes(),
		Value = Theme,
		DropdownIcon = false,
		Multi = false,
		Callback = function(Value: StringValue)
			Theme = Value
		end,
	})

	Themes:ColorPicker({
		Title = "Window Color",
		Description = "Pick the Window color (will be overwrited by selecting a new theme)",
		Color = Color3.fromRGB(9, 9, 9),
		Callback = function(Value)
			Body.Window.BackgroundColor3 = Value
		end,
	})

	Themes:Button({
		Title = "Apply Selected Theme",
		Description = "Apply the selected theme",
		Callback = function()
			Library:SetTheme(Theme)
			Notify:Fire("Personalization", "Set theme to: " .. Library:GetTheme())
		end,
	})

	local Corners = Personalization:Section({
		Transparency = "Max",
		Opened = true,
		Blank = true,
		ElementPadding = 0,
		ElementCornerSize = 0,
	})

	Corners:Label({
		Title = "Top Left Corner",
	})

	Corners:Toggle({
		Title = "Visible",
		Description = "Enable / Disable the top left corner glow",
		Value = true,
		Callback = function(State)
			Window:SetCornerProperty("TopLeft", "Visible", State)
		end,
	})

	Corners:Slider({
		Title = "Transparency",
		Description = "Change the top left glow transparency",
		Min = 0,
		Max = 1,
		Step = 0.01,
		Value = 0.9,
		SmoothSlider = true,
		Callback = function(Value)
			Window:SetCornerProperty("TopLeft", "ImageTransparency", Value)
		end,
	})

	Corners:Label({
		Title = "Top Right Corner",
	})

	Corners:Toggle({
		Title = "Visible",
		Description = "Enable / Disable the top right corner glow",
		Value = true,
		Callback = function(State)
			Window:SetCornerProperty("TopRight", "Visible", State)
		end,
	})

	Corners:Slider({
		Title = "Transparency",
		Description = "Change the top right glow transparency",
		Min = 0,
		Max = 1,
		Step = 0.01,
		Value = 0.9,
		SmoothSlider = true,
		Callback = function(Value)
			Window:SetCornerProperty("TopRight", "ImageTransparency", Value)
		end,
	})

	Corners:Label({
		Title = "Down Left Corner",
	})

	Corners:Toggle({
		Title = "Visible",
		Description = "Enable / Disable the down left corner glow",
		Value = true,
		Callback = function(State)
			Window:SetCornerProperty("DownLeft", "Visible", State)
		end,
	})

	Corners:Slider({
		Title = "Transparency",
		Description = "Change the down left glow transparency",
		Min = 0,
		Max = 1,
		Step = 0.01,
		Value = 0.9,
		SmoothSlider = true,
		Callback = function(Value)
			Window:SetCornerProperty("DownLeft", "ImageTransparency", Value)
		end,
	})

	Corners:Label({
		Title = "Down Right Corner",
	})

	Corners:Toggle({
		Title = "Visible",
		Description = "Enable / Disable the down right corner glow",
		Value = true,
		Callback = function(State)
			Window:SetCornerProperty("DownRight", "Visible", State)
		end,
	})

	Corners:Slider({
		Title = "Transparency",
		Description = "Change the down right glow transparency",
		Min = 0,
		Max = 1,
		Step = 0.01,
		Value = 0.9,
		SmoothSlider = true,
		Callback = function(Value)
			Window:SetCornerProperty("DownRight", "ImageTransparency", Value)
		end,
	})

	local Animations = Personalization:Section({
		Transparency = "Max",
		Opened = true,
		Blank = true,
		ElementPadding = 0,
		ElementCornerSize = 0,
	})

	Animations:Label({
		Title = "Animations",
	})

	Animations:Dropdown({
		Title = "Animation",
		Description = "Select the animation you want",
		Icon = "solar:play-circle-bold",
		Values = { "Parallax" },
		Value = "Parallax",
		DropdownIcon = false,
		Multi = false,
		Callback = function(Value: StringValue)
			Animation = Value
		end,
	})

	Animations:Button({
		Title = "Load Animation",
		Description = "Load the selected animation",
		Callback = function()
			if Animation then
				Notify:Fire("Personalization", "Loaded Animation: " .. Animation)

				if Animation == "Parallax" then
					Window:LoadAnimation("Parallax", {
						LightHouseAngle = 10,
						LightHouseSpeed = 1,
						LightHouseBobAmplitude = 0.01,
						LightHouseBobMultipliers = { 1, 1 },
						LightHouseTiltMultipliers = { 0.8, 0.8 },
						LightHouseXPositions = { 0.15, 0.75 },
						LightHouseYPosition = 0.9,
						WaveAmplitude = 0.05,
						WaveAmplitudeStep = 1,
						WaveBaseSpeed = 2,
						WaveSpeedStep = 0.5,
						WaveHeight = 0.235,
					})
				end
			end
		end,
	})

	Animations:Button({
		Title = "UnLoad Animation",
		Description = "UnLoad the selected theme",
		Callback = function()
			Window:UnloadAnimation()
		end,
	})
end)

task.spawn(function() --// Corner effects
	Window:SetCornerProperty("DownLeft", "ImageTransparency", 0.9)
	Window:SetCornerProperty("DownLeft", "ZIndex", 10)

	Window:SetCornerProperty("DownRight", "ImageTransparency", 0.9)
	Window:SetCornerProperty("DownRight", "ZIndex", 10)

	Window:SetCornerProperty("TopRight", "ImageTransparency", 0.9)
	Window:SetCornerProperty("TopRight", "ZIndex", 10)

	Window:SetCornerProperty("TopLeft", "ImageTransparency", 0.9)
	Window:SetCornerProperty("TopLeft", "ZIndex", 10)

	game:GetService("RunService").Heartbeat:Connect(function()
		local Clock = os.clock() * 0.1

		Window:SetCornerProperty("TopRight", "ImageColor3", Color3.fromHSV(Clock % 1, 0.85, 0.3))
		Window:SetCornerProperty("TopLeft", "ImageColor3", Color3.fromHSV((Clock + 0.08) % 1, 0.85, 0.3))

		Window:SetCornerProperty("DownRight", "ImageColor3", Color3.fromHSV((Clock + 0.16) % 1, 0.85, 0.3))
		Window:SetCornerProperty("DownLeft", "ImageColor3", Color3.fromHSV((Clock + 0.24) % 1, 0.85, 0.3))
	end)
end)
