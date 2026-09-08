local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Overlay"))
local Signal = Library.Signal

Library.SetLibraryDebugs(true) --// Enables Signal:Debug, this is important if you have an issue and you want to see any warnings. [function Library.SetLibraryDebugs(Bool: boolean): ()]
Library.SetHidden(true) --// Hides the UI and makes it harder to read. [function Library.SetHidden(Bool: boolean): ()]

Signal:Debug("Library Loaded", "Loading Thread") --// [function Signal:Debug<a, b, c>(Input: b, Thread: c): ()]

local OnActionFired = Signal.New() --// Creates a new signal [Note: if you use Signal.New, the library will disconnect it when closing, use if you want to unbind any connection when the user destroys the ui]
local IsMobile = Library.IsMobile

if IsMobile then
	Signal:Debug("Mobile Device Detected", "Device Check Thread")

	Library:Notify({
		Title = "Device Detection",
		Content = "Library has been optimized for mobile devices.", --// If you don't want the content to show, set it to "" or nil or don't define it.
		--// [Alternative] Message = "Library has been optimized for mobile devices.",
		Icon = "rbxassetid://134070681746662", --// If you don't want the Icon to show, set it to "" or nil or don't define it.
		Background = "rbxassetid://82295031952284", --// If you don't want the Background to show, set it to "" or nil or don't define it.
		--// [Alt] BackgroundImage = = "rbxassetid://82295031952284",
		Duration = 100, --// [Seconds, how much the notification will be displayed for]
		CloseType = "Button", --// The method of closing the notification early [Button: will display an 'x' button, Body: Will close the notification when clicking the Notification]
		Buttons = {
			{
				Title = "Close",
				DestroyOnClick = true, --// Destroys the notification when clicked
				Callback = function() end, --// Ignored if DestroyOnClick is enabled
			},

			{
				Title = "Load Mobile UI",
				Callback = function()
					print("loaded mobile ui")
				end,
			},
		},
	})
end

OnActionFired:Connect(function(Argument1: string, Argument2: string)
	Library:Notify({
		Title = Argument1,
		Content = Argument2,
		Icon = "rbxassetid://134070681746662",
		CloseType = "Button",
		Background = "rbxassetid://82295031952284",
		Duration = 5,
	})
end)

--// Themes:
local CurrentThemes = Library:GetThemes() --// Default Themes: {"Dark", "Light", "Crimson", "Midnight", "Sunrise", "Glass", "Black Glass"}
Library:CreateTheme({
	Name = "Cyan Glass", --// Important: this will show when using Library:GetThemes() and you will need to use this name when using Library:SetTheme()
	BackgroundColor = Color3.fromRGB(0, 238, 255), --// BackgroundColor, Eg: Notification, DropdownContextMenu, Window
	BackgroundTransparency = 0.9, --// Transparency of the background, this includes: Notification, DropdownContextMenu, Window
	AccentColor = Color3.fromRGB(119, 239, 255), --// Accent color, Eg: Toggle, Button, Dropdown Background (use something light)
	TextColor = Color3.fromRGB(183, 238, 255), --// Text Color (Use Something light)
	IconColor = Color3.fromRGB(52, 208, 255), --// Icon Color (Use Something light)
})

Library:CreateTheme({
	Name = "Midnight Glass", --// Important: this will show when using Library:GetThemes() and you will need to use this name when using Library:SetTheme()
	BackgroundColor = Color3.fromRGB(101, 122, 255), --// BackgroundColor, Eg: Notification, DropdownContextMenu, Window
	BackgroundTransparency = 0.9, --// Transparency of the background, this includes: Notification, DropdownContextMenu, Window
	AccentColor = Color3.fromRGB(101, 122, 255), --// Accent color, Eg: Toggle, Button, Dropdown Background (use something light)
	TextColor = Color3.fromRGB(193, 201, 255), --// Text Color (Use Something light)
	IconColor = Color3.fromRGB(164, 176, 255), --// Icon Color (Use Something light)
})

