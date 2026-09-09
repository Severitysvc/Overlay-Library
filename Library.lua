--[[
	// Overlay Library 
	// Made By: Severitysvc
	// Version: 1.0.5
	// State: Beta
]]

--// Modules
local Library = {}
Library.Instances = {}
Library.Connections = {}
Library.Signals = {}

local Signal = {}
Signal.__index = Signal

local ThemeManager = {}
ThemeManager.__index = ThemeManager

--// Services
local CloneReference = cloneref or clonereference or function(Object)
	return Object
end

local TweenService = CloneReference(game:GetService("TweenService")) :: TweenService
local RunService = CloneReference(game:GetService("RunService")) :: RunService
local Players = CloneReference(game:GetService("Players")) :: Players
local UserInputService = CloneReference(game:GetService("UserInputService")) :: UserInputService

local LocalPlayer = CloneReference(Players.LocalPlayer) :: Player

Library.IsStudio = RunService:IsStudio() :: boolean
Library.IsMobile = UserInputService.TouchEnabled and true or false :: boolean

local Hui = (Library.IsStudio and game:GetService("Players").LocalPlayer.PlayerGui)
	or (gethui and gethui())
	or CloneReference(game:GetService("CoreGui")) :: CoreGui
local Protect = Library.IsStudio and (protectgui or syn and syn.protectgui) or function() end
local Global = Library.IsStudio and shared or getgenv()

Library.CloneReference = CloneReference
Library.Player = LocalPlayer
Library.Hui = Hui

Library.Signal = Signal
Library.Global = Global

if Global.OverlayInjected then
	Global.OverlayDestroy:Fire()
end

--// Icons
local API = not Library.IsStudio
		and loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))() --// Creds: https://github.com/Footagesus/Icons
	or {
		SetIconsType = function(Object)
			return Object
		end,

		GetIcon = function()
			return ""
		end,
	}

function Library.GetIcon(Icon)
	if Icon and type(Icon) == "string" and (string.find(Icon, "rbxassetid") or string.find(Icon, "rbxthumb")) then
		return Icon
	end

	local Icon = API.GetIcon and API.GetIcon(tostring(Icon):lower()) or ""

	if not Icon then
		return ""
	end

	return Icon
end

function Library.SetIcon(Icon, Label)
	local IconData = Library.GetIcon(Icon)

	if IconData then
		Label.Image = IconData
	end

	return nil
end

function Library.Get(Data, Keys, Default)
	if Data == nil then
		return Default
	end

	for _, Key in ipairs(Keys) do
		if Data[Key] ~= nil then
			return Data[Key]
		end

		if type(Key) == "string" then
			local LowerKey = string.lower(Key)

			for DataKey, Value in pairs(Data) do
				if type(DataKey) == "string" and string.lower(DataKey) == LowerKey then
					return Value
				end
			end
		end
	end

	return Default
end

function Library:SetIconPack(Pack)
	API.SetIconsType(Pack or "Lucide")
end

--// Signal
function Signal.New()
	local self = setmetatable({}, Signal)
	self.Connections = {}
	table.insert(Library.Signals, self)

	return self
end

function Signal:Connect(Func)
	local Connection = { Func = Func, Connected = true }

	function Connection.Disconnect(self)
		self.Connected = false

		for Index, Conn in ipairs(Connection.Owner.Connections) do
			if Conn == Connection then
				table.remove(Connection.Owner.Connections, Index)
				break
			end
		end
	end

	Connection.Owner = self
	table.insert(self.Connections, Connection)
	return Connection
end

function Signal:Once(Func)
	local Connection = self:Connect(Func)
	Connection.Once = true

	return Connection
end

function Signal:Fire(...)
	local Connections = table.clone(self.Connections)

	for _, Connection in ipairs(Connections) do
		if Connection.Connected then
			if Connection.Once then
				Connection:Disconnect()
			end

			task.spawn(Connection.Func, ...)
		end
	end
end

function Signal:DisconnectAll()
	for _, Connection in ipairs(self.Connections) do
		Connection.Connected = false
	end

	self.Connections = {}
end

function Signal:Assert(Condition, Text, Thread)
	if Condition then
		return true
	end

	if Library.LibraryDebugs then
		local Source, Line, Function = nil, nil, nil

		if debug and type(debug.info) == "function" then
			local Success, CSource, CLine, CName = pcall(debug.info, 2, "sln")

			if Success then
				Source = CSource or "unknown"
				Line = CLine or "?"
				Function = CName or "anonymous"
			end
		end
		error(
			("[Overlay Error] %s\n  Context: %s\n  Function: %s\n  Location: %s:%s"):format(
				tostring(Text or "No error set."),
				tostring(Thread or "Thread"),
				Function,
				Source,
				Line
			),
			2
		)
	end
end

function Signal:MatchInput(Input, ...)
	local Inputs = { ... }

	for _, _Input in ipairs(Inputs) do
		if Input.KeyCode == _Input or Input.UserInputType == _Input then
			return true
		end
	end

	return false
end

function Signal:Animate(Object, Info, Propriety)
	Signal:Assert(Object and typeof(Object) == "Instance", "Object is nil and/or is not an instance", "Track")

	local TweenInfo = TweenInfo.new(
		Info.Time,
		Info.Style,
		Info.Direction,
		Info.RepeatCount or 0,
		Info.Reverses or false,
		Info.DelayTime or 0
	)

	local Animation = TweenService:Create(Object, TweenInfo, Propriety)
	Animation:Play()

	return Animation, {
		Stop = function()
			Animation:Cancel()
		end,
	}
end

function Signal:Track(Object, Optional)
	Signal:Assert(Object and typeof(Object) == "Instance", "Object is nil and/or is not an instance", "Track")

	local TextObject = Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")
	local ImageObject = Object:IsA("ImageLabel") or Object:IsA("ImageButton")

	Signal:Assert(TextObject or ImageObject, "Object is not a TextLabel or ImageLabel", "Track")

	local Content = TextObject and Object.Text or Object.Image
	Object.Visible = Content ~= nil and Content ~= ""

	if Optional then
		Optional.Visible = Content ~= nil and Content ~= ""
	end

	if TextObject then
		Object:GetPropertyChangedSignal("Text"):Connect(function()
			local Content = TextObject and Object.Text
			Object.Visible = Content ~= nil and Content ~= ""

			if Optional then
				Optional.Visible = Content ~= nil and Content ~= ""
			end
		end)
	else
		Object:GetPropertyChangedSignal("Image"):Connect(function()
			local Content = ImageObject and Object.Image
			Object.Visible = Content ~= nil and Content ~= ""

			if Optional then
				Optional.Visible = Content ~= nil and Content ~= ""
			end
		end)
	end
end

function Signal:Callback(Func)
	if Func == nil then
		Func = function() end
	end

	Signal:Assert(Func and type(Func) == "function", "Argument is nil and/or is not a function", "Callback")
	local Callback = Signal.New()

	Callback:Connect(function(Arg)
		return Func(Arg)
	end)

	return Callback
end

function Library.TrackConnection(Connection)
	table.insert(Library.Connections, Connection)
	return Connection
end

function Library.DisconnectConnection(Connection)
	if Connection and Connection.Connected then
		Connection:Disconnect()
	end

	local Index = table.find(Library.Connections, Connection)
	if Index then
		table.remove(Library.Connections, Index)
	end
end

function Library.DisconnectAllConnections()
	for Index = #Library.Connections, 1, -1 do
		Library.DisconnectConnection(Library.Connections[Index])
	end
end

function Library.DisconnectAllSignals()
	for _, SignalObject in ipairs(Library.Signals) do
		SignalObject:DisconnectAll()
	end

	Library.Signals = {}
end

--// Themes
ThemeManager.CurrentTheme = nil
ThemeManager.ThemeChanged = Signal.New()
local InstanceAdded = Signal.New()

function ThemeManager.New(Data)
	Signal:Assert(Data and type(Data) == "table", "Argument is nil and/or is not a table", "ThemeManager:SetTheme")

	local Theme = setmetatable({
		Name = Data.Name or "Theme",
		BackgroundColor = Data.BackgroundColor or Color3.fromRGB(9, 9, 9),
		BackgroundTransparency = Library.Get(Data, { "BackgroundTransparency" }, 0.1),
		AccentColor = Data.AccentColor or Color3.fromRGB(255, 255, 255),
		TextColor = Data.TextColor or Color3.fromRGB(255, 255, 255),
		IconColor = Data.IconColor or Color3.fromRGB(255, 255, 255),
	}, ThemeManager)

	return Theme
end

function ThemeManager:SetTheme(Theme)
	Signal:Assert(Theme and type(Theme) == "table", "Argument is nil and/or is not a table", "ThemeManager:SetTheme")
	ThemeManager.CurrentTheme = Theme
	ThemeManager.ThemeChanged:Fire(Theme.Name)

	for _, Instance in ipairs(Library.Instances) do
		local Role = Instance:GetAttribute("Role")

		if Instance:GetAttribute("Ignore") then
			continue
		end

		if Role then
			if Role == "Background" and Instance.BackgroundColor3 ~= nil and Instance.BackgroundTransparency ~= nil then
				Signal:Animate(
					Instance,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ BackgroundColor3 = Theme.BackgroundColor, BackgroundTransparency = Theme.BackgroundTransparency }
				)
			elseif Role == "Accent" then
				if Instance:IsA("UIStroke") then
					Signal:Animate(
						Instance,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Color = Theme.AccentColor }
					)
					continue
				end

				if Instance.BackgroundColor3 ~= nil then
					Signal:Animate(
						Instance,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ BackgroundColor3 = Theme.AccentColor }
					)
				end
			elseif Role == "Text" and Instance.TextColor3 ~= nil then
				Signal:Animate(
					Instance,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ TextColor3 = Theme.TextColor }
				)
			elseif Role == "Icon" and Instance.ImageColor3 ~= nil then
				Signal:Animate(
					Instance,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ ImageColor3 = Theme.IconColor }
				)
			end
		end
	end
end

function ThemeManager:GetTheme()
	return ThemeManager.CurrentTheme
end

ThemeManager.Themes = {
	["Dark"] = ThemeManager.New({
		Name = "Dark",
		BackgroundColor = Color3.fromRGB(9, 9, 9),
		BackgroundTransparency = 0.1,
		AccentColor = Color3.fromRGB(255, 255, 255),
		TextColor = Color3.fromRGB(255, 255, 255),
		IconColor = Color3.fromRGB(255, 255, 255),
	}),

	["Light"] = ThemeManager.New({
		Name = "Light",
		BackgroundColor = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.1,
		AccentColor = Color3.fromRGB(0, 0, 0),
		TextColor = Color3.fromRGB(0, 0, 0),
		IconColor = Color3.fromRGB(0, 0, 0),
	}),

	["Midnight"] = ThemeManager.New({
		Name = "Midnight",
		BackgroundColor = Color3.fromRGB(24, 30, 66),
		BackgroundTransparency = 0.1,
		AccentColor = Color3.fromRGB(119, 135, 255),
		TextColor = Color3.fromRGB(183, 197, 255),
		IconColor = Color3.fromRGB(98, 125, 255),
	}),

	["Crimson"] = ThemeManager.New({
		Name = "Crimson",
		BackgroundColor = Color3.fromRGB(24, 9, 9),
		BackgroundTransparency = 0.1,
		AccentColor = Color3.fromRGB(255, 119, 119),
		TextColor = Color3.fromRGB(255, 183, 183),
		IconColor = Color3.fromRGB(255, 52, 52),
	}),

	["Sunrise"] = ThemeManager.New({
		Name = "Sunrise",
		BackgroundColor = Color3.fromRGB(66, 41, 24),
		BackgroundTransparency = 0.1,
		AccentColor = Color3.fromRGB(255, 180, 119),
		TextColor = Color3.fromRGB(255, 218, 183),
		IconColor = Color3.fromRGB(255, 205, 98),
	}),

	["Glass"] = ThemeManager.New({
		Name = "Glass",
		BackgroundColor = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		AccentColor = Color3.fromRGB(255, 255, 255),
		TextColor = Color3.fromRGB(255, 255, 255),
		IconColor = Color3.fromRGB(255, 255, 255),
	}),

	["Black Glass"] = ThemeManager.New({
		Name = "Black Glass",
		BackgroundColor = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.9,
		AccentColor = Color3.fromRGB(0, 0, 0),
		TextColor = Color3.fromRGB(255, 255, 255),
		IconColor = Color3.fromRGB(255, 255, 255),
	}),
}

ThemeManager.CurrentTheme = ThemeManager.Themes.Dark

--// Library
function Library:SetLibraryDebugs(Bool)
	Library.LibraryDebugs = Bool
end

function Library:SetHidden(Bool)
	Library.Hidden = Bool
end

function Library:SetGlobal(Name, Value)
	Signal:Assert(Global, "Global is nil", "SetGlobal")
	Global[Name] = Value
end

function Library.New(Class, Properties)
	local Success, Object = pcall(Instance.new, Class)

	if not Success then
		return nil
	end

	if Properties then
		local Role = Properties.Role
		Properties.Role = nil

		for Property, Value in pairs(Properties) do
			local Success = pcall(function()
				Object[Property] = Value
			end)

			if not Success and (Property ~= "Ignore" and Property ~= "Role" and Property ~= "Icon") then
				warn("Failed to set property: " .. tostring(Property))
			end
		end

		if Role then
			Object:SetAttribute("Role", Role)
		else
			if not Properties.Ignore then
				if Class == "TextLabel" then
					Object:SetAttribute("Role", "Text")
				elseif Class == "ImageLabel" or Class == "ImageButton" then
					Object:SetAttribute("Role", "Icon")
				end
			end
		end
	end

	if Class == "TextButton" then
		Object.Text = ""
		Object.AutoButtonColor = false
	elseif Class == "ImageButton" then
		Object.AutoButtonColor = false
		Library.SetIcon(Properties.Icon or "", Object)
	elseif Class == "ImageLabel" then
		Library.SetIcon(Properties.Icon or "", Object)
	end

	table.insert(Library.Instances, Object)
	InstanceAdded:Fire(Object)

	return Object
end

function Library.DestroyAll()
	for _, Object in ipairs(Library.Instances) do
		Object:Destroy()
	end

	Library.Instances = {}
end