local NewThemes = Library:GetThemes() --// Default Themes + The newly added theme: {"Dark", "Light", "Crimson", "Midnight", "Sunrise", "Glass", "Black Glass", "Blue Glass", "Midnight Glass"}
local Window, Body = Library:Window({
	Title = "Perseus Hub",
	SubTitle = "Made By Severitysvc", --// If you don't want the content to show, set it to "" or nil or don't define it.

	WindowSize = UDim2.fromOffset(700, 500), --// Recommended to use offsets, Default is 700x500
	UIScale = 1,

	Minimized = false,
	MinimizeKeybind = Enum.KeyCode.RightShift,

	Theme = "Dark", --// Note: Do not set Newly Created Themes here, use Library:SetTheme after window creation
	BackgroundImage = "", --// if you don't want the background image, set it to "" or nil or don't define it.

	Profile = {
		AnonymousScreenshot = false, --// Makes the screenshot anonymous
		UserAnonym = true, --// makes the user anonymous
		DisplayAnonym = true, --// makes the display anonymous
		Transparent = false, --// Makes the profile board transparent
	},

	ImageCorners = {
		TopLeft = {
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.8,
		},

		TopRight = {
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.8,
		},

		DownLeft = {
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.9,
		},

		DownRight = {
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.9,
		},
	},
})

local OnMinimize = Window.OnMinimize --// Will get fired when the window is minimized
local OnDestroy = Window.OnDestroy --// Will get fired when the window gets destroyed

if IsMobile then
	Window:SetUIScale(0.7) --// Recommended ui scale for mobile devices
end

--// Window Methods
Window:SetBackgroundImage("rbxassetid://82295031952284")
Window:SetBackgroundImageTransparency(0.9)

--// Topbar button
Window:NewTopbarButton({
	Icon = "rbxassetid://134070681746662",
	Order = 1, --// The bigger the order is, the closer it is to the right, go beyond 999 if you want it to display in front of the close and minimize buttons
	Callback = function()
		Library:Notify({
			Title = "Discord Invite Copied!",
			Background = "rbxassetid://82295031952284",
			CloseType = "Body",
			Duration = 5,
		})
	end,
})

--// Interaction Button (displayed on the sidebar)
Window:NewInteractionButton({
	Order = 1, --// The bigger the order is, the closer it is to the left
	Icon = "rbxassetid://111039484684928",
	Callback = function()
		Window:SetWindowTransparency(0.8)
	end,
})

--// Tabs
local Tabs = {}
local Tab = Window:Tab({
	Title = "Tab Example",
	Description = "This is an example of a tab", --// Will only show when 'Section' is defined
	Icon = "rbxassetid://91164200324199", --// If you don't want the Icon to show, set it to "" or nil or don't define it.
	Section = { --// If you don't want the Section to show, simply don't define it
		ShowIcon = true, --// Weather the tab icon shows on the section, will not show if icon is nil/undefined
	},
	Callback = function()
		Window:SetBackgroundImage("rbxassetid://133748586430296")
		Window:SetBackgroundImageTransparency(0.6)
	end,
})

Window:Divider({ --// Creates a line
	Size = 0.8,
	Transparency = 0.9,
})

local Section = Window:Section({
	Title = "Section Example",
	Icon = "rbxassetid://91164200324199",
	Opened = true,
})

local Overview = Section:Tab({
	Title = "Overview",
	Description = "Overview your stats",
	Icon = "rbxassetid://92502305278637",
	Section = {
		ShowIcon = false,
	},
})

Overview.OnSelect:Connect(function() --// Fires when tab is selected
	Window:SetBackgroundImage("rbxassetid://133748586430296")
	Window:SetBackgroundImageTransparency(0.6)
	Body.BackgroundImage.ImageColor3 = Color3.fromRGB(40, 40, 40)

	Window:SetCornerProperty("DownLeft", "ImageColor3", Color3.fromRGB(0, 110, 255))
	Window:SetCornerProperty("DownLeft", "Visible", true)
	Window:SetCornerProperty("DownLeft", "ImageTransparency", 0.9)

	Window:SetCornerProperty("DownRight", "ImageColor3", Color3.fromRGB(162, 0, 255))
	Window:SetCornerProperty("DownRight", "Visible", true)
	Window:SetCornerProperty("DownRight", "ImageTransparency", 0.9)
end)