function Library.SetupBody(Data)
	Data = Data or {}
	local Body = {}

	local HoverStart = Signal.New()
	local HoverEnd = Signal.New()

	local ElementBody = Library.New("TextButton", {
		Name = "ElementBody",
		Position = UDim2.new(0, 0, 0.057, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Role = "Accent",
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Parent = Library.Get(Data, { "Parent", "Ascendant" }, nil),
	}) :: TextButton

	local TransparencyPhase = Library.Get(Data, { "Transparency", "TransparencyPhase" }, "Min")

	if TransparencyPhase == "Min" then
		ElementBody.BackgroundTransparency = 0.95
	elseif TransparencyPhase == "Mid" then
		ElementBody.BackgroundTransparency = 0.985
	elseif TransparencyPhase == "Max" then
		ElementBody.BackgroundTransparency = 1
	end

	Library.New("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = ElementBody,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = ElementBody })

	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = ElementBody,
	})

	Library.New("UIStroke", {
		Transparency = Library.Get(Data, { "Stroke", "StrokeEnabled" }, false)
				and (ElementBody.BackgroundTransparency - 0.05)
			or 1,
		Role = "Accent",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = ElementBody,
	})

	local Header = Library.New("Frame", {
		Name = "Header",
		Size = UDim2.new(0.8, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = ElementBody,
	}) :: Frame

	Library.New("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Header,
	})

	local Icon = Library.New("Frame", {
		Name = "Icon",
		LayoutOrder = -1,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 40),
		AnchorPoint = Vector2.new(0, 0.5),
		Role = "Accent",
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		Parent = Header,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Medium), Parent = Icon })

	local IconDisplay = Library.New("ImageLabel", {
		Name = "IconDisplay",
		LayoutOrder = -1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.6, 0, 0.6, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Icon = Library.Get(Data, { "Icon", "Image", "ImageDisplay", "IconDisplay" }, ""),
		Role = "Icon",
		ImageTransparency = 0.2,
		Parent = Icon,
	})

	Signal:Track(IconDisplay, Icon)

	local Display = Library.New("Frame", {
		Name = "Display",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Header,
	})

	local Title = Library.New("TextLabel", {
		Name = "Title",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = Library.Get(Data, { "Title" }, "Title"),
		Role = "Text",
		TextSize = 18,
		TextTransparency = 0.2,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
		Parent = Display,
	})

	local Description = Library.New("TextLabel", {
		Name = "Description",
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = Library.Get(Data, { "Desc", "Description", "About" }, ""),
		Role = "Text",
		TextSize = 14,
		TextTransparency = 0.4,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new("rbxassetid://16658221428"),
		Parent = Display,
	})

	Signal:Track(Description)

	Library.New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Display,
	})

	local Interaction = Library.New("Frame", {
		Name = "Interaction",
		Size = UDim2.new(0.2, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = ElementBody,
	})

	Library.New("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Interaction,
	})

	Library.New("UIPadding", {
		PaddingRight = UDim.new(0, 10),
		Parent = Interaction,
	})

	Body.Interaction = Interaction
	Body.Header = Header
	Body.ElementBody = ElementBody

	Body.Icon = Icon
	Body.Title = Title
	Body.Description = Description

	local OldTransparency = ElementBody.BackgroundTransparency

	HoverStart:Connect(function()
		Signal:Animate(
			ElementBody,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = OldTransparency - 0.025 }
		)
	end)

	HoverEnd:Connect(function()
		Signal:Animate(
			ElementBody,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = OldTransparency }
		)
	end)

	ElementBody.MouseEnter:Connect(function()
		HoverStart:Fire()
	end)

	ElementBody.MouseLeave:Connect(function()
		HoverEnd:Fire()
	end)

	function Body:SetDescription(Text)
		Signal:Assert(
			Text and type(Text) == "string",
			"Argument is not present and/or is not a string value",
			"Set Description"
		)

		Description.Text = Text
	end

	function Body:SetTitle(Text)
		Signal:Assert(
			Text and type(Text) == "string",
			"Argument is not present and/or is not a string value",
			"Set Description"
		)

		Title.Text = Text
	end

	return Body
end

function Library.NewSizeConstraint(Object, MaxX, MaxY, MinX, MinY)
	Signal:Assert(Object, "No object input", "New Size Constraint")

	local SizeConstraint = Library.New("UISizeConstraint", {
		Parent = Object,
		MaxSize = Vector2.new(MaxX ~= nil and MaxX or math.huge, MaxY ~= nil and MaxY or math.huge),
		MinSize = Vector2.new(MinX ~= nil and MinX or 0, MinY ~= nil and MinY or 0),
	})

	return SizeConstraint
end

function Library.SetDraggable(Object, Handle)
	Signal:Assert(Object, "No object input", "SetDraggable")

	Handle = Handle or Object

	local DragStart = Signal.New()
	local DragChanged = Signal.New()
	local DragEnd = Signal.New()

	local Dragging = false
	local DragInputType = nil
	local StartPosition = nil
	local StartInputPosition = nil
	local TargetPosition = Object.Position
	local Connection = nil

	local SmoothSpeed = 20

	local function Update(InputPosition)
		local Delta = InputPosition - StartInputPosition

		TargetPosition = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)

		DragChanged:Fire(TargetPosition)
	end

	local function StopDragging()
		if not Dragging then
			return
		end

		Dragging = false
		DragInputType = nil

		if Connection then
			Library.DisconnectConnection(Connection)
			Connection = nil
		end

		DragEnd:Fire(Object)
	end

	Handle.InputBegan:Connect(function(Input)
		if
			Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		Dragging = true
		DragInputType = Input.UserInputType
		StartPosition = Object.Position
		StartInputPosition = Input.Position
		TargetPosition = Object.Position

		DragStart:Fire(Object)

		if Connection then
			Library.DisconnectConnection(Connection)
		end

		Connection = Library.TrackConnection(RunService.Heartbeat:Connect(function(DeltaTime)
			local Alpha = 1 - math.exp(-SmoothSpeed * DeltaTime)
			Object.Position = Object.Position:Lerp(TargetPosition, Alpha)
		end))
	end)

	Library.TrackConnection(UserInputService.InputChanged:Connect(function(Input)
		if
			Dragging
			and DragInputType
			and (
				Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch
			)
		then
			Update(Input.Position)
		end
	end))

	Library.TrackConnection(UserInputService.InputEnded:Connect(function(Input)
		if Dragging and Input.UserInputType == DragInputType then
			StopDragging()
		end
	end))

	return {
		DragStart = DragStart,
		DragChanged = DragChanged,
		DragEnd = DragEnd,
		IsDragging = function()
			return Dragging
		end,
	}
end

--// Theme References
function Library:GetTheme()
	return ThemeManager.CurrentTheme.Name
end

function Library:GetThemes()
	local Themes = {}

	for _, Theme in pairs(ThemeManager.Themes) do
		table.insert(Themes, Theme.Name)
	end

	return Themes
end

function Library:SetTheme(Theme)
	local SelectedTheme = ThemeManager.Themes[Theme]
	--//Signal:Assert(SelectedTheme, "Theme: " .. Theme .. " Does not exist", "Library:SetTheme")

	if SelectedTheme then
		ThemeManager.CurrentTheme = SelectedTheme
		ThemeManager:SetTheme(SelectedTheme)
	end
end

function Library:CreateTheme(Data)
	Data = Data or {}
	local Theme = ThemeManager.New({
		Name = Data.Name or Data.ThemeName or "Unnamed Theme",
		BackgroundColor = Data.BackgroundColor or Color3.fromRGB(9, 9, 9),
		BackgroundTransparency = Library.Get(Data, { "BackgroundTransparency" }, 0.1),
		AccentColor = Data.AccentColor or Color3.fromRGB(255, 255, 255),
		TextColor = Data.TextColor or Color3.fromRGB(255, 255, 255),
		IconColor = Data.IconColor or Color3.fromRGB(255, 255, 255),
	})

	ThemeManager.Themes[Theme.Name] = Theme
	return Theme
end

--// Background Animations
function Library.SetupAnimation(Animation, Window, Data)
	Data = Data or {}
	Signal:Assert(
		Animation and type(Animation) == "string",
		"Animation is nil and/or is not a string",
		"Library.SetupAnimation"
	)

	--[[
		// Creditx:
		//	Parallax:= https://matthew.wagerfield.com/parallax/
		//	Parallax Github Orientation: https://github.com/wagerfield/parallax
	]]

	if Animation == "Parallax" then
		local Config = {
			LightHouse = {
				Angle = Library.Get(Data, { "LightHouseAngle" }, 5),
				Speed = Library.Get(Data, { "LightHouseSpeed" }, 1),
				BobAmplitude = Library.Get(Data, { "LightHouseBobAmplitude" }, 0.008),
				BobMultipliers = Library.Get(Data, { "LightHouseBobMultipliers" }, { 1, 1 }),
				TiltMultipliers = Library.Get(Data, { "LightHouseTiltMultipliers" }, { 1, 1 }),
				PhaseStep = math.pi,
				TiltPhaseOffset = (math.pi / 4),
				X = Library.Get(Data, { "LightHouseXPositions" }, { 0.15, 0.75 }),
				Y = Library.Get(Data, { "LightHouseYPosition" }, 0.9),
			},

			Wave = {
				Amplitude = Library.Get(Data, { "WaveAmplitude" }, 0.04),
				AmplitudeStep = Library.Get(Data, { "WaveAmplitudeStep" }, 0.1),
				BaseSpeed = Library.Get(Data, { "WaveBaseSpeed" }, 0.9),
				SpeedStep = Library.Get(Data, { "WaveSpeedStep" }, 0.4),
				PhaseStep = ((2 * math.pi) / 3),
				Height = Library.Get(Data, { "WaveHeight" }, 0.2),
			},
		}

		local Background = Library.New("ImageLabel", {
			Name = "Background",
			Visible = true,
			ZIndex = -1,
			Position = UDim2.new(0.000, 0, 0.000, 0),
			Size = UDim2.new(1.000, 0, 1.000, 0),
			AnchorPoint = Vector2.new(0.000, 0.000),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0,
			ClipsDescendants = false,
			Transparency = 0,
			Icon = "rbxassetid://88713227769730",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			Ignore = true,
			ImageTransparency = 0,
			Parent = Window,
		})

		Library.New("UICorner", {
			Name = "UICorner",
			CornerRadius = UDim.new(0.000, 15),
			Parent = Background,
		})

		local Wave = Library.New("ImageLabel", {
			Name = "Wave",
			Visible = true,
			ZIndex = 1,
			Position = UDim2.new(0.000, 0, 1.000, 0),
			Size = UDim2.new(1.000, 0, Config.Wave.Height, 0),
			AnchorPoint = Vector2.new(0.000, 1.000),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			Transparency = 1,
			Icon = "rbxassetid://75039717310710",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 0,
			ScaleType = Enum.ScaleType.Tile,
			SliceScale = 1,
			TileSize = UDim2.new(0.500, 0, 1.000, 0),
			Ignore = true,
			Parent = Window,
		})

		Library.New("UICorner", {
			Name = "UICorner",
			CornerRadius = UDim.new(0.000, 15),
			Parent = Wave,
		})

		local LightHouse = Library.New("ImageLabel", {
			Name = "LightHouse",
			Visible = true,
			ZIndex = -1,
			LayoutOrder = 0,
			Position = UDim2.new(Config.LightHouse.X[1], 0, Config.LightHouse.Y, 0),
			Size = UDim2.new(0.000, 120, 0.000, 185),
			AnchorPoint = Vector2.new(0.000, 1.000),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			Transparency = 1,
			Icon = "rbxassetid://90519913198907",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 0,
			Ignore = true,
			Parent = Window,
		})

		local SecondWave = Wave:Clone()
		local ThirdWave = Wave:Clone()

		SecondWave.ZIndex = 0
		ThirdWave.ZIndex = -1

		SecondWave.Parent = Window
		ThirdWave.Parent = Window

		local SecondLightHouse = LightHouse:Clone()
		SecondLightHouse.Position = UDim2.new(Config.LightHouse.X[2], 0, Config.LightHouse.Y, 0)
		SecondLightHouse.Parent = Window

		local WaveList = { Wave, SecondWave, ThirdWave }
		local LightHouseList = { LightHouse, SecondLightHouse }

		for Index, Instance in ipairs(WaveList) do
			local Speed = Config.Wave.BaseSpeed + (Index - 1) * Config.Wave.SpeedStep
			local Amplitude = (
				Config.Wave.Amplitude + (Index - 1) * (Config.Wave.Amplitude * Config.Wave.AmplitudeStep)
			) * 0.5

			local TileStretch = 0.35 + (Index * 0.1)
			Instance.TileSize = UDim2.new(TileStretch, 0, 1, 0)

			local Duration = math.pi / Speed
			local BaseSize = Instance.Size

			Instance.Size =
				UDim2.new(BaseSize.X.Scale, BaseSize.X.Offset, BaseSize.Y.Scale - Amplitude, BaseSize.Y.Offset)
			local Phase = (Index - 1) * Config.Wave.PhaseStep
			local StartDelay = Phase / Speed

			task.delay(StartDelay, function()
				Signal:Animate(Instance, {
					Time = Duration,
					Style = Enum.EasingStyle.Sine,
					Direction = Enum.EasingDirection.InOut,
					RepeatCount = -1,
					Reverses = true,
					DelayTime = 0,
				}, {
					Size = UDim2.new(
						BaseSize.X.Scale,
						BaseSize.X.Offset,
						BaseSize.Y.Scale + Amplitude,
						BaseSize.Y.Offset
					),
				})
			end)
		end

		for Index, Instance in ipairs(LightHouseList) do
			local BobMultiplier = Config.LightHouse.BobMultipliers[Index]
				or Config.LightHouse.BobMultipliers[#Config.LightHouse.BobMultipliers]

			local TiltMultiplier = Config.LightHouse.TiltMultipliers[Index]
				or Config.LightHouse.TiltMultipliers[#Config.LightHouse.TiltMultipliers]

			local BobSpeed = Config.LightHouse.Speed * BobMultiplier :: number
			local BobAmplitude = Config.LightHouse.BobAmplitude * BobMultiplier :: number
			local BobDuration = math.pi / BobSpeed

			local TiltSpeed = Config.LightHouse.Speed * TiltMultiplier :: number
			local TiltAmplitude = Config.LightHouse.Angle * TiltMultiplier :: number
			local TiltDuration = math.pi / TiltSpeed

			local BasePosition = Instance.Position

			Instance.Position = UDim2.new(
				BasePosition.X.Scale,
				BasePosition.X.Offset,
				BasePosition.Y.Scale - BobAmplitude,
				BasePosition.Y.Offset
			)

			Instance.Rotation = -TiltAmplitude

			local BobPhase = (Index - 1) * Config.LightHouse.PhaseStep
			local TiltPhase = (Index - 1) * Config.LightHouse.PhaseStep + Config.LightHouse.TiltPhaseOffset

			task.delay(BobPhase / BobSpeed, function()
				Signal:Animate(Instance, {
					Time = BobDuration,
					Style = Enum.EasingStyle.Sine,
					Direction = Enum.EasingDirection.InOut,
					RepeatCount = -1,
					Reverses = true,
					DelayTime = 0,
				}, {
					Position = UDim2.new(
						BasePosition.X.Scale,
						BasePosition.X.Offset,
						BasePosition.Y.Scale + BobAmplitude,
						BasePosition.Y.Offset
					),
				})
			end)

			task.delay(TiltPhase / TiltSpeed, function()
				Signal:Animate(Instance, {
					Time = TiltDuration,
					Style = Enum.EasingStyle.Sine,
					Direction = Enum.EasingDirection.InOut,
					RepeatCount = -1,
					Reverses = true,
					DelayTime = 0,
				}, { Rotation = TiltAmplitude })
			end)
		end

		return {
			Unload = function()
				Background:Destroy()

				for _, Wave in ipairs(WaveList) do
					Wave:Destroy()
				end

				for _, LightHouse in ipairs(LightHouseList) do
					LightHouse:Destroy()
				end
			end,
		}
	end

	return nil
end

Library.CornerPhases = {
	High = 15,
	Medium = 12,
	Low = 8,
}

function Library:SetCornerSize(Phase, Size)
	local PhaseSlot = Library.CornerPhases[Phase]
	Signal:Assert(PhaseSlot, "Invalid phase name: " .. tostring(Phase), "Library:SetCornerPhase")

	Library.CornerPhases[Phase] = Size

	for _, Corner in pairs(Library.Instances) do
		if Corner:IsA("UICorner") then
			if Corner.CornerRadius.Offset == PhaseSlot then
				Corner.CornerRadius = UDim.new(0, Size)
			end
		end
	end
end

--// UI
local OnDestroy = Signal.New()
Global.OverlayDestroy = OnDestroy

local UI = Library.New("ScreenGui", {
	Name = "UI",
	IgnoreGuiInset = true,
	Parent = Hui,
	DisplayOrder = 999,
}) :: ScreenGui

Protect(UI)

if not Library.IsStudio then
	if Global.sethiddenpropriety then
		Global.sethiddenpropriety(UI, "OnTopOfCoreBlur", true)
	end
end

local ContextMenus = Library.New("Folder", { Parent = UI, Name = "ContextMenus" })
local NotificationZone = Library.New("Frame", {
	Name = "NotificationZone",
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.new(0.18, 0, 1, 0),
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = UI,
})

Library.New("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	Parent = NotificationZone,
})

--// Notification Queue
local AddToQueue = Signal.New()
local RemoveFromQueue = Signal.New()

AddToQueue:Connect(function(Notification)
	Signal:Assert(Notification and Notification.Body, "Argument is nil and/or no body was found", "AddToQueue")

	local Body = Notification:FindFirstChildOfClass("TextButton")
	local StackSizeY = 0

	Signal:Animate(
		Body,
		{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
		{ Position = UDim2.new(0, 0, 0, 0) }
	)

	StackSizeY = StackSizeY + Body.AbsoluteSize.Y + 10

	local Old = {}
	for _, Child in ipairs(NotificationZone:GetChildren()) do
		if Child:IsA("Frame") and Child ~= Notification then
			table.insert(Old, Child)
		end
	end

	for I = #Old, 1, -1 do
		local OldFrame = Old[I]

		Signal:Animate(
			OldFrame,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Position = UDim2.new(1, 0, 1, -StackSizeY) }
		)

		StackSizeY = StackSizeY + OldFrame.AbsoluteSize.Y + 10
	end
end)

RemoveFromQueue:Connect(function(Notification)
	Signal:Assert(
		Notification and Notification:FindFirstChildOfClass("TextButton"),
		"Argument is nil and/or no body was found",
		"RemoveFromQueue"
	)

	local Body = Notification:FindFirstChildOfClass("TextButton")
	local StackSizeY = 0

	local Size = Body.AbsoluteSize
	Body.Size = UDim2.fromOffset(Size.X, Size.Y)
	Body.AutomaticSize = Enum.AutomaticSize.None

	for _, Frame in ipairs(Body:GetChildren()) do
		if Frame:IsA("Frame") then
			Frame.Visible = false
		end
	end

	Signal:Animate(Body, { Time = 0.15, Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.In }, {
		Size = UDim2.fromOffset(Size.X - 20, Size.Y - 20),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.1, -0.1),
	})

	task.delay(0.2, function()
		Notification.Visible = false
	end)

	local Old = {}
	for _, Child in ipairs(NotificationZone:GetChildren()) do
		if Child:IsA("Frame") and Child ~= Notification then
			table.insert(Old, Child)
		end
	end

	for I = #Old, 1, -1 do
		local OldFrame = Old[I]

		Signal:Animate(
			OldFrame,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Position = UDim2.new(1, 0, 1, -StackSizeY) }
		)

		StackSizeY = StackSizeY + OldFrame.AbsoluteSize.Y + 10
	end

	task.delay(0.25, function()
		Notification:Destroy()
	end)