Overview.OnDeselect:Connect(function() --// Fires when tab is selected
	Window:SetBackgroundImage("rbxassetid://82295031952284")
	Window:SetBackgroundImageTransparency(0.9)
	Body.BackgroundImage.ImageColor3 = Color3.fromRGB(255, 255, 255)

	Window:SetCornerProperty("DownLeft", "ImageColor3", Color3.fromRGB(0, 110, 255))
	Window:SetCornerProperty("DownLeft", "ImageTransparency", 1)

	Window:SetCornerProperty("DownRight", "ImageColor3", Color3.fromRGB(162, 0, 255))
	Window:SetCornerProperty("DownRight", "ImageTransparency", 1)
end)

local Profile = Overview:ProfileBanner() --// Creates a profile banner
local DestroyCopy = Profile:Button({
	Icon = "rbxassetid://10747384394",
	Order = 2,
	Callback = function()
		Window:Destroy()
	end,
})

DestroyCopy.BackgroundColor3 = Color3.fromRGB(253, 115, 115)

local MinimizeCopy = Profile:Button({
	Icon = "rbxassetid://10734896206",
	Callback = function()
		Window:MinimizeWindow()
	end,
})

Tabs["Dashboard"] = Tab
Tabs["Overview"] = Overview

--[[
	GLOBAL ELEMENT PROPRIETIES: [Proprieties that all elements have]
	
	[Title, Name]: Title of the element
	[Description, Desc]: Descrption of the element [Optional]
	[Transparency]: Transparency of the element [Min, Mid, Max are possible, Min is default]
	[Icon, Image]: Icon of the element [Optional]
	[StrokeEnabled, Stroke]: Enables the element stroke [Default is false]
	[Value, Default]: Value of the object, Depends on the element
]]

Tab:Select() --// Selects the tab, use Tab:Deselect() to deselect the tab

local SelectedTheme = "Dark"
Tab:Dropdown({
	Title = "Old Themes",
	Description = "This Dropdown displays the old themes",
	Icon = "", --// If you don't want the Icon to show, set it to "" or nil or don't define it.
	DropdownIcon = true, --// Weather to show the chevron up and down icon or not.
	Values = CurrentThemes, --// always requires a table
	Value = "Dark", --// When using Multi, Wrap the value inside a {}
	CloseOnSelection = true, --// Closes the DropdownContextMenu when selecting a value [not recommended when using multi]
	Multi = false, --// Allows multiple values, will return a table on callback
	Callback = function(Value: StringValue)
		SelectedTheme = Value
	end,
})

Tab:Dropdown({
	Title = "New Themes",
	Description = "This Dropdown displays the new themes",
	DropdownIcon = true,
	Values = NewThemes,
	Value = "Dark",
	Multi = false,
	Callback = function(Value: StringValue)
		SelectedTheme = Value
	end,
})

Tab:Button({
	Title = "Apply Selected Theme",
	Description = "This button applies the selected theme",
	HeadingButton = "Icon", --// What shows at the end of the button. [Icon: shows a mouse icon, by default, changeable using HeadingIcon; Watermark: Displays a text, Changeable by using HeadingText]
	HeadingText = "Button", --// The text at the end
	StrokeEnabled = false, --// Weather the stroke is enabled or not
	Transparency = "Mid", --// The Transparency phase of the background {Min = 0.95, Mid = 0.985, Max - 1}
	Callback = function()
		Window:UnloadAnimation()
		Library:SetTheme(SelectedTheme)
	end,
})

local Player = Overview:Section({
	Title = "Player Behaviour",
	Desc = "Change player behaviour",
	Icon = "rbxassetid://92794817430734", --// Optional
	Opened = true,
	ElementPadding = 0,
	ElementCornerSize = 0,
	Class = "Watermark", --// Possible Classes: Normal: displays a chevron; Toggle: displays a working toggle, can use callback and value.
	Watermark = "Change Settings",
})

Player:BodyLabel({
	Title = "Player Behaviour",
	Description = "Configure player behaviour",
})