end)

--// Role Coloring
InstanceAdded:Connect(function(Instance)
	if Instance:GetAttribute("Ignore") then
		return
	end

	if not Instance:IsA("GuiObject") then
		return
	end

	if Instance:GetAttribute("Role") then
		local Role = Instance:GetAttribute("Role")
		local Theme = ThemeManager.CurrentTheme

		if Role == "Background" and Instance.BackgroundColor3 ~= nil then
			Instance.BackgroundColor3 = Theme.BackgroundColor
			Instance.BackgroundTransparency = Theme.BackgroundTransparency
		elseif Role == "Accent" then
			if Instance:IsA("UIStroke") then
				Instance.Color = Theme.AccentColor
				return
			end

			if Instance.BackgroundColor3 ~= nil then
				Instance.BackgroundColor3 = Theme.AccentColor
			end
		elseif Role == "Text" and Instance.TextColor3 ~= nil then
			Instance.TextColor3 = Theme.TextColor
		elseif Role == "Icon" and Instance.ImageColor3 ~= nil then
			Instance.ImageColor3 = Theme.IconColor
		end
	end
end)

--// Window
function Library:Window(Data)
	Data = Data or {}
	local Controller, Body = {}, {}
	local DragHoverStart = Signal.New()
	local DragHoverEnd = Signal.New()

	local Minimize = Signal.New()
	local UnMinimize = Signal.New()
	local SetProfileAnonimity = Signal.New()

	local CloseThread = Signal.New()
	local ActiveCloseThread = nil

	local _UIScale = Library.New("UIScale", { Parent = UI, Scale = Library.Get(Data, { "UIScale" }, 1) }) :: UIScale

	Controller.SelectedTab = nil
	Controller.SelectedContainer = nil
	Controller.Corners = {}

	Controller.OnDestroy = OnDestroy
	Controller.OnMinimize = Minimize

	Controller.MinimizeKeybind = Library.Get(Data, { "MinimizeKeybind" }, Enum.KeyCode.RightShift)
	Controller.IsMinimized = Library.Get(Data, { "IsMinimized", "Minimized" }, false)
	Controller.Minimizing = false

	local Window = Library.New("Frame", {
		Name = "Window",
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = Data and (Data.WindowSize or Data.Size) or UDim2.new(0, 700, 0, 500),
		BackgroundTransparency = Library.Get(ThemeManager.CurrentTheme, { "BackgroundTransparency" }, 0.1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "Background",
		BorderSizePixel = 0,
		Parent = UI,
		ZIndex = -1,
		Visible = false,
	}) :: Frame

	local IgnoreLayout = Library.New("Folder", { Name = "IgnoreLayout", Parent = Window })

	local DragBar = Library.New("Frame", {
		Name = "DragBar",
		Visible = true,
		ZIndex = 1,
		LayoutOrder = 0,
		Position = UDim2.new(0.500, 0, -0.025, 0),
		Size = UDim2.new(0.300, 0, 0, 6),
		AnchorPoint = Vector2.new(0.500, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.None,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Rotation = 0,
		Active = false,
		Selectable = false,
		BackgroundTransparency = 0.6,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		BorderMode = Enum.BorderMode.Outline,
		ClipsDescendants = false,
		Transparency = 0.9,
		Parent = IgnoreLayout,
		Ignore = true,
	})

	local DragMechanic = Library.SetDraggable(Window, DragBar)
	local DragHover = false

	DragHoverStart:Connect(function()
		DragHover = true

		Signal:Animate(
			DragBar,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 0.2 }
		)
	end)

	DragHoverEnd:Connect(function()
		DragHover = false

		if DragMechanic:IsDragging() then
			return
		end

		Signal:Animate(
			DragBar,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 0.6 }
		)
	end)

	DragMechanic.DragEnd:Connect(function()
		if not DragHover then
			Signal:Animate(
				DragBar,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.9 }
			)
		end
	end)

	DragBar.MouseEnter:Connect(function()
		DragHoverStart:Fire()
	end)

	DragBar.MouseLeave:Connect(function()
		DragHoverEnd:Fire()
	end)

	Library.New("UICorner", {
		Name = "UICorner",
		CornerRadius = UDim.new(1.000, 0),
		Parent = DragBar,
	})

	Library.SetGlobal("OverlayInjected", true)
	Body.Window = Window

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = Window })
	Controller.WindowSize = Data and (Data.WindowSize or Data.Size) or UDim2.new(0, 700, 0, 500)
	Controller.WindowTransparency =
		Library.Get(ThemeManager.CurrentTheme, { "BackgroundTransparency" }, Window.BackgroundTransparency)

	Library.New("UIStroke", {
		Transparency = 0.9,
		Role = "Accent",
		Parent = Window,
	})

	local BackgroundImage = Library.New("ImageLabel", {
		Name = "BackgroundImage",
		ZIndex = -1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Icon = Library.Get(Data, { "BackgroundImage", "Background" }, ""),
		Role = "Icon",
		ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Crop,
		Ignore = true,
		Parent = IgnoreLayout,
	}) :: ImageLabel

	Body.BackgroundImage = BackgroundImage

	Signal:Track(BackgroundImage)
	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = BackgroundImage })

	local CornerData = Data.ImageCorners or {}
	local Corners = Controller.Corners

	Corners.TopLeft = Library.New("ImageLabel", {
		Name = "TopLeft",
		ZIndex = 1,
		Position = UDim2.new(0, -1, 0, -1),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Icon = "rbxassetid://90085857557952",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 1,
		Parent = IgnoreLayout,
		Ignore = true,
		Visible = CornerData.TopLeft and CornerData.TopLeft.Enabled or false,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = Corners.TopLeft })

	Corners.TopRight = Library.New("ImageLabel", {
		Name = "TopRight",
		ZIndex = 1,
		Position = UDim2.new(0, 1, 0, -1),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Icon = "rbxassetid://136612025197923",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 1,
		Parent = IgnoreLayout,
		Ignore = true,
		Visible = CornerData.TopRight and CornerData.TopRight.Enabled or false,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = Corners.TopRight })

	Corners.DownLeft = Library.New("ImageLabel", {
		Name = "DownLeft",
		ZIndex = 1,
		Position = UDim2.new(0, -1, 0, 1),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Icon = "rbxassetid://80706260659632",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 1,
		Parent = IgnoreLayout,
		Ignore = true,
		Visible = CornerData.DownLeft and CornerData.DownLeft.Enabled or false,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = Corners.DownLeft })

	Corners.DownRight = Library.New("ImageLabel", {
		Name = "DownRight",
		ZIndex = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Icon = "rbxassetid://117215442732435",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 1,
		Parent = IgnoreLayout,
		Ignore = true,
		Visible = CornerData.DownRight and CornerData.DownRight.Enabled or false,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = Corners.DownRight })

	local MainOverlay = Library.New("Frame", {
		Name = "MainOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Window,
		ZIndex = 5,
	})

	--[[Library.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Wraps = true,
		Parent = MainOverlay,
	})]]

	local Sidebar = Library.New("Frame", {
		Name = "Sidebar",
		Position = UDim2.new(0, 0, 0.109, 0),
		Size = UDim2.new(0.3, 0, 0.9, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = MainOverlay,
	})

	local Content = Library.New("Frame", {
		Name = "Content",
		LayoutOrder = 2,
		Position = UDim2.new(0.292, 0, 0.098, 0),
		Size = UDim2.new(0.7, 0, 0.9, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = MainOverlay,
	})

	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		Parent = Content,
	})

	Library.NewSizeConstraint(Sidebar, 230)

	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = Sidebar,
	})

	Library.New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Sidebar,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, 0), Parent = Sidebar })

	local Tabs = Library.New("ScrollingFrame", {
		Name = "Tabs",
		LayoutOrder = 2,
		Position = UDim2.new(0, 0, 0.165, 0),
		Size = UDim2.new(1, 0, 0.7, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ScrollBarThickness = 0,
		Parent = Sidebar,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 1),
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 1),
		PaddingRight = UDim.new(0, 1),
		Parent = Tabs,
	})

	Library.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Tabs,
	})

	local Interaction = Library.New("Frame", {
		Name = "Interaction",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0.12, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Sidebar,
	})

	Library.New("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Center,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = Interaction,
	})

	local Topbar = Library.New("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0.1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = MainOverlay,
	})

	Library.New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		Parent = Topbar,
	})

	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = Topbar,
	})

	local Left = Library.New("Frame", {
		Name = "Left",
		Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Topbar,
	})

	Library.New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = Left,
	})
	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 3),
		PaddingLeft = UDim.new(0, 3),
		Parent = Left,
	})

	local TopbarHeader = Library.New("Frame", {
		Name = "Header",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Left,
	})

	Library.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TopbarHeader,
	})

	local TitleDisplay = Library.New("TextLabel", {
		Name = "Title",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = Library.Get(Data, { "Title" }, "Title"),
		Role = "Text",
		TextSize = 20,
		TextTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
		Parent = TopbarHeader,
	})

	Signal:Track(TitleDisplay)

	local SubtitleDisplay = Library.New("TextLabel", {
		Name = "Subtitle",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = Library.Get(Data, { "SubTitle" }, ""),
		Role = "Text",
		TextSize = 16,
		TextTransparency = 0.4,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Font.new("rbxassetid://16658221428"),
		Parent = TopbarHeader,
	})

	Signal:Track(SubtitleDisplay)

	local Right = Library.New("Frame", {
		Name = "Right",
		LayoutOrder = 1,
		Size = UDim2.new(0.3, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Topbar,
	})

	Library.New("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Right,
	})

	--// Tabs
	local Select = Signal.New()
	local Deselect = Signal.New()
	local HoverStart = Signal.New()
	local HoverEnd = Signal.New()

	local Hovering = {}

	Select:Connect(function(Tab, Container)
		if Tab == Controller.SelectedTab and Container == Controller.SelectedContainer then
			return
		end

		if Controller.SelectedTab and Controller.SelectedContainer then
			Deselect:Fire(Controller.SelectedTab, Controller.SelectedContainer)
		end

		Controller.SelectedTab = Tab
		Controller.SelectedContainer = Container

		if Container then
			local UIPadding = Container:FindFirstChildOfClass("UIPadding")

			if UIPadding then
				UIPadding.PaddingBottom = UDim.new(0, 20)
				UIPadding.PaddingLeft = UDim.new(0, 20)
				UIPadding.PaddingRight = UDim.new(0, 20)
				UIPadding.PaddingTop = UDim.new(0, 20)

				Signal:Animate(
					UIPadding,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{
						PaddingBottom = UDim.new(0, 1),
						PaddingLeft = UDim.new(0, 1),
						PaddingRight = UDim.new(0, 1),
						PaddingTop = UDim.new(0, 1),
					}
				)
			end

			task.delay(0.1, function()
				Container.Visible = true
			end)
		end

		if Hovering[Tab] then
			Signal:Animate(
				Tab,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.93 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("UIStroke"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Transparency = 0.87 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("TextLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ TextTransparency = 0.18 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("ImageLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ ImageTransparency = 0.18 }
			)

			return
		end

		Signal:Animate(
			Tab,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 0.95 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("UIStroke"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Transparency = 0.9 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("TextLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ TextTransparency = 0.2 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("ImageLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ ImageTransparency = 0.2 }
		)
	end)

	Deselect:Connect(function(Tab, Container)
		if Container then
			Container.Visible = false
		end

		if Hovering[Tab] then
			Signal:Animate(
				Tab,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.98 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("UIStroke"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Transparency = 0.95 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("TextLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ TextTransparency = 0.55 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("ImageLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ ImageTransparency = 0.55 }
			)

			return
		end

		Signal:Animate(
			Tab,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 1 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("UIStroke"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Transparency = 1 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("TextLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ TextTransparency = 0.6 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("ImageLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ ImageTransparency = 0.6 }
		)
	end)

	HoverStart:Connect(function(Tab)
		Hovering[Tab] = true

		if Controller.SelectedTab == Tab then
			Signal:Animate(
				Tab,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.93 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("UIStroke"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Transparency = 0.87 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("TextLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ TextTransparency = 0.18 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("ImageLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ ImageTransparency = 0.18 }
			)

			return
		end

		Signal:Animate(
			Tab,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 0.98 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("UIStroke"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Transparency = 0.95 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("TextLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ TextTransparency = 0.55 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("ImageLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ ImageTransparency = 0.55 }
		)
	end)

	HoverEnd:Connect(function(Tab)
		Hovering[Tab] = nil

		if Controller.SelectedTab == Tab then
			Signal:Animate(
				Tab,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.95 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("UIStroke"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Transparency = 0.9 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("TextLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ TextTransparency = 0.2 }
			)

			Signal:Animate(
				Tab:FindFirstChildOfClass("ImageLabel"),
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ ImageTransparency = 0.2 }
			)

			return
		end

		Signal:Animate(
			Tab,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 1 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("UIStroke"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Transparency = 1 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("TextLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ TextTransparency = 0.6 }
		)

		Signal:Animate(
			Tab:FindFirstChildOfClass("ImageLabel"),
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ ImageTransparency = 0.6 }
		)
	end)

	--// Tab
	function Controller:Tab(Data)
		Data = Data or {}
		local Elements = {}

		local Tab = Library.New("TextButton", {
			Name = "Tab",
			Position = UDim2.new(0.075, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Role = "Accent",
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
			Parent = Tabs,
		}) :: TextButton

		Library.New("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			Parent = Tab,
		})

		Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Medium), Parent = Tab })
		Library.New("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = Tab,
		})

		Library.New("UIStroke", { Role = "Accent", Parent = Tab, Transparency = 1 })

		local IconDisplay = Library.New("ImageLabel", {
			Name = "Icon",
			LayoutOrder = 1,
			Position = UDim2.new(-0.005, 0, 0, 0),
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 1,
			Role = "Icon",
			Icon = Library.Get(Data, { "Icon", "Image", "ImageDisplay", "IconDisplay" }, ""),
			ImageTransparency = 0.2,
			Parent = Tab,
		})

		Signal:Track(IconDisplay)

		Library.New("TextLabel", {
			Name = "TabTitle",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(0.8, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = Library.Get(Data, { "Title" }, "Title"),
			Role = "Text",
			TextSize = 16,
			TextTransparency = 0.2,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold),
			Parent = Tab,
		})

		local Container = Library.New("ScrollingFrame", {
			Name = Library.Get(Data, { "Title" }, "Title"),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = Content,
		})

		Library.New("UIPadding", {
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
			PaddingLeft = UDim.new(0, 1),
			PaddingRight = UDim.new(0, 1),
			Parent = Container,
		})

		Library.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = Container,
		})

		if Data.Section then
			local Section = Library.New("Frame", {
				Name = "Section",
				LayoutOrder = -1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Container,
			})

			local Header = Library.New("Frame", {
				Name = "Header",
				LayoutOrder = 2,
				Position = UDim2.new(0.358, 0, 0.216, 0),
				Size = UDim2.new(0.667, 0, 0.569, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Section,
			})

			local TitleHash = Library.New("TextLabel", {
				Name = "Title",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = Data and (Library.Get(Data, { "Title" }, "Title") or Data.Name) or "Section",
				Role = "Text",
				TextSize = 20,
				TextTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
				Parent = Header,
			})

			Signal:Track(TitleHash)

			local DescriptionHash = Library.New("TextLabel", {
				Name = "Description",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = Data and (Data.Description or Data.Desc) or "Description",
				Role = "Text",
				TextSize = 16,
				TextTransparency = 0.4,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Font.new("rbxassetid://16658221428"),
				Parent = Header,
			})

			Signal:Track(DescriptionHash)

			Library.New("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Header,
			})

			Library.New("ImageLabel", {
				Name = "Icon",
				LayoutOrder = 1,
				Position = UDim2.new(0.195, 0, 0.5, 0),
				Size = UDim2.new(0, 35, 0, 35),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Icon = Library.Get(Data, { "Icon", "Image", "ImageDisplay", "IconDisplay" }, ""),
				Role = "Icon",
				ImageTransparency = 0.2,
				Visible = Data.Section.ShowIcon,
				Parent = Section,
			})

			Library.New("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				Parent = Section,
			})

			Library.New("UIPadding", {
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				Parent = Section,
			})
		end

		--// Logic
		Deselect:Fire(Tab, Container)

		local CallbackOnSelect = Signal.New()
		local CallbackOnDeselect = Signal.New()

		Elements.OnSelect = CallbackOnSelect
		Elements.OnDeselect = CallbackOnDeselect

		Tab.MouseButton1Click:Connect(function()
			Select:Fire(Tab, Container)
		end)

		Tab.MouseEnter:Connect(function()
			HoverStart:Fire(Tab)
		end)

		Tab.MouseLeave:Connect(function()
			HoverEnd:Fire(Tab)
		end)

		--// Elements
		function Elements:Toggle(Data)
			Data = Data or {}
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			Header.Size = UDim2.fromScale(0.8, 0)
			Interaction.Size = UDim2.fromScale(0.2, 0)
			ElementBody.Parent = Container

			local Toggle = Library.New("TextButton", {
				Name = "Toggle",
				Size = UDim2.new(0, 50, 0, 24),
				Role = "Accent",
				BackgroundTransparency = 0.95,
				BorderSizePixel = 0,
				Parent = Interaction,
			})

			Library.New("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = Toggle,
			})

			local Dot = Library.New("Frame", {
				Name = "Dot",
				Position = UDim2.new(0, 2, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 20, 0, 20),
				Role = "Accent",
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				Parent = Toggle,
			})

			Library.New("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = Dot,
			})

			--// Logic
			local AnimateOn = Signal.New()
			local AnimateOff = Signal.New()

			local Value = Library.Get(Data, { "Value", "Toggled" }, false)
			local CallbackOnLoad = Library.Get(Data, { "CallbackOnLoad", "CallbackOnCreation" }, false)
			local Callback = Signal:Callback(Data and Data.Callback)

			AnimateOn:Connect(function()
				Signal:Animate(
					Toggle,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ BackgroundTransparency = 0.9 }
				)

				Signal:Animate(
					Dot,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{
						BackgroundTransparency = 0.2,
						Position = UDim2.fromScale(1, 0.5),
						AnchorPoint = Vector2.new(1, 0.5),
					}
				)
			end)

			AnimateOff:Connect(function()
				Signal:Animate(
					Toggle,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ BackgroundTransparency = 0.95 }
				)

				Signal:Animate(
					Dot,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{
						BackgroundTransparency = 0.6,
						Position = UDim2.fromScale(0, 0.5),
						AnchorPoint = Vector2.new(0, 0.5),
					}
				)
			end)

			if CallbackOnLoad then
				Callback:Fire(Value)
			end

			if Value then
				AnimateOn:Fire()
			else
				AnimateOff:Fire()
			end

			Toggle.MouseButton1Click:Connect(function()
				Value = not Value
				Callback:Fire(Value)

				if Value then
					AnimateOn:Fire()
				else
					AnimateOff:Fire()
				end
			end)

			function Methods:SimulateToggle()
				Value = not Value
				Callback:Fire(Value)

				if Value then
					AnimateOn:Fire()
				else
					AnimateOff:Fire()
				end
			end

			function Methods:Set(HValue)
				Value = HValue
				Callback:Fire(Value)

				if Value then
					AnimateOn:Fire()
				else
					AnimateOff:Fire()
				end
			end

			return Methods, Body
		end

		function Elements:Slider(Data)
			Data = Data or {}
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			ElementBody.Parent = Container
			Header.Size = UDim2.fromScale(0.5, 0)
			Interaction.Size = UDim2.fromScale(0.5, 0)

			local NumberPlate = Library.New("TextBox", {
				Name = "NumberPlate",
				Size = UDim2.new(0, 43, 0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.95,
				LayoutOrder = 1,
				TextTransparency = 1,
				Text = "",
				Parent = Interaction,
			}) :: TextBox

			Library.NewSizeConstraint(NumberPlate, 50)
			Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Low), Parent = NumberPlate })

			Library.New("UIPadding", {
				PaddingTop = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 3),
				PaddingLeft = UDim.new(0, 9),
				PaddingRight = UDim.new(0, 9),
				Parent = NumberPlate,
			})

			local ValueText = Library.New("TextLabel", {
				Name = "ValueText",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = tostring(Library.Get(Data, { "Value", "Default", "Min", "MinimumValue" }, 0)),
				Role = "Text",
				TextSize = 15,
				TextTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
				Parent = NumberPlate,
			})

			Library.New("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Parent = NumberPlate,
			})

			local Slider = Library.New("Frame", {
				Name = "Slider",
				Size = UDim2.new(0.73, 0, 0, 7),
				BackgroundTransparency = 0.95,
				Active = true,
				Parent = Interaction,
			})

			Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Low), Parent = Slider })

			local Percent = Library.New("Frame", {
				Name = "Percent",
				Size = UDim2.new(0, 0, 1, 0),
				Role = "Accent",
				BackgroundTransparency = 0.2,
				Parent = Slider,
			})

			Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Low), Parent = Percent })

			--// Logic
			local Max = Library.Get(Data, { "Max", "MaximumValue" }, 100)
			local Min = Library.Get(Data, { "Min", "MinimumValue" }, 0)
			local Step = Library.Get(Data, { "Step", "Threshold" }, 1)
			local Value = Library.Get(Data, { "Default", "Value" }, Min)
			local SmoothSlide = Library.Get(Data, { "SmoothSlide", "Animate" }, false)

			local Callback = Signal:Callback(Data and Data.Callback)
			local Changed = Signal.New()
			local DragStart = Signal.New()
			local DragEnd = Signal.New()

			local Dragging = false

			local function GetDecimalPlaces(Step)
				local StepString = tostring(Step)
				local DecimalIndex = StepString:find("%.")

				if not DecimalIndex then
					return 0
				end

				return #StepString - DecimalIndex
			end

			local Decimals = GetDecimalPlaces(Step)

			local function Round(Number, StepValue)
				if StepValue == 0 then
					return Number
				end

				local Rounded = math.floor((Number / StepValue) + 0.5) * StepValue

				return tonumber(string.format("%." .. Decimals .. "f", Rounded))
			end

			local function AlphaFromValue(Target)
				if Max == Min then
					return 0
				end

				return (Target - Min) / (Max - Min)
			end

			local function ApplyValue(HValue, HCallback)
				HValue = math.clamp(Round(HValue, Step), Min, Max)

				if HValue == Value and SmoothSlide ~= false then
					return
				end

				Value = HValue

				local Alpha = AlphaFromValue(Value)

				if SmoothSlide == false then
					Percent.Size = UDim2.new(Alpha, 0, 1, 0)
				else
					Signal:Animate(
						Percent,
						{ Time = 0.1, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Size = UDim2.new(Alpha, 0, 1, 0) }
					)
				end

				ValueText.Text = tostring(Value)
				Changed:Fire(Value)

				if HCallback then
					Callback:Fire(Value)
				end
			end

			local function AlphaFromInput(X)
				local AbsoluteSize = Slider.AbsoluteSize.X

				if AbsoluteSize <= 0 then
					return AlphaFromValue(Value)
				end

				return math.clamp((X - Slider.AbsolutePosition.X) / AbsoluteSize, 0, 1)
			end

			local function ValueFromAlpha(Alpha)
				return Min + (Max - Min) * Alpha
			end

			Slider.InputBegan:Connect(function(Input)
				if
					Input.UserInputType ~= Enum.UserInputType.MouseButton1
					and Input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				Dragging = true
				DragStart:Fire(Value)
				ApplyValue(ValueFromAlpha(AlphaFromInput(Input.Position.X)), true)
			end)

			Library.TrackConnection(UserInputService.InputChanged:Connect(function(Input)
				if not Dragging then
					return
				end

				if
					Input.UserInputType == Enum.UserInputType.MouseMovement
					or Input.UserInputType == Enum.UserInputType.Touch
				then
					ApplyValue(ValueFromAlpha(AlphaFromInput(Input.Position.X)), true)
				end
			end))

			Library.TrackConnection(UserInputService.InputEnded:Connect(function(Input)
				if
					Dragging
					and (
						Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch
					)
				then
					Dragging = false
					DragEnd:Fire(Value)
				end
			end))

			task.delay(1, function()
				local Alpha = AlphaFromValue(Value)

				if SmoothSlide == false then
					Percent.Size = UDim2.new(Alpha, 0, 1, 0)
				else
					Signal:Animate(
						Percent,
						{ Time = 0.1, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Size = UDim2.new(Alpha, 0, 1, 0) }
					)
				end
			end)

			NumberPlate.FocusLost:Connect(function(EnterPressed)
				local Input = tonumber(NumberPlate.Text)

				if Input then
					ApplyValue(Input, true)
				end
			end)

			NumberPlate:GetPropertyChangedSignal("Text"):Connect(function()
				local Input = tonumber(NumberPlate.Text)

				if Input then
					ValueText.Text = tostring(Input)
				end
			end)

			function Methods:Set(HValue, HCallback)
				ApplyValue(HValue, HCallback == true)
			end

			function Methods:Get()
				return Value
			end

			Methods.Changed = Changed
			Methods.DragStart = DragStart
			Methods.DragEnd = DragEnd

			return Methods, Body
		end

		function Elements:Button(Data)
			Data = Data or {}
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			ElementBody.Parent = Container
			Header.Size = UDim2.fromScale(0.85, 0)
			Interaction.Size = UDim2.fromScale(0.15, 0)

			local ButtonHeading = Data and (Data.ButtonClass or Data.HeadingButton) or "Icon"

			if ButtonHeading == "Icon" then
				local ButtonHolder = Library.New("Frame", {
					Name = "Button",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 1,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0, 30, 0, 30),
					AnchorPoint = Vector2.new(0, 0),
					AutomaticSize = Enum.AutomaticSize.None,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
					Role = "Accent",
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BorderMode = Enum.BorderMode.Outline,
					ClipsDescendants = false,

					Parent = Interaction,
				})

				Library.New("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0, Library.CornerPhases.Medium),
					Parent = ButtonHolder,
				})

				Library.New("ImageLabel", {
					Name = "Icon",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 0,
					Position = UDim2.new(0.500, 0, 0.500, 0),
					Size = UDim2.new(0, 25, 0, 25),
					AnchorPoint = Vector2.new(0.500, 0.500),
					AutomaticSize = Enum.AutomaticSize.None,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
					Active = false,
					Selectable = false,
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BorderMode = Enum.BorderMode.Outline,
					ClipsDescendants = false,
					Icon = Data and (Data.ButtonIcon or Data.HeadingIcon) or "rbxassetid://72922480325213",
					Role = "Icon",
					ImageTransparency = 0.2,
					ScaleType = Enum.ScaleType.Stretch,
					SliceCenter = Rect.new(0, 0, 0, 0),
					SliceScale = 1,
					TileSize = UDim2.new(1.000, 0, 1.000, 0),
					ImageRectOffset = Vector2.new(0, 0),
					ImageRectSize = Vector2.new(0, 0),
					ResampleMode = Enum.ResamplerMode.Default,
					Parent = ButtonHolder,
				})
			else
				Library.New("TextLabel", {
					Name = "ButtonWatermark",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 0,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0, 0, 0, 0),
					AnchorPoint = Vector2.new(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = false,
					BackgroundTransparency = 1,
					Text = Data and (Data.ButtonText or Data.HeadingText) or "Button",
					Role = "Text",
					TextSize = 16,
					TextScaled = false,
					TextTransparency = 0.6000000238418579,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					Parent = Interaction,
				})
			end

			--// Logic
			local Callback = Signal:Callback(Data and Data.Callback)

			ElementBody.MouseButton1Click:Connect(function()
				Callback:Fire()
			end)

			function Methods:Click()
				Callback:Fire()
			end

			return Methods, Body
		end

		function Elements:Dropdown(Data)
			Data = Data or {}
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			ElementBody.Parent = Container
			Header.Size = UDim2.fromScale(0.6, 0)
			Interaction.Size = UDim2.fromScale(0.4, 0)

			local DropdownPlate = Library.New("Frame", {
				Name = "DropdownPlate",
				Size = UDim2.new(0, 0, 0, 35),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.95,
				Role = "Accent",
				LayoutOrder = 1,
				Parent = Interaction,
			}) :: Frame

			Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Low), Parent = DropdownPlate })
			Library.NewSizeConstraint(DropdownPlate, 150)

			Library.New("UIPadding", {
				PaddingTop = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 3),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = DropdownPlate,
			})

			local DropdownIndex = Library.New("TextLabel", {
				Name = "DropdownIndex",
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = "None",
				Role = "Text",
				TextSize = 15,
				TextTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.SplitWord,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold),
				Parent = DropdownPlate,
			}) :: TextLabel

			Library.NewSizeConstraint(DropdownIndex, Data.DropdownIcon and 110 or 130)

			Library.New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = DropdownPlate,
			})

			if Data.DropdownIcon then
				local Icon = Library.New("ImageLabel", {
					Name = "Icon",
					Size = UDim2.new(0, 20, 0, 20),
					LayoutOrder = 1,
					Role = "Icon",
					BackgroundTransparency = 1,
					Icon = type(Data.DropdownIcon) == "string" and Data.DropdownIcon or "rbxassetid://10709797508",
					ImageTransparency = 0.2,
					Parent = DropdownPlate,
				})

				Signal:Track(Icon)
			end

			--// Logic
			local Values = Data and (Data.Values or Data.Table or Data.Index) or {}
			local Value = Library.Get(Data, { "Value", "Default" }, nil)
			local Multi = Library.Get(Data, { "Multi", "Multiple" }, false)
			local CloseOnSelection = Library.Get(Data, { "CloseOnSelection", "CloseWhenSelected" }, false)
			local Callback = Signal:Callback(Data and Data.Callback)

			local Selected = {}
			local SelectedObjects = {}

			local ContextData = {
				Open = Signal.New(),
				ContextCallback = Signal.New(),

				ValueHoverStart = Signal.New(),
				ValueHoverEnd = Signal.New(),
			}

			ContextData.ContextCallback:Connect(function()
				Callback:Fire(Selected)

				if Multi then
					DropdownIndex.Text = table.concat(Selected, ", ")
				else
					DropdownIndex.Text = Selected
				end
			end)

			task.spawn(function()
				if Multi then
					if type(Value) == "table" then
						for _, String in ipairs(Value) do
							table.insert(Selected, String)
						end
					end
				else
					Selected = Value
				end

				ContextData.ContextCallback:Fire()
			end)

			local function MatchValue(ValueToMatch)
				if Multi then
					if table.find(Selected, ValueToMatch) then
						return true
					end
				else
					if Selected == ValueToMatch then
						return true
					end
				end

				return false
			end

			Minimize:Connect(function()
				if ActiveCloseThread then
					CloseThread:Fire()
					ActiveCloseThread:Disconnect()
				end
			end)

			ElementBody.MouseButton1Click:Connect(function()
				ContextData.Open:Fire(Values)
			end)

			ContextData.ValueHoverStart:Connect(function(Object)
				local ObjectText = Object:FindFirstChildOfClass("TextLabel").Text
				local IsSelected = MatchValue(ObjectText)

				if IsSelected then
					Signal:Animate(
						Object,
						{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.925 }
					)
				else
					Signal:Animate(
						Object,
						{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.95 }
					)
				end
			end)

			ContextData.ValueHoverEnd:Connect(function(Object)
				local ObjectText = Object:FindFirstChildOfClass("TextLabel").Text
				local IsSelected = MatchValue(ObjectText)

				if IsSelected then
					Signal:Animate(
						Object,
						{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.95 }
					)
				else
					Signal:Animate(
						Object,
						{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 1 }
					)
				end
			end)

			ContextData.Open:Connect(function(Data)
				if ActiveCloseThread then
					CloseThread:Fire()
					ActiveCloseThread:Disconnect()
				end

				local AbsolutePosition = DropdownPlate.AbsolutePosition
				local AbsoluteSize = DropdownPlate.AbsoluteSize

				local X = AbsolutePosition.X + (AbsoluteSize.X / 2) - (175 / 2)
				local Y = AbsolutePosition.Y + AbsoluteSize.Y + 60

				local InputConnection
				local ContextCloseThread
				local Children = 0

				for _, Child in pairs(Data) do
					Children = Children + 1
				end

				local ContextMenu = Library.New(Children < 8 and "Frame" or "ScrollingFrame", {
					Name = "ContextMenu",
					Visible = true,
					Position = UDim2.fromOffset(X, Y),
					Size = UDim2.new(0, 175, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Role = "Background",
					BackgroundTransparency = ThemeManager.CurrentTheme.BackgroundTransparency,
					Parent = ContextMenus,
					ZIndex = 2,
				})

				Library.New("UIListLayout", { Padding = UDim.new(0, 3), Parent = ContextMenu })

				Library.New("UIPadding", {
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					Parent = ContextMenu,
				})

				InputConnection = Library.TrackConnection(UserInputService.InputBegan:Connect(function(Input)
					if
						Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch
					then
						local MousePosition = Input.Position
						local AbsolutePosition = ContextMenu.AbsolutePosition
						local AbsoluteSize = ContextMenu.AbsoluteSize

						local IsOutside = (
							MousePosition.X < AbsolutePosition.X
							or MousePosition.X > AbsolutePosition.X + AbsoluteSize.X
							or MousePosition.Y < AbsolutePosition.Y
							or MousePosition.Y > AbsolutePosition.Y + AbsoluteSize.Y
						)

						if IsOutside then
							Library.DisconnectConnection(InputConnection)
							InputConnection = nil
							CloseThread:Fire()
						end
					end
				end))

				Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = ContextMenu })

				ContextCloseThread = CloseThread:Connect(function()
					if InputConnection then
						Library.DisconnectConnection(InputConnection)
						InputConnection = nil
					end

					for _, Button in ipairs(ContextMenu:GetChildren()) do
						if Button:IsA("TextButton") and Button:FindFirstChildOfClass("TextLabel") then
							Signal:Animate(
								Button,
								{ Time = 0.15, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
								{ Size = UDim2.new(1, 0, 0, 0) }
							)

							Signal:Animate(
								Button:FindFirstChildOfClass("TextLabel"),
								{ Time = 0.07, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
								{ TextTransparency = 1 }
							)
						end

						task.wait()
					end

					ContextMenu:Destroy()

					if ContextCloseThread then
						ContextCloseThread:Disconnect()
					end

					if ActiveCloseThread == ContextCloseThread then
						ActiveCloseThread = nil
					end
				end)

				ActiveCloseThread = ContextCloseThread

				if Children >= 8 then
					ContextMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
					ContextMenu.AutomaticCanvasSize = Enum.AutomaticSize.None
					ContextMenu.ScrollBarThickness = 0
					ContextMenu.AutomaticCanvasSize = Enum.AutomaticSize.Y
					ContextMenu.AutomaticSize = Enum.AutomaticSize.None

					ContextMenu.Size = UDim2.fromOffset(175, 305)
				end

				for _, String in ipairs(Data) do
					local ValueButton = Library.New("TextButton", {
						Name = String,
						Position = UDim2.new(0.075, 0, 0, 0),
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						Role = "Accent",
						BackgroundTransparency = 1,
						Text = "",
						Visible = false,
						Parent = ContextMenu,
						ClipsDescendants = true,
						ZIndex = 3,
					}) :: TextButton

					Library.New("TextLabel", {
						Name = "Title",
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						Text = String,
						Role = "Text",
						TextSize = 16,
						TextTransparency = 0.2,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold),
						Parent = ValueButton,
						ZIndex = 3,
					})

					Library.New("UIPadding", {
						PaddingTop = UDim.new(0, 9),
						PaddingBottom = UDim.new(0, 9),
						PaddingLeft = UDim.new(0, 9),
						PaddingRight = UDim.new(0, 9),
						Parent = ValueButton,
					})

					Library.New(
						"UICorner",
						{ CornerRadius = UDim.new(0, Library.CornerPhases.Medium), Parent = ValueButton }
					)

					local Size = ValueButton.AbsoluteSize.Y
					ValueButton.AutomaticSize = Enum.AutomaticSize.None
					ValueButton.Visible = true

					Signal:Animate(
						ValueButton,
						{ Time = 0.15, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Size = UDim2.new(1, 0, 0, Size) }
					)

					ValueButton.MouseEnter:Connect(function()
						ContextData.ValueHoverStart:Fire(ValueButton)
					end)

					ValueButton.MouseLeave:Connect(function()
						ContextData.ValueHoverEnd:Fire(ValueButton)
					end)

					ValueButton.MouseButton1Click:Connect(function()
						if MatchValue(String) then
							if Multi then
								local Index = table.find(Selected, String)

								if Index then
									table.remove(Selected, Index)

									local ObjectIndex = table.find(SelectedObjects, ValueButton)
									if ObjectIndex then
										table.remove(SelectedObjects, ObjectIndex)
									end
								end

								Signal:Animate(
									ValueButton,
									{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
									{ BackgroundTransparency = 1 }
								)

								ContextData.ContextCallback:Fire()
							end

							return
						end

						if Multi then
							table.insert(Selected, String)
							table.insert(SelectedObjects, ValueButton)

							ContextData.ContextCallback:Fire()
						else
							if SelectedObjects and typeof(SelectedObjects) == "Instance" then
								Signal:Animate(
									SelectedObjects,
									{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
									{ BackgroundTransparency = 1 }
								)
							end

							Selected = String
							SelectedObjects = ValueButton
							ContextData.ContextCallback:Fire()
						end

						if CloseOnSelection then
							CloseThread:Fire()
							ActiveCloseThread:Disconnect()
						end
					end)

					if MatchValue(String) then
						if Multi then
							table.insert(SelectedObjects, ValueButton)
						else
							SelectedObjects = ValueButton
						end

						Signal:Animate(
							ValueButton,
							{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
							{ BackgroundTransparency = 0.95 }
						)
					end
				end
			end)

			function Methods:Add(String)
				Signal:Assert(
					String and type(String) == "string",
					"Argument is not valid and/or is not a string",
					"Dropdown:Add"
				)

				table.insert(Values, String)
				table.sort(Values)
			end

			function Methods:Remove(String)
				Signal:Assert(
					String and type(String) == "string",
					"Argument is not valid and/or is not a string",
					"Dropdown:Remove"
				)

				if table.find(Values, String) then
					local Index = table.find(Values, String)

					table.remove(Values, Index)
					table.sort(Values)
				end
			end

			return Methods, Body
		end

		function Elements:Keybind(Data)
			Data = Data or {}
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			Header.Size = UDim2.fromScale(0.6, 0)
			Interaction.Size = UDim2.fromScale(0.4, 0)
			ElementBody.Parent = Container

			local Input = Library.New("Frame", {
				Name = "Input",
				LayoutOrder = 1,
				Size = UDim2.new(0, 0, 0, 35),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.95,
				BorderSizePixel = 0,
				Parent = Interaction,
			}) :: Frame

			Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Low), Parent = Input })
			Library.New("UIPadding", {
				PaddingTop = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 3),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = Input,
			})

			local BindName = Library.New("TextLabel", {
				Name = "BindName",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = "",
				Role = "Text",
				TextSize = 15,
				TextTransparency = 0.2,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold),
				RichText = true,
				Parent = Input,
			})

			Library.New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = Input,
			})

			--// Logic
			local Value = Library.Get(Data, { "Value", "Default" }, Enum.KeyCode.Asterisk)
			local Callback = Signal:Callback(Data and Data.Callback)
			local OnKeypressCalback = Signal:Callback(Data and (Data.KeyPressCallback or Data.OnKeyPressed))

			local OnListenStart = Signal.New()
			local OnListenEnd = Signal.New()

			local ListeningConnection
			local IsListening = false

			BindName.Text = Value.Name
			Callback:Fire(Value)

			OnListenStart:Connect(function()
				if IsListening then
					OnListenEnd:Fire(Value)

					if ListeningConnection then
						Library.DisconnectConnection(ListeningConnection)
					end
				end

				IsListening = true
				local FireInput

				BindName.Text = "Listening..."
				BindName.TextTransparency = 0.4

				ListeningConnection =
					Library.TrackConnection(UserInputService.InputBegan:Connect(function(Input, Procesed)
						if Procesed then
							return
						end

						if
							Signal:MatchInput(Input, Enum.UserInputType.MouseButton1)
							or Signal:MatchInput(Input, Enum.UserInputType.MouseButton2)
							or Signal:MatchInput(Input, Enum.UserInputType.MouseButton3)
						then
							FireInput = Input.UserInputType
						elseif Input.KeyCode then
							FireInput = Input.KeyCode
						end

						if FireInput then
							OnListenEnd:Fire(FireInput)
						end
					end))
			end)

			OnListenEnd:Connect(function(Bind: Enum.KeyCode)
				if ListeningConnection then
					Library.DisconnectConnection(ListeningConnection)
					ListeningConnection = nil
				end

				IsListening = false

				if Bind == Value then
					BindName.Text = Value.Name
					BindName.TextTransparency = 0.2

					return
				end

				BindName.Text = Bind.Name
				BindName.TextTransparency = 0.2

				Value = Bind
				Callback:Fire(Bind)
			end)

			ElementBody.MouseButton1Click:Connect(function()
				OnListenStart:Fire()
			end)

			Library.TrackConnection(UserInputService.InputBegan:Connect(function(Input, Procesed)
				if Procesed then
					return
				end

				if Signal:MatchInput(Input, Value) then
					OnKeypressCalback:Fire()
				end
			end))

			function Methods:Set(Keybind)
				Signal:Assert(
					Keybind and typeof(Keybind) == "EnumItem",
					"Argument is nil and/or is not an Enum Item",
					"Keybind:Set"
				)

				OnListenEnd:Fire(Keybind)
			end

			return Methods, Body
		end

		function Elements:Label(Data)
			local Methods = {}
			local Section = Library.New("TextButton", {
				Name = "Section",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = Container,
			})

			Section:SetAttribute("Divider", true)

			local SectionTitle = Library.New("TextLabel", {
				Name = "SectionTitle",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = Library.Get(Data, { "Title", "Text", "Name" }, "Label"),
				TextSize = Library.Get(Data, { "TextSize" }, 20),
				TextTransparency = 0.2,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
				Parent = Section,
			})

			Library.New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = Section,
			})

			local Icon = Library.New("ImageLabel", {
				Name = "Icon",
				Position = UDim2.new(-0.005, 0, 0, 0),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				Icon = Library.Get(Data, { "Icon", "Image", "ImageDisplay", "IconDisplay" }, ""),
				LayoutOrder = -1,
				ImageTransparency = 0.2,
				Parent = Section,
			})

			Signal:Track(Icon)

			function Methods:Set(Text)
				Signal:Assert(Text and type(Text) == "string", "Argument is nil and/or is not a string", "Label:Set")

				SectionTitle.Text = Text
			end

			function Methods:SetIcon(Image)
				Signal:Assert(
					Image and type(Image) == "string",
					"Argument is nil and/or is not a string",
					"Label:SetIcon"
				)

				Icon.Image = Image
			end

			return Methods, Section
		end

		function Elements:BodyLabel(Data)
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			Header.Size = UDim2.fromScale(0.5, 0)

			ElementBody.Parent = Container
			Interaction.Size = UDim2.fromScale(0.5, 0)

			local Value = Library.New("TextLabel", {
				Name = "Watermark",
				Visible = true,
				ZIndex = 1,
				LayoutOrder = 0,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = false,
				BackgroundTransparency = 1,
				Text = Library.Get(Data, { "Value", "Text", "Name" }, "Value"),
				Role = "Text",
				TextSize = 16,
				TextScaled = false,
				TextTransparency = 0.6000000238418579,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Parent = Interaction,
			})

			function Methods:Set(Text)
				Signal:Assert(
					Text and type(Text) == "string",
					"Argument is nil and/or is not a string",
					"BodyLabel:Set"
				)

				Value.Text = Text
			end

			local Callback = Signal:Callback(Data and Data.Callback or function() end)

			ElementBody.MouseButton1Click:Connect(function()
				Callback:Fire()
			end)

			return Methods, Body
		end

		function Elements:Divider(Data)
			local Methods = {}
			local Divider = Library.New("TextButton", {
				Name = "Divider",
				Size = UDim2.new(1, 0, 0, 10),
				BackgroundTransparency = 1,
				Parent = Container,
			})

			Divider:SetAttribute("Divider", true)

			Library.New("Frame", {
				Name = "Line",
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(Data and Data.Size or 0.9, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 0),
				Role = "Accent",
				BackgroundTransparency = Data and Data.Transparency or 0.9,
				Parent = Divider,
				BorderSizePixel = 0,
			})

			function Methods:Set(Size)
				Signal:Assert(Size and type(Size) == "number", "Argument is nil and/or is not a number", "Divider:Set")

				Divider.Size = UDim2.new(Size, 0, 0, 0)
			end

			return Methods, Divider
		end

		function Elements:ProfileBanner(Data)
			local Methods = {}
			local Profile = Library.New("Frame", {
				Name = "Profile",
				Position = UDim2.fromScale(0.012, 0.082),
				Size = UDim2.fromScale(1, 0.15),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Container,
			})

			Library.New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = Profile,
			})

			Library.New("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0.15, 0),
				Parent = Profile,
			})

			local ProfileIcon = Library.New("ImageLabel", {
				Name = "Icon",
				Visible = true,
				ZIndex = 1,
				LayoutOrder = 1,
				Position = UDim2.new(0.195, 0, 0.500, 0),
				Size = UDim2.new(0.000, 65, 0.000, 65),
				AnchorPoint = Vector2.new(0.500, 0.500),
				BackgroundColor3 = Color3.fromRGB(163, 162, 165),
				BackgroundTransparency = 0.95,
				Transparency = 0.95,
				Icon = Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size420x420
				),
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ImageTransparency = 0,
				Ignore = true,
				Rotation = 0,
				Parent = Profile,
			})

			Library.New("UIStroke", {
				Name = "UIStroke",
				ZIndex = 1,
				Transparency = 0.9,
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 1,
				Enabled = true,
				Parent = ProfileIcon,
			})

			Library.New("UICorner", {
				Name = "UICorner",
				CornerRadius = UDim.new(1.000, 0),
				Parent = ProfileIcon,
			})

			local Displays = Library.New("Frame", {
				Name = "Display",
				Visible = true,
				LayoutOrder = 1,
				Position = UDim2.new(0.156, 0, 0.115, 0),
				Size = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0.000, 0.000),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(163, 162, 165),
				BackgroundTransparency = 1,
				ClipsDescendants = false,
				Transparency = 1,
				Parent = Profile,
			})

			Library.New("UIListLayout", {
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.000, 0),
				ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
				Parent = Displays,
			})

			local Display = Library.New("TextLabel", {
				Name = "Display",
				Visible = true,
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(163, 162, 165),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Text = LocalPlayer.DisplayName or "Display",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextTransparency = 0.20000000298023224,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				RichText = true,
				Parent = Displays,
			})

			local User = Library.New("TextLabel", {
				Name = "User",
				Visible = true,
				ZIndex = 1,
				LayoutOrder = 2,
				Position = UDim2.new(0.000, 0, 0.000, 0),
				Size = UDim2.new(0.000, 0, 0.000, 0),
				AnchorPoint = Vector2.new(0.000, 0.000),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(163, 162, 165),
				BackgroundTransparency = 1,
				Text = "@" .. tostring(LocalPlayer.Name) .. "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Parent = Displays,
			})

			local ID = Library.New("TextLabel", {
				Name = "ID",
				Visible = true,
				AutomaticSize = Enum.AutomaticSize.XY,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
				BackgroundColor3 = Color3.fromRGB(163, 162, 165),
				LayoutOrder = 3,
				BackgroundTransparency = 1,
				Text = tostring(LocalPlayer.UserId),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Parent = Displays,
			})

			local IgnoreLayout = Library.New("Folder", {
				Name = "IgnoreLayout",
				Parent = Profile,
			})

			Library.New("UIListLayout", {
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = IgnoreLayout,
			})

			SetProfileAnonimity:Connect(function(Object, Value)
				if Object == "Username" then
					if Value then
						User.Text = "@Anonymous"
					else
						User.Text = "@" .. tostring(LocalPlayer.Name) .. ""
					end
				elseif Object == "Display" then
					if Value then
						Display.Text = "Anonymous"
					else
						Display.Text = tostring(LocalPlayer.DisplayName)
					end
				elseif Object == "Screenshot" then
					if Value then
						ProfileIcon.Image = Players:GetUserThumbnailAsync(
							1,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size420x420
						)
					else
						ProfileIcon.Image = Players:GetUserThumbnailAsync(
							LocalPlayer.UserId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size420x420
						)
					end
				end
			end)

			function Methods:Button(Data)
				local Button = Library.New("TextButton", {
					Name = "Button",
					LayoutOrder = Data.Order or 1,
					Size = UDim2.new(0, 30, 0, 30),
					BackgroundTransparency = 0.95,
					Parent = IgnoreLayout,
				})

				Library.New("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0, 8),
					Parent = Button,
				})

				local Icon = Library.New("ImageLabel", {
					Name = "Icon",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 16, 0, 16),
					BackgroundTransparency = 1,
					Icon = Data and Data.Icon or "",
					ImageTransparency = 0.4,
					Parent = Button,
				})

				--// Logic
				local Callback = Signal:Callback(Data and Data.Callback or function() end)
				local HoverStart = Signal.New()
				local HoverEnd = Signal.New()

				HoverStart:Connect(function()
					Signal:Animate(
						Button,
						{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.9 }
					)
				end)

				HoverEnd:Connect(function()
					Signal:Animate(
						Button,
						{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.95 }
					)
				end)

				Button.MouseEnter:Connect(function()
					HoverStart:Fire()
				end)

				Button.MouseLeave:Connect(function()
					HoverEnd:Fire()
				end)

				Button.MouseButton1Click:Connect(function()
					Callback:Fire()
				end)

				return Button
			end

			return Methods, Profile
		end

		function Elements:Paragraph(Data)
			local Methods = {}
			local Body = Library.SetupBody(Data)

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			Interaction.Visible = false
			Header.Size = UDim2.fromScale(1, 0)

			Body.Title.Size = UDim2.fromScale(0.95, 0)
			Body.Description.Size = UDim2.fromScale(0.95, 0)

			ElementBody.Parent = Container

			function Methods:SetBackgroundTransparency(Transparency)
				Signal:Assert(
					Transparency and type(Transparency) == "number",
					"Argument is nil and/or is not a number",
					"Paragraph:SetBackgroundTransparency"
				)

				ElementBody.BackgroundTransparency = Transparency
			end

			function Methods:SetBackgroundColor(Color)
				Signal:Assert(
					Color and typeof(Color) == "Color3",
					"Argument is nil and/or is not a Color3",
					"Paragraph:SetBackgroundColor"
				)

				ElementBody.BackgroundColor3 = Color
			end

			function Methods:FillIcon()
				local Icon = Body.Icon:FindFirstChildOfClass("ImageLabel")
				local Corner = Body.Icon:FindFirstChildOfClass("UICorner")

				Icon.Size = UDim2.fromScale(1, 1)
				Icon.ImageTransparency = 0

				Body.Icon.BackgroundTransparency = 1
				Corner:Clone().Parent = Icon
			end

			return Methods, Body
		end

		function Elements:Section(Data)
			Data = Data or {}
			local Methods = {}
			local Body = Library.SetupBody(Data)
			local Blank = Library.Get(Data, { "Blank" }, false)

			local Interaction = Body.Interaction :: Frame
			local Header = Body.Header :: Frame
			local ElementBody = Body.ElementBody :: TextButton
			ElementBody.Parent = Container

			local _Elements = Library.New("Frame", {
				Name = "Elements",
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Role = "Accent",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 10,
				Parent = ElementBody,
			}) :: Frame

			local List = ElementBody:FindFirstChildOfClass("UIListLayout"):Clone()
			List.Padding = UDim.new(0, Library.Get(Data, { "ElementPadding" }, 6))
			List.Parent = _Elements
			List.Wraps = true

			ElementBody:FindFirstChildOfClass("UIListLayout").Wraps = true

			Header.Size = UDim2.fromScale(0.9, 0)
			Interaction.Size = UDim2.fromScale(0.08, 0)

			if Blank then
				Header.Visible = false
				Interaction.Visible = false
			end

			local Class = Data and (Data.Class or Data.Type) or "Normal"
			local Chevron = nil

			if Class == "Toggle" then
				Header.Size = UDim2.fromScale(0.8, 0)
				Interaction.Size = UDim2.fromScale(0.18, 0)

				local Toggle = Library.New("TextButton", {
					Name = "Toggle",
					Size = UDim2.new(0, 50, 0, 24),
					Role = "Accent",
					BackgroundTransparency = 0.95,
					BorderSizePixel = 0,
					Parent = Interaction,
				})

				Library.New("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = Toggle,
				})

				local Dot = Library.New("Frame", {
					Name = "Dot",
					Position = UDim2.new(0, 2, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.new(0, 20, 0, 20),
					Role = "Accent",
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					Parent = Toggle,
				})

				Library.New("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = Dot,
				})

				--// Logic
				local AnimateOn = Signal.New()
				local AnimateOff = Signal.New()

				local Value = Library.Get(Data, { "Value", "Toggled" }, false)
				local Callback = Signal:Callback(Data and Data.Callback)

				AnimateOn:Connect(function()
					Signal:Animate(
						Toggle,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.9 }
					)

					Signal:Animate(
						Dot,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{
							BackgroundTransparency = 0.2,
							Position = UDim2.fromScale(1, 0.5),
							AnchorPoint = Vector2.new(1, 0.5),
						}
					)
				end)

				AnimateOff:Connect(function()
					Signal:Animate(
						Toggle,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ BackgroundTransparency = 0.95 }
					)

					Signal:Animate(
						Dot,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{
							BackgroundTransparency = 0.6,
							Position = UDim2.fromScale(0, 0.5),
							AnchorPoint = Vector2.new(0, 0.5),
						}
					)
				end)

				Callback:Fire(Value)
				if Value then
					AnimateOn:Fire()
				else
					AnimateOff:Fire()
				end

				Toggle.MouseButton1Click:Connect(function()
					Value = not Value
					Callback:Fire(Value)

					if Value then
						AnimateOn:Fire()
					else
						AnimateOff:Fire()
					end
				end)

				function Methods:SimulateToggle()
					Value = not Value
					Callback:Fire(Value)

					if Value then
						AnimateOn:Fire()
					else
						AnimateOff:Fire()
					end
				end

				function Methods:Set(HValue)
					Value = HValue
					Callback:Fire(Value)

					if Value then
						AnimateOn:Fire()
					else
						AnimateOff:Fire()
					end
				end
			elseif Class == "Watermark" then
				Header.Size = UDim2.fromScale(0.5, 0)
				Interaction.Size = UDim2.fromScale(0.48, 0)

				local Value = Library.New("TextLabel", {
					Name = "Watermark",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 0,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0, 0, 0, 0),
					AnchorPoint = Vector2.new(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = false,
					BackgroundTransparency = 1,
					Text = Library.Get(Data, { "Watermark", "Text", "Value" }, "Value"),
					Role = "Text",
					TextSize = 16,
					TextScaled = false,
					TextTransparency = 0.6000000238418579,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					Parent = Interaction,
				})
			else
				Library.New("ImageLabel", {
					Name = "Chevron",
					LayoutOrder = 5,
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 22, 0, 22),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Icon = "rbxassetid://109320394183701",
					ImageTransparency = 0.4,
					Rotation = 180,
					Parent = Interaction,
				})
			end

			--// Logic
			local Open = Signal.New()
			local Close = Signal.New()

			local Opened = Library.Get(Data, { "Opened" }, false)
			local Animating = false

			Open:Connect(function()
				if Animating then
					return
				end

				Animating = true
				_Elements.Visible = true

				if Chevron then
					Signal:Animate(
						Chevron,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Rotation = 0 }
					)
				end

				local Children = _Elements:GetChildren()
				local Pending = 0

				for _, Element in ipairs(Children) do
					if Element:IsA("TextButton") then
						Pending += 1
					end
				end

				if Pending == 0 then
					Animating = false
					return
				end

				local Completed = 0

				for _, Element in ipairs(Children) do
					if Element:IsA("TextButton") then
						local ExpandedHeight = Element:GetAttribute("ExpandedHeight")

						Element.Visible = true
						Element.ClipsDescendants = true

						if ExpandedHeight then
							Element.AutomaticSize = Enum.AutomaticSize.None
							Element.Size = UDim2.new(1, 0, 0, 0)

							Signal:Animate(
								Element,
								{ Time = 0.1, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
								{ Size = UDim2.new(1, 0, 0, ExpandedHeight) }
							)
						end

						task.delay(0.1, function()
							Element.AutomaticSize = Enum.AutomaticSize.Y
							Element.ClipsDescendants = false
							Completed += 1

							if Completed >= Pending then
								Animating = false
							end
						end)
					end
				end
			end)

			Close:Connect(function()
				if Animating then
					return
				end

				Animating = true

				if Chevron then
					Signal:Animate(
						Chevron,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Rotation = 180 }
					)
				end

				local Children = _Elements:GetChildren()
				local Pending = 0

				for _, Element in ipairs(Children) do
					if Element:IsA("TextButton") and Element.AbsoluteSize.Y then
						Pending += 1
					end
				end

				if Pending == 0 then
					_Elements.Visible = false
					Animating = false
					return
				end

				local Completed = 0

				for _, Element in ipairs(Children) do
					if Element:IsA("TextButton") then
						local AbsoluteSizeY = Element.AbsoluteSize.Y

						if AbsoluteSizeY then
							Element:SetAttribute("ExpandedHeight", AbsoluteSizeY)
							Element.AutomaticSize = Enum.AutomaticSize.None
							Element.Size = UDim2.new(1, 0, 0, AbsoluteSizeY)
							Element.ClipsDescendants = true

							Signal:Animate(
								Element,
								{ Time = 0.1, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
								{ Size = UDim2.new(1, 0, 0, 0) }
							)

							task.delay(0.1, function()
								Element.Visible = false
								Completed += 1

								if Completed >= Pending then
									_Elements.Visible = false
									Animating = false
								end
							end)
						end
					end
				end
			end)

			task.delay(0.5, function()
				if Opened then
					Open:Fire()
				else
					Close:Fire()
				end
			end)

			ElementBody.MouseButton1Click:Connect(function()
				Opened = not Opened

				if Opened then
					Open:Fire()
				else
					Close:Fire()
				end
			end)

			local function GetElements()
				local Bodies = {}

				for _, Element in ipairs(_Elements:GetChildren()) do
					if Element:IsA("TextButton") then
						table.insert(Bodies, Element)
					end
				end

				return #Bodies, Bodies
			end

			local function SetChildrenCorners()
				local _CornerSize = Library.Get(Data, { "CornerSize", "ElementCornerSize" }, 5)
				local Children, Bodies = GetElements()

				if Children > 1 then
					for Index, Object in ipairs(Bodies) do
						local Corner = Object:FindFirstChildOfClass("UICorner")
						if Corner then
							if Children == 2 then
								if Index == 1 then
									Corner.TopLeftRadius = UDim.new(0, 15)
									Corner.TopRightRadius = UDim.new(0, 15)
									Corner.BottomLeftRadius = UDim.new(0, _CornerSize)
									Corner.BottomRightRadius = UDim.new(0, _CornerSize)
								elseif Index == 2 then
									Corner.BottomLeftRadius = UDim.new(0, 15)
									Corner.BottomRightRadius = UDim.new(0, 15)
									Corner.TopLeftRadius = UDim.new(0, _CornerSize)
									Corner.TopRightRadius = UDim.new(0, _CornerSize)
								end
							elseif Children > 2 then
								if Index == 1 then
									Corner.TopLeftRadius = UDim.new(0, 15)
									Corner.TopRightRadius = UDim.new(0, 15)
									Corner.BottomLeftRadius = UDim.new(0, _CornerSize)
									Corner.BottomRightRadius = UDim.new(0, _CornerSize)
								elseif Index > 1 and Index < Children then
									Corner.TopLeftRadius = UDim.new(0, _CornerSize)
									Corner.TopRightRadius = UDim.new(0, _CornerSize)
									Corner.BottomLeftRadius = UDim.new(0, _CornerSize)
									Corner.BottomRightRadius = UDim.new(0, _CornerSize)
								elseif Index == Children then
									Corner.BottomLeftRadius = UDim.new(0, 15)
									Corner.BottomRightRadius = UDim.new(0, 15)
									Corner.TopLeftRadius = UDim.new(0, _CornerSize)
									Corner.TopRightRadius = UDim.new(0, CornerSize)
								end
							end
						end
					end
				end

				for Index, Object in ipairs(Bodies) do
					if Object:GetAttribute("Divider") == true then
						local Above = Bodies[Index - 1]
						local Below = Bodies[Index + 1]

						if Above then
							local Corner = Above:FindFirstChildOfClass("UICorner")
							if Corner then
								Corner.BottomLeftRadius = UDim.new(0, 15)
								Corner.BottomRightRadius = UDim.new(0, 15)
							end
						end

						if Below then
							local Corner = Below:FindFirstChildOfClass("UICorner")
							if Corner then
								Corner.TopLeftRadius = UDim.new(0, 15)
								Corner.TopRightRadius = UDim.new(0, 15)
							end
						end
					end
				end
			end

			function Methods:Toggle(Args)
				Args = Args or {}
				local Element, _Body = Elements:Toggle(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Button(Args)
				Args = Args or {}
				local Element, _Body = Elements:Button(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Slider(Args)
				Args = Args or {}
				local Element, _Body = Elements:Slider(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Dropdown(Args)
				Args = Args or {}
				local Element, _Body = Elements:Dropdown(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Keybind(Args)
				Args = Args or {}
				local Element, _Body = Elements:Keybind(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Label(Args)
				Args = Args or {}
				local Element, _Body = Elements:Label(Args)

				Library.New("UIPadding", {
					Parent = _Body,
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
				})

				_Body.Parent = _Elements
				return Element
			end

			function Methods:BodyLabel(Args)
				Args = Args or {}
				local Element, _Body = Elements:BodyLabel(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Paragraph(Args)
				Args = Args or {}
				local Element, _Body = Elements:Paragraph(Args)

				_Body.ElementBody.Parent = _Elements
				return Element
			end

			function Methods:Divider(Args)
				Args = Args or {}
				local Element, _Body = Elements:Divider(Args)

				_Body.Parent = _Elements
				return Element
			end

			SetChildrenCorners()

			_Elements.ChildAdded:Connect(function(Child)
				if Child:IsA("TextButton") then
					SetChildrenCorners()
				end
			end)

			return Methods, Body
		end

		--// Methods
		function Elements:Select()
			Select:Fire(Tab, Container)
		end

		function Elements:Deselect()
			Deselect:Fire(Tab, Container)
		end

		Select:Connect(function(_Tab, C)
			if _Tab == Tab then
				CallbackOnSelect:Fire()
			end
		end)

		Deselect:Connect(function(_Tab, C)
			if _Tab == Tab then
				CallbackOnDeselect:Fire()
			end
		end)

		return Elements, Tab, Container
	end

	--// Section
	function Controller:Section(Data)
		Data = Data or {}
		local TabController = {}
		local Section = Library.New("Frame", {
			Name = "Section",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Role = "Accent",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = Tabs,
		})

		local TransparencyPhase = Data.Transparency

		if TransparencyPhase == "Min" then
			Section.BackgroundTransparency = 0.95
		elseif TransparencyPhase == "Mid" then
			Section.BackgroundTransparency = 0.985
		elseif TransparencyPhase == "Max" then
			Section.BackgroundTransparency = 1
		end

		Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.High), Parent = Section })

		local SectionToggle = Library.New("TextButton", {
			Name = "SectionToggle",
			LayoutOrder = -999,
			Size = UDim2.new(1, 2, 0, 2),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			Parent = Section,
		})

		Library.New("TextLabel", {
			Name = "TabTitle",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = Data and (Library.Get(Data, { "Title" }, "Title") or Data.Name) or "Section",
			Role = "Text",
			Size = UDim2.new(0.75, 0, 0, 0),
			BackgroundTransparency = 1,
			TextSize = 16,
			TextTransparency = 0.4,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold),
			Parent = SectionToggle,
		})

		local IconDisplay = Library.New("ImageLabel", {
			Name = "Icon",
			LayoutOrder = 1,
			Position = UDim2.new(-0.005, 0, 0, 0),
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 1,
			Role = "Icon",
			Icon = Data and (Data.Icon or Data.Image) or "",
			ImageTransparency = 0.4,
			Parent = SectionToggle,
		})

		Signal:Track(IconDisplay)

		Library.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = SectionToggle,
		})

		Library.New("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 2),
			Parent = SectionToggle,
		})

		local IgnoreLayout = Library.New("Folder", { Name = "IgnoreLayout", Parent = SectionToggle })

		local Chevron = Library.New("ImageLabel", {
			Name = "Chevron",
			LayoutOrder = 5,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, 22, 0, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Icon = "rbxassetid://109320394183701",
			Role = "Icon",
			ImageTransparency = 0.4,
			Rotation = 180,
			Parent = IgnoreLayout,
		})

		Library.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = Section,
		})

		local Padding = Library.New("UIPadding", {
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			Parent = Section,
		})

		local Open = Signal.New()
		local Close = Signal.New()
		local Opened = Library.Get(Data, { "Opened" }, false)

		local Animating = false
		local Debounce = 0.05

		Open:Connect(function()
			Animating = true

			Signal:Animate(
				Padding,
				{ Time = 0.1, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ PaddingBottom = UDim.new(0, 6) }
			)

			Signal:Animate(
				Chevron,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Rotation = 0 }
			)

			local Index = 0
			local LastDelay = 0

			for _, Tab in ipairs(Section:GetChildren()) do
				if Tab ~= SectionToggle and Tab:IsA("TextButton") then
					local ExpandedHeight = Tab:GetAttribute("ExpandedHeight")
					local Delay = Index * Debounce
					LastDelay = Delay
					Index += 1

					Tab.Visible = true
					Tab.ClipsDescendants = true

					task.delay(Delay, function()
						if ExpandedHeight then
							Tab.AutomaticSize = Enum.AutomaticSize.None
							Tab.Size = UDim2.new(1, 0, 0, 0)

							Signal:Animate(Tab, {
								Time = 0.1,
								Style = Enum.EasingStyle.Sine,
								Direction = Enum.EasingDirection.Out,
							}, { Size = UDim2.new(1, 0, 0, ExpandedHeight) })
						end

						task.delay(0.1, function()
							Tab.AutomaticSize = Enum.AutomaticSize.Y
							Tab.ClipsDescendants = false
						end)
					end)
				end
			end

			task.delay(LastDelay + 0.1, function()
				Animating = false
			end)
		end)

		Close:Connect(function()
			Animating = true

			Signal:Animate(
				Padding,
				{ Time = 0.1, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ PaddingBottom = UDim.new(0, 1) }
			)

			Signal:Animate(
				Chevron,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Rotation = 180 }
			)

			local Index = 0
			local LastDelay = 0

			for _, Tab in ipairs(Section:GetChildren()) do
				if Tab ~= SectionToggle and Tab:IsA("TextButton") then
					local AbsoluteSizeY = Tab.AbsoluteSize.Y
					local Delay = Index * Debounce
					LastDelay = Delay
					Index += 1

					if AbsoluteSizeY then
						Tab:SetAttribute("ExpandedHeight", AbsoluteSizeY)
						Tab.AutomaticSize = Enum.AutomaticSize.None
						Tab.Size = UDim2.new(1, 0, 0, AbsoluteSizeY)
						Tab.ClipsDescendants = true

						task.delay(Delay, function()
							Signal:Animate(Tab, {
								Time = 0.1,
								Style = Enum.EasingStyle.Sine,
								Direction = Enum.EasingDirection.Out,
							}, { Size = UDim2.new(1, 0, 0, 0) })

							task.delay(0.1, function()
								Tab.Visible = false
							end)
						end)
					end
				end
			end

			task.delay(LastDelay + 0.1, function()
				Animating = false
			end)
		end)

		function TabController:Tab(Data)
			local Elements, Body = Controller:Tab(Data)

			if Body then
				Body.Parent = Section

				if not Opened then
					task.defer(function()
						local AbsoluteSizeY = Body.AbsoluteSize.Y

						Body:SetAttribute("ExpandedHeight", AbsoluteSizeY)
						Body.AutomaticSize = Enum.AutomaticSize.None
						Body.Size = UDim2.new(1, 0, 0, 0)
						Body.ClipsDescendants = true
						Body.Visible = false
					end)
				end
			end

			return Elements, Body
		end

		if Opened then
			Open:Fire()
		else
			Close:Fire()
		end

		SectionToggle.MouseButton1Click:Connect(function()
			if Animating then
				return
			end

			Opened = not Opened

			if Opened then
				Open:Fire()
			else
				Close:Fire()
			end
		end)

		return TabController
	end

	function Controller:Divider(Data)
		local Divider = Library.New("Frame", {
			Name = "Divider",
			Size = UDim2.new(1, 0, 0, 10),
			BackgroundTransparency = 1,
			Parent = Tabs,
		})

		Library.New("Frame", {
			Name = "Line",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(Library.Get(Data, { "Size" }, 0.9), 0, 0, 1),
			AnchorPoint = Vector2.new(0.5, 0),
			Role = "Accent",
			BackgroundTransparency = Library.Get(Data, { "Transparency" }, 0.9),
			Parent = Divider,
			BorderSizePixel = 0,
		})

		return Divider
	end

	function Controller:SetBackgroundImage(Image)
		Signal:Assert(Image and type(Image) == "string", "Argument is nil and/or is not a string", "SetBackgroundImage")
		local Clone = BackgroundImage:Clone()
		Clone.ImageTransparency = 0
		BackgroundImage.Image = Image

		Signal:Animate(
			Clone,
			{ Time = 0.35, Style = Enum.EasingStyle.Cubic, Direction = Enum.EasingDirection.InOut },
			{ ImageTransparency = 1 }
		)

		task.delay(0.35, function()
			Clone:Destroy()
		end)
	end

	function Controller:SetBackgroundImageTransparency(Transparency)
		Signal:Assert(
			Transparency and type(Transparency) == "number",
			"Argument is nil and/or is not a number",
			"SetBackgroundImageTransparency"
		)

		Signal:Animate(
			BackgroundImage,
			{ Time = 0.5, Style = Enum.EasingStyle.Cubic, Direction = Enum.EasingDirection.InOut },
			{ ImageTransparency = Transparency }
		)
	end

	function Controller:SetWindowTransparency(Transparency)
		Signal:Assert(
			Transparency ~= nil and type(Transparency) == "number",
			"Argument is nil and/or is not a number",
			"SetWindowTransparency"
		)

		Signal:Animate(
			Window,
			{ Time = 0.5, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = Transparency }
		)

		Controller.WindowTransparency = Transparency
	end

	function Controller:NewTopbarButton(Data)
		Data = Data or {}
		local Button = Library.New("TextButton", {
			Name = "Button",
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			Parent = Right,
			LayoutOrder = Data.Order,
		})

		Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Low), Parent = Button })

		Library.New("ImageLabel", {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Icon = Data.Icon,
			Role = "Icon",
			ImageTransparency = 0.4,
			Parent = Button,
		})

		local Callback = Signal.New()
		local HoverStart = Signal.New()
		local HoverEnd = Signal.New()

		HoverStart:Connect(function()
			Signal:Animate(
				Button,
				{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.95 }
			)
		end)

		HoverEnd:Connect(function()
			Signal:Animate(
				Button,
				{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 1 }
			)
		end)

		Button.MouseEnter:Connect(function()
			HoverStart:Fire()
		end)

		Button.MouseLeave:Connect(function()
			HoverEnd:Fire()
		end)

		Callback:Connect(Data.Callback)

		Button.MouseButton1Click:Connect(function()
			Callback:Fire()
		end)

		return Button
	end

	function Controller:NewInteractionButton(Data)
		Data = Data or {}
		local InteractionButton = Library.New("TextButton", {
			Name = "Button",
			LayoutOrder = Data.Order,
			Size = UDim2.new(0, 35, 0, 35),
			Role = "Accent",
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
			Text = "",
			Parent = Interaction,
		})

		Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Medium), Parent = InteractionButton })

		Library.New("ImageLabel", {
			Name = "Icon",
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 20, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Icon = Library.Get(Data, { "Icon", "Image", "ImageDisplay", "IconDisplay" }, ""),
			Role = "Icon",
			ImageTransparency = 0.4,
			Parent = InteractionButton,
		})

		local Callback = Signal:Callback(Data and Data.Callback)
		local HoverStart = Signal.New()
		local HoverEnd = Signal.New()

		HoverStart:Connect(function()
			Signal:Animate(
				InteractionButton,
				{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.9 }
			)
		end)

		HoverEnd:Connect(function()
			Signal:Animate(
				InteractionButton,
				{ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
				{ BackgroundTransparency = 0.95 }
			)
		end)

		InteractionButton.MouseEnter:Connect(function()
			HoverStart:Fire()
		end)

		InteractionButton.MouseLeave:Connect(function()
			HoverEnd:Fire()
		end)

		InteractionButton.MouseButton1Click:Connect(function()
			Callback:Fire()
		end)

		return InteractionButton
	end

	function Controller:SetWindowSize(Size)
		Signal:Assert(Size and typeof(Size) == "UDim2", "Argument is nil and/or is not an UDIM2 Value", "SetWindowSize")

		Signal:Animate(
			Window,
			{ Time = 0.2, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
			{ Size = Size }
		)

		Controller.WindowSize = Size
	end

	function Controller:SetUIScale(Scale)
		Signal:Assert(Scale ~= nil and type(Scale) == "number", "Argument is nil and/or is not a number", "SetUIScale")

		_UIScale.Scale = Scale
	end

	function Controller:SetMinimizeKeybind(Keybind)
		Signal:Assert(
			Keybind and typeof(Keybind) == "EnumItem",
			"Argument is nil and/or is not an EnumItem",
			"SetMinimizeKeybind"
		)
		Controller.MinimizeKeybind = Keybind
	end

	function Controller:MinimizeWindow()
		Minimize:Fire()
	end

	function Controller:UnMinimizeWindow()
		UnMinimize:Fire()
	end

	function Controller:Destroy()
		if Controller.Destroyed then
			return
		end

		Controller.Destroyed = true
		OnDestroy:Fire()
	end

	function Controller:SetCornerProperty(Name, Property, Value)
		local Corner = Controller.Corners[Name]
		if Corner then
			if string.find(Property, "Color") or string.find(Property, "Transparency") then
				Signal:Animate(
					Corner,
					{ Time = 0.6, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
					{ [Property] = Value }
				)
			else
				Corner[Property] = Value
			end
		end
	end

	--// Animations
	function Controller:LoadAnimation(Animation, Data)
		Controller.LoadedAnimation = Library.SetupAnimation(Animation, IgnoreLayout, Data)
		BackgroundImage.Visible = false
	end

	function Controller:UnloadAnimation()
		if Controller.LoadedAnimation then
			Controller.LoadedAnimation:Unload()
			Controller.LoadedAnimation = nil

			BackgroundImage.Visible = true
		end
	end

	do --// Topbar Buttons
		Controller:NewTopbarButton({ --// Close
			Order = 999,
			Icon = "rbxassetid://10747384394",
			Callback = function()
				Controller:Destroy()
			end,
		})

		Controller:NewTopbarButton({ --// Minimize
			Order = 998,
			Icon = "rbxassetid://10734896206",
			Callback = function()
				if Controller.IsMinimized then
					Controller:UnMinimizeWindow()
				else
					Controller:MinimizeWindow()
				end
			end,
		})
	end

	if Data.Profile then
		local Profile = Library.New("Frame", {
			Name = "Profile",
			LayoutOrder = Library.Get(Data.Profile, { "Order", "LayoutOrder" }, 1),
			Size = UDim2.new(1, 0, 0.15, 0),
			BackgroundTransparency = Library.Get(Data.Profile, { "Transparent" }, false) and 1 or 0.95,
			Role = "Accent",
			BorderSizePixel = 0,
			Parent = Sidebar,
		})

		Library.NewSizeConstraint(Profile, 200, 70)
		Library.New("UICorner", { CornerRadius = UDim.new(0, Library.CornerPhases.Medium), Parent = Profile })

		Library.New("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = Profile,
		})

		local Padding = Library.New("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			Parent = Profile,
		}) :: UIPadding

		if not Library.Get(Data.Profile, { "Transparent" }, false) then
			Padding.PaddingLeft = UDim.new(0, 8)
		end

		local ProfileIcon = Library.New("ImageLabel", {
			Name = "Icon",
			LayoutOrder = 1,
			Position = UDim2.new(0.195, 0, 0.5, 0),
			Size = UDim2.new(0, 45, 0, 45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
			Icon = Library.Get(Data.Profile, { "AnonymousScreenshot" }, false)
					and Players:GetUserThumbnailAsync(1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				or Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size420x420
				),
			Ignore = true,
			Parent = Profile,
		})

		Library.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProfileIcon })
		Library.New("UIStroke", {
			Transparency = 0.9,
			Role = "Accent",
			Parent = ProfileIcon,
		})

		local Header = Library.New("Frame", {
			Name = "",
			LayoutOrder = 1,
			Position = UDim2.new(0.358, 0, 0.216, 0),
			Size = UDim2.new(0.667, 0, 0.569, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = Profile,
		})

		Library.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Header,
		})

		local Display = Library.New("TextLabel", {
			Name = "Title",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = Library.Get(Data.Profile, { "DisplayAnonym" }, false) and "Anonymous"
				or tostring(LocalPlayer.DisplayName),
			Role = "Text",
			TextSize = 16,
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
			Parent = Header,
		})

		local Username = Library.New("TextLabel", {
			Name = "Subtitle",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = Library.Get(Data.Profile, { "UserAnonym" }, false) and "@Anonymous"
				or "@" .. tostring(LocalPlayer.Name),
			Role = "Text",
			TextSize = 14,
			TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = Font.new("rbxassetid://16658221428"),
			Parent = Header,
		})

		SetProfileAnonimity:Connect(function(Object, Value)
			if Object == "Username" then
				if Value then
					Username.Text = "@Anonymous"
				else
					Username.Text = "@" .. tostring(LocalPlayer.Name) .. ""
				end
			elseif Object == "Display" then
				if Value then
					Display.Text = "Anonymous"
				else
					Display.Text = tostring(LocalPlayer.DisplayName)
				end
			elseif Object == "Screenshot" then
				if Value then
					ProfileIcon.Image =
						Players:GetUserThumbnailAsync(1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				else
					ProfileIcon.Image = Players:GetUserThumbnailAsync(
						LocalPlayer.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size420x420
					)
				end
			end
		end)
	else
		Sidebar.Size = UDim2.fromScale(0.3, 0.88)
	end

	Controller.CurrentOverlay = MainOverlay

	Minimize:Connect(function()
		if Controller.Minimizing then
			return
		end

		Signal:Assert(Controller.CurrentOverlay, "No overlay found", "Minimize:Connect")
		Signal:Assert(Window, "No window found", "Minimize:Connect")

		Controller.Minimizing = true
		Controller.IsMinimized = true

		Controller.CurrentOverlay.Visible = false

		Signal:Animate(Window, { Time = 0.3, Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.In }, {
			Size = UDim2.fromOffset(Controller.WindowSize.X.Offset - 20, Controller.WindowSize.Y.Offset - 20),
			BackgroundTransparency = 1,
		})

		local Stroke = Window:FindFirstChildOfClass("UIStroke")

		if Stroke then
			Signal:Animate(
				Stroke,
				{ Time = 0.3, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.In },
				{ Transparency = 1 }
			)
		end

		task.delay(0.3, function()
			if Controller.IsMinimized and Window then
				Window.Visible = false
			end

			Controller.Minimizing = false
		end)
	end)

	UnMinimize:Connect(function()
		if Controller.Minimizing then
			return
		end

		Signal:Assert(Controller.CurrentOverlay, "No overlay found", "UnMinimize:Connect")
		Signal:Assert(Window, "No window found", "UnMinimize:Connect")

		Controller.Minimizing = true
		Controller.IsMinimized = false

		Window.Visible = true
		Window.BackgroundTransparency = 1

		Signal:Animate(
			Window,
			{ Time = 0.35, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
			{ Size = Controller.WindowSize, BackgroundTransparency = ThemeManager.CurrentTheme.BackgroundTransparency }
		)

		local Stroke = Window:FindFirstChildOfClass("UIStroke")

		if Stroke then
			Signal:Animate(
				Stroke,
				{ Time = 0.35, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ Transparency = 0.9 }
			)
		end

		task.delay(0.35, function()
			if not Controller.IsMinimized and Controller.CurrentOverlay then
				Controller.CurrentOverlay.Visible = true
			end

			Controller.Minimizing = false
		end)
	end)

	Library.TrackConnection(UserInputService.InputBegan:Connect(function(Input, Procesed)
		if Procesed then
			return
		end

		if Signal:MatchInput(Input, Controller.MinimizeKeybind) then
			if Controller.IsMinimized then
				Controller:UnMinimizeWindow()
			else
				Controller:MinimizeWindow()
			end
		end
	end))

	if Controller.IsMinimized then
		Controller:MinimizeWindow()
	else
		Controller:UnMinimizeWindow()
	end

	Library:SetTheme(Data and Data.Theme or "Dark")

	return Controller, Body
end

--// Notification
function Library:Notify(Data)
	Data = Data or {}
	local Notification = Library.New("Frame", {
		Name = "Notification",
		ZIndex = 1,
		LayoutOrder = 0,
		Position = UDim2.new(1.000, 0, 1.000, 0),
		Size = UDim2.new(1.000, 0, 0, 0),
		AnchorPoint = Vector2.new(1.000, 1.000),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = NotificationZone,
	})

	local Body = Library.New("TextButton", {
		Name = "Body",
		ZIndex = 1,
		LayoutOrder = 0,
		Position = UDim2.new(1.5, 0, 0, 0),
		Size = UDim2.new(1.000, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Role = "Background",
		ClipsDescendants = false,
		Parent = Notification,
	})

	Library.New("UIPadding", {
		Name = "UIPadding",
		PaddingTop = UDim.new(0, 15),
		PaddingBottom = UDim.new(0, 15),
		PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15),
		Parent = Body,
	})

	local Header = Library.New("Frame", {
		Name = "Header",
		Visible = true,
		ZIndex = 2,
		LayoutOrder = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1.000, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Rotation = 0,
		Active = false,
		Selectable = false,
		Role = "Accent",
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		BorderMode = Enum.BorderMode.Outline,
		ClipsDescendants = false,
		Parent = Body,
	})

	Library.New("TextLabel", {
		Name = "Title",
		ZIndex = 1,
		LayoutOrder = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.800, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Text = Library.Get(Data, { "Title" }, "Title"),
		Role = "Text",
		TextSize = 20,
		TextScaled = false,
		TextTransparency = 0.2,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Parent = Header,
	})

	Library.New("UIListLayout", {
		Name = "UIListLayout",
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
		Parent = Header,
	})

	if Library.Get(Data, { "Icon" }) then
		local Icon = Library.New("ImageLabel", {
			Name = "Icon",
			Visible = true,
			ZIndex = 1,
			LayoutOrder = 0,
			Position = UDim2.new(-0.005, 0, 0, 0),
			Size = UDim2.new(0, 22, 0, 22),
			AnchorPoint = Vector2.new(0, 0),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			Icon = Library.Get(Data, { "Icon" }),
			Role = "Icon",
			ImageTransparency = 0.20000000298023224,
			Parent = Header,
		})

		Signal:Track(Icon)
	end

	local IgnoreLayout = Library.New("Folder", { Name = "IgnoreLayout", Parent = Header })

	local Content = Library.New("Frame", {
		Name = "Content",
		ZIndex = 2,
		LayoutOrder = 2,
		Position = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1.000, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		Role = "Accent",
		BackgroundTransparency = 1,
		Parent = Body,
	})

	local ContentText = Library.New("TextLabel", {
		Name = "ContentText",
		ZIndex = 1,
		LayoutOrder = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1.000, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = Library.Get(Data, { "Content" }, ""),
		Role = "Text",
		TextSize = 16,
		TextTransparency = 0.4000000059604645,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Parent = Content,
	})

	Signal:Track(ContentText, Content)

	Library.New("UIListLayout", {
		Name = "UIListLayout",
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
		Parent = Content,
	})

	Library.New("UIListLayout", {
		Name = "UIListLayout",
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
		Parent = Body,
	})

	Library.New("UICorner", {
		Name = "UICorner",
		CornerRadius = UDim.new(0, Library.CornerPhases.High),
		Parent = Body,
	})

	local Background = Library.Get(Data, { "Background", "BackgroundImage" })
	if Background then
		local IgnoreLayout_1 = Library.New("Folder", {
			Name = "IgnoreLayout",
			Parent = Body,
		})

		local BackgroundImage = Library.New("ImageLabel", {
			Name = "BackgroundImage",
			ZIndex = 1,
			LayoutOrder = 0,
			Position = UDim2.new(0.500, 0, 0.500, 0),
			Size = UDim2.new(1.000, 30, 1.000, 30),
			AnchorPoint = Vector2.new(0.500, 0.500),
			BackgroundTransparency = 1,
			Icon = Background,
			ImageTransparency = 0.800000011920929,
			Parent = IgnoreLayout_1,
		})

		Library.New("UICorner", {
			Name = "UICorner",
			CornerRadius = UDim.new(0, Library.CornerPhases.High),
			Parent = BackgroundImage,
		})
	end

	local ButtonsData = Library.Get(Data, { "Buttons" })
	if ButtonsData and #ButtonsData > 0 then
		local ButtonLayout = Library.New("Frame", {
			Name = "ButtonLayout",
			Visible = true,
			ZIndex = 2,
			LayoutOrder = 3,
			Position = UDim2.new(-0.004, 0, 0.987, 0),
			Size = UDim2.new(1.000, 0, 0, 35),
			AnchorPoint = Vector2.new(0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Role = "Accent",
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			Parent = Body,
		})

		local Buttons = Library.New("ScrollingFrame", {
			Name = "Buttons",
			ZIndex = 1,
			LayoutOrder = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1.000, 0, 1.000, 0),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			BorderMode = Enum.BorderMode.Outline,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ClipsDescendants = true,
			ScrollBarThickness = 0,
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			ScrollBarImageTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ScrollingEnabled = true,
			Parent = ButtonLayout,
		})

		Library.New("UIListLayout", {
			Name = "UIListLayout",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
			Parent = Buttons,
		})

		for Index, Value in ipairs(ButtonsData) do
			local NotificationButton = Library.New("TextButton", {
				Name = "NotificationButton",
				ZIndex = 1,
				LayoutOrder = 1,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				Role = "Accent",
				BackgroundTransparency = 0.949999988079071,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				Transparency = 0.949999988079071,
				Parent = Buttons,
			})

			Library.New("UICorner", {
				Name = "UICorner",
				CornerRadius = UDim.new(0, Library.CornerPhases.Low),
				Parent = NotificationButton,
			})

			Library.New("UIPadding", {
				Name = "UIPadding",
				PaddingTop = UDim.new(0, 9),
				PaddingBottom = UDim.new(0, 9),
				PaddingLeft = UDim.new(0, 9),
				PaddingRight = UDim.new(0, 9),
				Parent = NotificationButton,
			})

			Library.New("TextLabel", {
				Name = "ActionText",
				ZIndex = 1,
				LayoutOrder = 0,
				Position = UDim2.new(-0.001, 0, 0.188, 0),
				Size = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 1,
				Text = Library.Get(Value, { "Title" }, "Action"),
				AutomaticSize = Enum.AutomaticSize.XY,
				Role = "Text",
				TextSize = 15,
				TextScaled = false,
				TextTransparency = 0.2,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				Parent = NotificationButton,
			})

			Library.New("UIListLayout", {
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
				Parent = NotificationButton,
			})

			NotificationButton.MouseEnter:Connect(function()
				Signal:Animate(
					NotificationButton,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ BackgroundTransparency = 0.9 }
				)
			end)

			NotificationButton.MouseLeave:Connect(function()
				Signal:Animate(
					NotificationButton,
					{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
					{ BackgroundTransparency = 0.95 }
				)
			end)

			local Callback = Signal:Callback(Library.Get(Value, { "Callback" }))

			NotificationButton.MouseButton1Click:Connect(function()
				if Library.Get(Value, { "DestroyOnClick" }) then
					RemoveFromQueue:Fire(Notification)
					return
				end

				Callback:Fire()
			end)
		end
	end

	--// Logic
	local Duration = Library.Get(Data, { "Duration" }, 3)
	local CloseType = Library.Get(Data, { "Close", "CloseType" }, "Body Click")
	local NotificationTransparency = Body.BackgroundTransparency

	Body.MouseEnter:Connect(function()
		Signal:Animate(
			Body,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = NotificationTransparency - 0.1 }
		)
	end)

	Body.MouseLeave:Connect(function()
		Signal:Animate(
			Body,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = NotificationTransparency }
		)
	end)

	if CloseType == "Button" then
		local Close = Library.New("ImageButton", {
			Name = "CloseIcon",
			ZIndex = 1,
			LayoutOrder = 5,
			Position = UDim2.new(1.000, 0, 0.500, 0),
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(1.000, 0.500),
			BackgroundTransparency = 1,
			Image = "rbxassetid://111236849679728",
			Role = "Icon",
			ImageTransparency = 0.5,
			Parent = IgnoreLayout,
		})

		Close.MouseButton1Click:Connect(function()
			RemoveFromQueue:Fire(Notification)
		end)

		Close.MouseEnter:Connect(function()
			Signal:Animate(
				Close,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ ImageTransparency = 0.2 }
			)
		end)

		Close.MouseLeave:Connect(function()
			Signal:Animate(
				Close,
				{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
				{ ImageTransparency = 0.5 }
			)
		end)
	else
		Body.MouseButton1Click:Connect(function()
			RemoveFromQueue:Fire(Notification)
		end)
	end

	AddToQueue:Fire(Notification)

	task.delay(Duration, function()
		RemoveFromQueue:Fire(Notification)
	end)
end

OnDestroy:Connect(function()
	Library.DisconnectAllConnections()
	Library.DisconnectAllSignals()
	Library.DestroyAll()
end)

task.delay(0.5, function()
	Library:SetTheme(ThemeManager.CurrentTheme.Name)
end)

return Library