Player:Slider({
	Title = "Walkspeed Changer",
	Description = "This slider changes walkspeed",
	Icon = "rbxassetid://92794817430734",
	Min = 0, --// Minimum Value
	Max = 100, --// Maximum Value
	Step = 1, --// Step
	Value = 16, --// Default value
	SmoothSlider = true, --// Makes the sliding smooth
	Callback = function(Value)
		Library.InitializedPlayer.Character.Humanoid.WalkSpeed = Value
	end,
})

Player:Slider({
	Title = "Jumppower Changer",
	Description = "This slider changes jumppower",
	Icon = "",
	Min = 0, --// Minimum Value
	Max = 500, --// Maximum Value
	Step = 1, --// Step
	Value = 50, --// Default value
	SmoothSlider = true, --// Makes the sliding smooth
	Callback = function(Value)
		Library.InitializedPlayer.Character.Humanoid.JumpPower = Value
	end,
})

Player:Divider({
	Size = 0.9,
	Transparency = 0.9,
}) --// This can intrerupt corner sizing

Player:BodyLabel({
	Title = "Player Options",
	Icon = "rbxassetid://85552473323403",
	Description = "Configure additional player behaviour.",
})

Player:Toggle({
	Title = "Enable Player Changes",
	Description = "Toggle the player behaviour settings.",
	Value = true,
	Callback = function(Value)
		print("Player changes enabled:", Value)
	end,
})

Player:Dropdown({
	Title = "Movement Style",
	Description = "Select a movement style.",
	Values = { "Default", "Fast", "Slow" },
	Value = "Default",
	Callback = function(Value)
		print("Movement style:", Value)
	end,
})

PlayerSettings:Keybind({
	Title = "Player Action",
	Description = "Nested keybind example.",
	Value = Enum.KeyCode.P,
	Callback = function() end,
	OnKeyPressed = function()
		ActionSignal:Fire("Player Action", "The nested keybind callback fired.")
	end,
})


--[[Window:LoadAnimation("Parallax", {
	--// Lighthouse Config
	LightHouseAngle = 10, --// Max angle of the lighthouse tilt, [Default: 5]
	LightHouseSpeed = 1, --// Base speed, [Default: 1]
	LightHouseBobAmplitude = 0.01, --// Vertical bob,  [Default: 0.008]
	LightHouseBobMultipliers = { 1, 1 }, --// lighthouse bob strength multiplier, [Default: { 1, 1 }] [Note: 1: FirstLighthouse, 1: Second Lighthouse]
	LightHouseTiltMultipliers = { 0.8, 0.8 }, --// lighthouse tilt strength multiplier,. [Default: { 1, 1 }]
	LightHouseXPositions = { 0.15, 0.75 }, --// X position for each lighthouse, [Default: { 0.15, 0.75 }] [Use Scale]
	LightHouseYPosition = 0.9, --// Y position for all lighthouses, [Default: 0.9] [Use Scale]

	--// Wave Config
	WaveAmplitude = 0.05, --// Base amount of the growth, [Default: 0.04]
	WaveAmplitudeStep = 1, --// Extra amplitude for each layer (3 in total), [Default: 0.1]
	WaveBaseSpeed = 2, --// Base wave speed,[Default: 0.9]
	WaveSpeedStep = 0.5, --// Speed added to each wave, [Default: 0.4]
	WaveHeight = 0.235, --// Starting height of each wave, [Default: 0.2] [Use scale]
})]]

local Undec = Overview:Section({
	Title = "Player Behaviour",
	Desc = "Change player behaviour",
	Icon = "rbxassetid://92794817430734", --// Optional
	Opened = true,
	Class = "Normal", --// Possible Classes: Normal: displays a chevron; Toggle: displays a working toggle, can use callback and value.
})

local Paragraph = Undec:Paragraph({
	Title = "Paragraph Example",
	Description = "This is a paragraph example",
	Icon = "rbxassetid://70746246601910",
	StrokeEnabled = true,
})

Paragraph:SetBackgroundColor(Color3.fromRGB(255, 0, 0))
Paragraph:FillIcon()
