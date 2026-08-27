local Library = {}
Library.Instances = {}

Library.LibraryDebugs = true
Library.Hidden = false
Library.FontID = ""
Library.CurrentTheme = "Dark"

local Signal = {}
Signal.__index = Signal

local CloneReference = cloneref or clonereference or function(Object)
	return Object
end

local TweenService = CloneReference(game:GetService("TweenService")) :: TweenService
local RunService = CloneReference(game:GetService("RunService")) :: RunService
local Players = CloneReference(game:GetService("Players")) :: Players
local UserInputService = CloneReference(game:GetService("UserInputService")) :: UserInputService

local LocalPlayer = CloneReference(Players.LocalPlayer) :: Player

Library.IsStudio = RunService:IsStudio()

local Hui = (Library.IsStudio and game:GetService("Players").LocalPlayer.PlayerGui)
	or gethui and gethui()
	or CloneReference(game:GetService("CoreGui"))
local Protect = Library.IsStudio and (protectgui or syn and syn.protectgui) or function() end
local Global = Library.IsStudio and shared or getgenv()

if Global.OverlayInjected then
	Global.OverlayPrompt:Fire() --// TODO: Add Prompt
end

--// Signal
function Signal.New()
	local self = setmetatable({}, Signal)
	self.Connections = {}
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
	local Connection
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		Func(...)
	end)

	return Connection
end

function Signal:Fire(...)
	for _, Connection in ipairs(self.Connections) do
		if Connection.Connected then
			task.spawn(Connection.Func, ...)
		end
	end
end

function Signal:DisconnectAll()
	self.Connections = {}
end

function Signal:Debug(Input, Thread)
	if Library.LibraryDebugs then
		warn("[Library, " .. tostring(Thread) .. "]: ", tostring(Input))
	end
end

function Signal:Assert(Condition, Text, Thread)
	Thread = Thread or ""

	if not Condition then
		Signal:Debug(Text, Thread)
		return
	end
end

function Signal:MatchInput(Input, ...)
	local Targets = { ... }

	for _, Target in ipairs(Targets) do
		if Input.KeyCode == Target or Input.UserInputType == Target then
			return true
		end
	end

	return false
end

function Signal:Animate(Object, Info, Propriety)
	local TweenInfo = TweenInfo.new(Info.Time, Info.Style, Info.Direction)
	local Animation = TweenService:Create(Object, TweenInfo, Propriety)
	Animation:Play()

	return Animation, {
		Stop = function()
			Animation:Cancel()
		end,
	}
end

function Signal:Track(Object, OptionalTarget)
	Signal:Assert(Object, "No object input", "Track")

	local IsTextObject = Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")
	local IsImageObject = Object:IsA("ImageLabel") or Object:IsA("ImageButton")

	Signal:Assert(IsTextObject or IsImageObject, "Object is not a text or image instance", "TrackVisibility")

	local Content = IsTextObject and Object.Text or Object.Image
	Object.Visible = Content ~= nil and Content ~= ""

	if OptionalTarget then
		OptionalTarget.Visible = Content ~= nil and Content ~= ""
	end

	if IsTextObject then
		Object:GetPropertyChangedSignal("Text"):Connect(function()
			local Content = IsTextObject and Object.Text or Object.Image
			Object.Visible = Content ~= nil and Content ~= ""

			if OptionalTarget then
				OptionalTarget.Visible = Content ~= nil and Content ~= ""
			end
		end)
	else
		Object:GetPropertyChangedSignal("Image"):Connect(function()
			local Content = IsTextObject and Object.Text or Object.Image
			Object.Visible = Content ~= nil and Content ~= ""

			if OptionalTarget then
				OptionalTarget.Visible = Content ~= nil and Content ~= ""
			end
		end)
	end
end

function Signal:Callback(Func)
	Signal:Assert(type(Func) == "function", "Argument is not a function", "Callback")

	local Callback = Signal.New()

	Callback:Connect(function(Arg)
		return Func(Arg)
	end)

	return Callback
end

Library.Signal = Signal

--// Library Methods
function Library.SetLibraryDebugs(Bool)
	Library.LibraryDebugs = Bool
end

function Library.SetHidden(Bool)
	Library.Hidden = Bool
end

function Library.SetGlobal(Name, Value)
	Signal:Assert(Global, "No global env found")

	Global[Name] = Value
end

function Library.GetImage(Asset)
	if Asset:find("rbxassetid") then
		return Asset
	end
end

function Library.New(ClassName, Properties)
	local Success, Object = pcall(Instance.new, ClassName)
	if not Success then
		return nil
	end

	if ClassName == "TextButton" then
		Object.Text = ""
		Object.AutoButtonColor = false
	end

	if Properties then
		for Property, Value in pairs(Properties) do
			if Library.Hidden and Property == "Name" then
				continue
			end

			local SetSuccess = pcall(function()
				Object[Property] = Value
			end)

			Signal:Assert(SetSuccess, "Failed to set property: " .. tostring(Property), "Instance Creation")
		end
	end

	table.insert(Library.Instances, Object)
	return Object :: Instance
end

function Library.Destroy(Object)
	for Index, Instance in ipairs(Library.Instances) do
		if Instance == Object then
			table.remove(Library.Instances, Index)
			break
		end
	end

	Object:Destroy()
end

function Library.DestroyAll()
	for _, Object in ipairs(Library.Instances) do
		Object:Destroy()
	end

	Library.Instances = {}
end

function Library.SetupCommonElementBody(Data)
	local Body = {}

	local HoverStart = Signal.New()
	local HoverEnd = Signal.New()

	local ElementBody = Library.New("TextButton", {
		Name = "ElementBody",
		Position = UDim2.new(0, 0, 0.057, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Parent = Data.Parent,
	}) :: TextButton

	local TransparencyPhase = Data.Transparency

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

	Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = ElementBody })

	Library.New("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = ElementBody,
	})

	Library.New("UIStroke", {
		Transparency = Data.StrokeEnabled and (ElementBody.BackgroundTransparency - 0.025) or 1,
		Color = Color3.fromRGB(255, 255, 255),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		Parent = Header,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Icon })

	local IconDisplay = Library.New("ImageLabel", {
		Name = "IconDisplay",
		LayoutOrder = -1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.6, 0, 0.6, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = Data.Icon,
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
		Text = Data.Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
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
		Text = Data.Description,
		TextColor3 = Color3.fromRGB(255, 255, 255),
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
		MaxSize = Vector2.new(MaxX or math.huge, MaxY or math.huge),
		MinSize = Vector2.new(MinX or 0, MinY or 0),
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
			Connection:Disconnect()
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
			Connection:Disconnect()
		end

		Connection = RunService.Heartbeat:Connect(function(DeltaTime)
			local Alpha = 1 - math.exp(-SmoothSpeed * DeltaTime)
			Object.Position = Object.Position:Lerp(TargetPosition, Alpha)
		end)
	end)

	UserInputService.InputChanged:Connect(function(Input)
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
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if Dragging and Input.UserInputType == DragInputType then
			StopDragging()
		end
	end)

	return {
		DragStart = DragStart,
		DragChanged = DragChanged,
		DragEnd = DragEnd,
		IsDragging = function()
			return Dragging
		end,
	}
end

local OnDestroy = Signal.New()

--// Window
function Library:Window(Data)
	local Controller, Body = {}, {}
	local DragHoverStart = Signal.New()
	local DragHoverEnd = Signal.New()

	local UI = Library.New("ScreenGui", {
		Name = "UI",
		IgnoreGuiInset = true,
		Parent = Hui,
		DisplayOrder = 999,
	}) :: ScreenGui

	Protect(UI)
	local _UIScale = Library.New("UIScale", { Parent = UI, Scale = Data.UIScale or 1 }) :: UIScale
	local ContextMenus = Library.New("Folder", { Parent = UI })

	if not Library.IsStudio then
		if Global.sethiddenpropriety then
			Global.sethiddenpropriety(UI, "OnTopOfCoreBlur", true)
		end
	end

	Controller.SelectedTab = nil
	Controller.SelectedContainer = nil

	local Minimize = Signal.New()
	local UnMinimize = Signal.New()
	local SetProfileAnonimity = Signal.New()

	Controller.OnDestroy = OnDestroy
	Controller.OnMinimize = Minimize

	Controller.MinimizeKeybind = Data.MinimizeKeybind or Enum.KeyCode.RightShift
	Controller.IsMinimized = false

	local ActiveCloseThread = nil
	local CloseThread = Signal.New()

	local Window = Library.New("Frame", {
		Name = "Window",
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = Data.Size or UDim2.new(0, 700, 0, 500),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Data.BackgroundColor or Color3.fromRGB(9, 9, 9),
		BackgroundTransparency = Data.BackgroundTransparency or 0.1,
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
		Size = UDim2.new(0.300, 0, 0.000, 6),
		AnchorPoint = Vector2.new(0.500, 0.000),
		AutomaticSize = Enum.AutomaticSize.None,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Rotation = 0,
		Active = false,
		Selectable = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		BorderMode = Enum.BorderMode.Outline,
		ClipsDescendants = false,
		Transparency = 0.9,
		Parent = IgnoreLayout,
	})

	DragBar:SetAttribute("Ignore", true)
	local DragMechanic = Library.SetDraggable(Window, DragBar)
	local DragHover = false

	DragHoverStart:Connect(function()
		DragHover = true

		Signal:Animate(
			DragBar,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = 0.6 }
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
			{ BackgroundTransparency = 0.9 }
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
	Body = Window

	Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = Window })
	Controller.WindowSize = Data.Size or Window.Size or UDim2.new(0, 700, 0, 500)
	Controller.WindowTransparency = Data.Transparency or Window.Transparency or 0.1

	Library.New("UIStroke", {
		Transparency = 0.9,
		Color = Color3.fromRGB(255, 255, 255),
		Parent = Window,
	})

	local TopRight = Library.New("ImageLabel", {
		Name = "TopRight",
		ZIndex = -1,
		Position = UDim2.new(0, 1, 0, -1),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://136612025197923",
		ImageColor3 = Color3.fromRGB(255, 0, 0),
		ImageTransparency = 1,
		Parent = IgnoreLayout,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = TopRight })

	local TopLeft = Library.New("ImageLabel", {
		Name = "TopLeft",
		ZIndex = -1,
		Position = UDim2.new(0, -1, 0, -1),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://90085857557952",
		ImageColor3 = Color3.fromRGB(158, 1, 255),
		ImageTransparency = 1,
		Parent = IgnoreLayout,
	})

	Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = TopLeft })

	local BackgroundImage = Library.New("ImageLabel", {
		Name = "BackgroundImage",
		ZIndex = -1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://82295031952284",
		ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Crop,
		Parent = IgnoreLayout,
	}) :: ImageLabel

	BackgroundImage:SetAttribute("Ignore", true)
	Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = BackgroundImage })

	local MainOverlay = Library.New("Frame", {
		Name = "MainOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Window,
	})

	Library.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Wraps = true,
		Parent = Window,
	})

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
		Text = Data.Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
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
		Text = Data.SubTitle,
		TextColor3 = Color3.fromRGB(255, 255, 255),
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

	function Controller:Tab(Data)
		local Elements = {}

		local Tab = Library.New("TextButton", {
			Name = "Tab",
			Position = UDim2.new(0.075, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

		Library.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Tab })
		Library.New("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = Tab,
		})

		Library.New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Parent = Tab, Transparency = 1 })

		local IconDisplay = Library.New("ImageLabel", {
			Name = "Icon",
			LayoutOrder = 1,
			Position = UDim2.new(-0.005, 0, 0, 0),
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 1,
			Image = Data.Icon,
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
			Text = Data.Title,
			TextColor3 = Color3.fromRGB(220, 220, 220),
			TextSize = 16,
			TextTransparency = 0.2,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold),
			Parent = Tab,
		})

		local Container = Library.New("ScrollingFrame", {
			Name = Data.Title,
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
				Text = Data and (Data.Title or Data.Name) or "Section",
				TextColor3 = Color3.fromRGB(255, 255, 255),
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
				TextColor3 = Color3.fromRGB(255, 255, 255),
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
				Image = Data and Data.Icon,
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
			local Methods = {}
			local Body = Library.SetupCommonElementBody({
				Title = Data and (Data.Title or Data.Name) or "Toggle",
				Description = Data and (Data.Desc or Data.Description) or "Description",
				Icon = Data and (Data.Icon or Data.Image) or "",
				StrokeEnabled = Data and Data.StrokeEnabled or false,
				Transparency = Data and (Data.Transparency or Data.TransparencyPhase) or "Min",
				Parent = Container,
			})

			local Interaction = Body.Interaction
			local Header = Body.Header

			Header.Size = UDim2.fromScale(0.8, 0)
			Interaction.Size = UDim2.fromScale(0.2, 0)

			local Toggle = Library.New("TextButton", {
				Name = "Toggle",
				Size = UDim2.new(0, 50, 0, 24),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

			local Value = Data.Value or Data.Toggled or false
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

			function Methods:Set(Value)
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
			local Methods = {}
			local Body = Library.SetupCommonElementBody({
				Title = Data and (Data.Title or Data.Name) or "Toggle",
				Description = Data and (Data.Desc or Data.Description) or "Description",
				Icon = Data and (Data.Icon or Data.Image) or "",
				StrokeEnabled = Data and Data.StrokeEnabled or false,
				Transparency = Data and (Data.Transparency or Data.TransparencyPhase) or "Min",
				Parent = Container,
			})

			local Interaction = Body.Interaction
			local Header = Body.Header

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

			Library.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = NumberPlate })

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
				Text = tostring(Data.Value),
				TextColor3 = Color3.fromRGB(255, 255, 255),
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

			Library.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Slider })

			local Percent = Library.New("Frame", {
				Name = "Percent",
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundTransparency = 0.2,
				Parent = Slider,
			})

			Library.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Percent })

			--// Logic
			local Max = Data and (Data.Max or Data.MaximumValue) or 100
			local Min = Data and (Data.Min or Data.MinimumValue) or 0
			local Step = Data and (Data.Step or Data.Threshold) or 1
			local Value = Data and (Data.Default or Data.Value) or Min
			local SmoothSlide = Data and (Data.SmoothSlide or Data.Animate) or false

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

			UserInputService.InputChanged:Connect(function(Input)
				if not Dragging then
					return
				end

				if
					Input.UserInputType == Enum.UserInputType.MouseMovement
					or Input.UserInputType == Enum.UserInputType.Touch
				then
					ApplyValue(ValueFromAlpha(AlphaFromInput(Input.Position.X)), true)
				end
			end)

			UserInputService.InputEnded:Connect(function(Input)
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
			end)

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
			local Methods = {}
			local Body = Library.SetupCommonElementBody({
				Title = Data and (Data.Title or Data.Name) or "Toggle",
				Description = Data and (Data.Desc or Data.Description) or "Description",
				Icon = Data and (Data.Icon or Data.Image) or "",
				StrokeEnabled = Data and (Data.StrokeEnabled or Data.Stroke) or false,
				Transparency = Data and (Data.Transparency or Data.TransparencyPhase) or "Min",
				Parent = Container,
			})

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			Header.Size = UDim2.fromScale(0.85, 0)
			Interaction.Size = UDim2.fromScale(0.15, 0)

			local ButtonHeading = Data and (Data.ButtonClass or Data.HeadingButton) or "Icon"

			if ButtonHeading == "Icon" then
				local ButtonHolder = Library.New("Frame", {
					Name = "Button",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 1,
					Position = UDim2.new(0.000, 0, 0.000, 0),
					Size = UDim2.new(0.000, 30, 0.000, 30),
					AnchorPoint = Vector2.new(0.000, 0.000),
					AutomaticSize = Enum.AutomaticSize.None,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BorderMode = Enum.BorderMode.Outline,
					ClipsDescendants = false,
					Transparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/SourceSansPro.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					),
					RichText = false,
					Parent = Interaction,
				})

				Library.New("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0.000, 12),
					Parent = ButtonHolder,
				})

				Library.New("ImageLabel", {
					Name = "Icon",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 0,
					Position = UDim2.new(0.500, 0, 0.500, 0),
					Size = UDim2.new(0.000, 25, 0.000, 25),
					AnchorPoint = Vector2.new(0.500, 0.500),
					AutomaticSize = Enum.AutomaticSize.None,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
					Active = false,
					Selectable = false,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BorderMode = Enum.BorderMode.Outline,
					ClipsDescendants = false,
					Transparency = 1,
					Image = Data and (Data.ButtonIcon or Data.HeadingIcon) or "rbxassetid://72922480325213",
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					ImageTransparency = 0.2,
					ScaleType = Enum.ScaleType.Stretch,
					SliceCenter = Rect.new(0.000, 0.000, 0.000, 0.000),
					SliceScale = 1,
					TileSize = UDim2.new(1.000, 0, 1.000, 0),
					ImageRectOffset = Vector2.new(0.000, 0.000),
					ImageRectSize = Vector2.new(0.000, 0.000),
					ResampleMode = Enum.ResamplerMode.Default,
					Parent = ButtonHolder,
				})
			else
				Library.New("TextLabel", {
					Name = "ButtonWatermark",
					Visible = true,
					ZIndex = 1,
					LayoutOrder = 0,
					Position = UDim2.new(0.000, 0, 0.000, 0),
					Size = UDim2.new(0.000, 0, 0.000, 0),
					AnchorPoint = Vector2.new(0.000, 0.000),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = false,
					BackgroundTransparency = 1,
					Text = Data and (Data.ButtonText or Data.HeadingText) or "Button",
					TextColor3 = Color3.fromRGB(255, 255, 255),
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

			return Methods
		end

		function Elements:Dropdown(Data)
			local Methods = {}
			local Body = Library.SetupCommonElementBody({
				Title = Data and (Data.Title or Data.Name) or "Toggle",
				Description = Data and (Data.Desc or Data.Description) or "Description",
				Icon = Data and (Data.Icon or Data.Image) or "",
				StrokeEnabled = Data and (Data.StrokeEnabled or Data.Stroke) or false,
				Transparency = Data and (Data.Transparency or Data.TransparencyPhase) or "Min",
				Parent = Container,
			})

			local Interaction = Body.Interaction
			local ElementBody = Body.ElementBody
			local Header = Body.Header

			Header.Size = UDim2.fromScale(0.6, 0)
			Interaction.Size = UDim2.fromScale(0.4, 0)

			local DropdownPlate = Library.New("Frame", {
				Name = "DropdownPlate",
				Size = UDim2.new(0, 0, 0, 35),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.95,
				LayoutOrder = 1,
				Parent = Interaction,
			}) :: Frame

			Library.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = DropdownPlate })
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
				TextColor3 = Color3.fromRGB(255, 255, 255),
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
				Library.New("ImageLabel", {
					Name = "Icon",
					Size = UDim2.new(0, 20, 0, 20),
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Image = type(Data.DropdownIcon) == "string" and Data.DropdownIcon or "rbxassetid://10709797508",
					ImageTransparency = 0.2,
					Parent = DropdownPlate,
				})
			end

			--// Logic
			local Values = Data and (Data.Values or Data.Table or Data.Index) or {}
			local Value = Data and (Data.Value or Data.Default) or nil
			local Multi = Data and (Data.Multi or Data.Multiple) or false
			local CloseOnSelection = Data and (Data.CloseOnSelection or Data.CloseWhenSelected) or false
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

				local ContextMenu = Library.New("Frame", {
					Name = "ContextMenu",
					Visible = true,
					Position = UDim2.fromOffset(X, Y),
					Size = UDim2.new(0, 175, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(9, 9, 9),
					BackgroundTransparency = 0.1,
					Parent = ContextMenus,
					ZIndex = 2,
				})

				InputConnection = UserInputService.InputBegan:Connect(function(Input)
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
							CloseThread:Fire()
							InputConnection:Disconnect()
							ActiveCloseThread:Disconnect()
						end
					end
				end)

				Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = ContextMenu })

				ActiveCloseThread = CloseThread:Connect(function()
					for _, Button in ipairs(ContextMenu:GetChildren()) do
						if Button:IsA("TextButton") then
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
				end)

				for _, String in Data do
					local ValueButton = Library.New("TextButton", {
						Name = String,
						Position = UDim2.new(0.075, 0, 0, 0),
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
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
						TextColor3 = Color3.fromRGB(220, 220, 220),
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

					Library.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = ValueButton })
					Library.New("UIListLayout", { Padding = UDim.new(0, 3), Parent = ContextMenu })

					Library.New("UIPadding", {
						PaddingTop = UDim.new(0, 6),
						PaddingBottom = UDim.new(0, 6),
						PaddingLeft = UDim.new(0, 6),
						PaddingRight = UDim.new(0, 6),
						Parent = ContextMenu,
					})

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

		function Elements:Section(Data)
			local Methods = {}
			local Body = Library.SetupCommonElementBody({
				Title = Data and (Data.Title or Data.Name) or "Toggle",
				Description = Data and (Data.Desc or Data.Description) or "Description",
				Icon = Data and (Data.Icon or Data.Image) or "",
				StrokeEnabled = Data and (Data.StrokeEnabled or Data.Stroke) or false,
				Transparency = Data and (Data.Transparency or Data.TransparencyPhase) or "Min",
				Parent = Container,
			})

			local Interaction = Body.Interaction :: Frame
			local Header = Body.Header :: Frame
			local ElementBody = Body.ElementBody :: TextButton

			ElementBody:FindFirstChildOfClass("UIListLayout").Wraps = true

			Header.Size = UDim2.fromScale(0.9, 0)
			Interaction.Size = UDim2.fromScale(0.08, 0)

			local Class = Data and (Data.Class or Data.Type) or "Normal"
			local Chevron = nil

			if Class == "Toggle" then
				--// Copy of toggle logic

				Header.Size = UDim2.fromScale(0.8, 0)
				Interaction.Size = UDim2.fromScale(0.18, 0)

				local Toggle = Library.New("TextButton", {
					Name = "Toggle",
					Size = UDim2.new(0, 50, 0, 24),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

				local Value = Data.Value or Data.Toggled or false
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

				function Methods:Set(Value)
					Callback:Fire(Value)

					if Value then
						AnimateOn:Fire()
					else
						AnimateOff:Fire()
					end
				end
			else
				Library.New("ImageLabel", {
					Name = "Chevron",
					LayoutOrder = 5,
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 22, 0, 22),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://109320394183701",
					ImageTransparency = 0.4,
					Rotation = 180,
					Parent = Interaction,
				})
			end

			--// Logic
			local Open = Signal.New()
			local Close = Signal.New()

			local Opened = Data and Data.Opened or false
			local Animating = false

			Open:Connect(function()
				if Animating then
					return
				end

				Animating = true

				if Chevron then
					Signal:Animate(
						Chevron,
						{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
						{ Rotation = 0 }
					)
				end

				for _, Element in ipairs(Body.ElementBody:GetChildren()) do
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
							Animating = false
						end)

						task.wait(0.1)
						Tab.AutomaticSize = Enum.AutomaticSize.Y
						Tab.ClipsDescendants = false
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

				for _, Element in ipairs(ElementBody:GetChildren()) do
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
								Animating = false
							end)

							task.wait(0.1)
							Element.Visible = false
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
				local Children, Bodies = 0, {}

				for _, Element in ipairs(ElementBody:GetChildren()) do
					if Element:IsA("TextButton") then
						Children = Children + 1
						table.insert(Bodies, Element)
					end
				end

				return Children, Bodies
			end

			local function SetChildrenCorners()
				local Children, Bodies = GetElements()

				if Children > 1 then
					for Index, Object in ipairs(Bodies) do
						local Corner = Object:FindFirstChildOfClass("UICorner")
						if Corner then
							if Children == 2 then
								if Index == 1 then
									Corner.BottomLeftRadius = UDim.new(0, 5)
									Corner.BottomRightRadius = UDim.new(0, 5)
								elseif Index == 2 then
									Corner.TopLeftRadius = UDim.new(0, 5)
									Corner.TopRightRadius = UDim.new(0, 5)
								end
							elseif Children > 2 then
								if Index == 1 then
									Corner.BottomLeftRadius = UDim.new(0, 5)
									Corner.BottomRightRadius = UDim.new(0, 5)
								elseif Index > 1 and Index < Children then
									Corner.CornerRadius = UDim.new(0, 5)
								elseif Index == Children then
									Corner.TopLeftRadius = UDim.new(0, 5)
									Corner.TopRightRadius = UDim.new(0, 5)
								end
							end
						end
					end
				end
			end

			function Methods:Toggle(Args)
				local Element, MethodBody = Elements:Toggle({
					Title = Args and (Args.Title or Args.Name) or "Toggle",
					Description = Args and (Args.Desc or Args.Description) or "Description",
					Icon = Args and (Args.Icon or Args.Image) or "",
					Callback = Args.Callback,
				})

				MethodBody.ElementBody.Parent = Body.ElementBody
				return Element
			end

			function Methods:Slider(Args)
				local Element, MethodBody = Elements:Slider({
					Title = Args and (Args.Title or Args.Name) or "Toggle",
					Description = Args and (Args.Desc or Args.Description) or "Description",
					Icon = Args and (Args.Icon or Args.Image) or "",
					Max = Args and (Args.Max or Args.MaximumValue) or 0,
					Min = Args and (Args.Min or Args.MinimumValue) or 0,
					Step = Args and (Args.Step or Args.Threshold) or 0,
					Value = Args and (Args.Value or Args.Default) or (Args.Min or Args.MinimumValue) or 0,
					Callback = Args.Callback,
				})

				MethodBody.ElementBody.Parent = Body.ElementBody
				return Element
			end

			function Methods:Dropdown(Args)
				local Element, MethodBody = Elements:Dropdown({
					Title = Args and (Args.Title or Args.Name) or "Toggle",
					Description = Args and (Args.Desc or Args.Description) or "Description",
					Icon = Args and (Args.Icon or Args.Image) or "",
					Multi = Args and (Args.Multi or Args.Multiple) or false,
					Values = Args and (Args.Values or Args.Table) or {},
					Value = Args and (Args.Value or Args.Default) or nil,
					DropdownIcon = Args and Args.DropdownIcon or "",
					Callback = Args.Callback,
				})

				MethodBody.ElementBody.Parent = Body.ElementBody
				return Element
			end

			SetChildrenCorners()

			ElementBody.ChildAdded:Connect(function(Child)
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

		return Elements, Tab, Container
	end

	function Controller:Section(Data)
		local TabController = {}
		local Section = Library.New("Frame", {
			Name = "Section",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

		Library.New("UICorner", { CornerRadius = UDim.new(0, 15), Parent = Section })

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
			Text = Data and (Data.Title or Data.Name) or "Section",
			TextColor3 = Color3.fromRGB(220, 220, 220),
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
			Image = Data and (Data.Icon or Data.Image) or "",
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
			Image = "rbxassetid://109320394183701",
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
		local Opened = Data and Data.Opened or false

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
			local _, Body = Controller:Tab({
				Title = Data and (Data.Title or Data.Name) or "Tab",
				Description = Data and (Data.Description or Data.Desc) or "Description",
				Icon = Data and (Data.Icon or Data.Image) or "",
				Section = Data and Data.Section,
			})

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

	function Controller:SetBackgroundImage(Image)
		BackgroundImage.Image = tostring(Image)
	end

	function Controller:SetBackgroundImageTransparency(Transparency)
		Signal:Assert(type(Transparency) == "number", "Argument is not a number")

		BackgroundImage.ImageTransparency = Transparency
	end

	function Controller:NewTopbarButton(Data)
		local Button = Library.New("TextButton", {
			Name = "Button",
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			Parent = Right,
			LayoutOrder = Data.Order,
		})

		Library.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Button })

		Library.New("ImageLabel", {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = Data.Icon,
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
		local InteractionButton = Library.New("TextButton", {
			Name = "Button",
			LayoutOrder = Data.Order,
			Size = UDim2.new(0, 35, 0, 35),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
			Text = "",
			Parent = Interaction,
		})

		Library.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = InteractionButton })

		Library.New("ImageLabel", {
			Name = "Icon",
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 20, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = Data.Icon,
			ImageTransparency = 0.4,
			Parent = InteractionButton,
		})

		local Callback = Signal.New()
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

		Callback:Connect(Data.Callback)

		return InteractionButton
	end

	function Controller:SetWindowSize(Size)
		Signal:Assert(typeof(Size) == "UDim2", "Invalid typeof size, Expected UDim2", "SetWindowSize")

		Signal:Animate(
			Window,
			{ Time = 0.2, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
			{ Size = Size }
		)

		Controller.WindowSize = Size
	end

	function Controller:SetUIScale(Scale)
		Signal:Assert(Scale and type(Scale) == "number", "Scale argument is not valid", "Set UI Scale")

		_UIScale.Scale = Scale
	end

	function Controller:SetWindowTransparency(Transparency)
		Signal:Assert(type(Transparency) == "number", "Argument is not a number")

		Signal:Animate(
			Window,
			{ Time = 0.25, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ BackgroundTransparency = Transparency }
		)

		Controller.WindowTransparency = Transparency
	end

	function Controller:SetMinimizeKeybind(Keybind)
		Signal:Assert(Keybind and typeof(Keybind) == "Enum", "Invalid keybind arg", "SetMinimizeKeybind")
		Controller.MinimizeKeybind = Keybind
	end

	function Controller:MinimizeWindow()
		Minimize:Fire()
	end

	function Controller:UnMinimizeWindow()
		UnMinimize:Fire()
	end

	function Controller:Destroy()
		OnDestroy:Fire()
	end

	Library.InUseOverlay = MainOverlay
	Minimize:Connect(function()
		Signal:Assert(Library.InUseOverlay, "No overlay found", "MinimizeLogic")
		Library.InUseOverlay.Visible = false

		Signal:Animate(Window, { Time = 0.3, Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.In }, {
			Size = UDim2.fromOffset(Controller.WindowSize.X.Offset - 20, Controller.WindowSize.Y.Offset - 20),
			BackgroundTransparency = 1,
		})

		Signal:Animate(
			Window:FindFirstChildOfClass("UIStroke"),
			{ Time = 0.3, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.In },
			{ Transparency = 1 }
		)

		task.delay(0.3, function()
			Window.Visible = false
		end)
	end)

	UnMinimize:Connect(function()
		Signal:Assert(Library.InUseOverlay, "No overlay found", "MinimizeLogic")
		Window.Visible = true
		Window.BackgroundTransparency = 1

		Signal:Animate(
			Window,
			{ Time = 0.35, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
			{ Size = Controller.WindowSize, BackgroundTransparency = Controller.WindowTransparency }
		)

		Signal:Animate(
			Window:FindFirstChildOfClass("UIStroke"),
			{ Time = 0.35, Style = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.Out },
			{ Transparency = 0.9 }
		)

		task.delay(0.2, function()
			Library.InUseOverlay.Visible = true
		end)
	end)

	UserInputService.InputBegan:Connect(function(Input, Procesed)
		if Procesed then
			return
		end

		if Signal:MatchInput(Input, Controller.MinimizeKeybind) then
			Controller.IsMinimized = not Controller.IsMinimized

			if Controller.IsMinimized then
				Controller:MinimizeWindow()
			else
				Controller:UnMinimizeWindow()
			end
		end
	end)

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
			Controller.IsMinimized = not Controller.IsMinimized

			if Controller.IsMinimized then
				Controller:MinimizeWindow()
			else
				Controller:UnMinimizeWindow()
			end
		end,
	})

	--[[Controller:NewTopbarButton({ --// FullScreen
		Order = 999,
		Icon = "rbxassetid://10747384394",
		Callback = function()
			Controller:Destroy()
		end,
	})]]

	if Data.Profile then
		local Profile = Library.New("Frame", {
			Name = "Profile",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0.15, 0),
			BackgroundTransparency = Data.Profile.Transparent and 1 or 0.95,
			BorderSizePixel = 0,
			Parent = Sidebar,
		})

		Library.NewSizeConstraint(Profile, 200, 70)
		Library.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Profile })

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

		if not Data.Profile.Transparent then
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
			Image = Data.Profile.AnonymousScreenshot
					and Players:GetUserThumbnailAsync(1, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				or Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size420x420
				),
			Parent = Profile,
		})

		ProfileIcon:SetAttribute("Ignore", true)

		Library.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProfileIcon })
		Library.New("UIStroke", {
			Transparency = 0.9,
			Color = Color3.fromRGB(255, 255, 255),
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
			Text = Data.Profile.DisplayAnonym and "Anonymous" or tostring(LocalPlayer.DisplayName),
			TextColor3 = Color3.fromRGB(255, 255, 255),
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
			Text = Data.Profile.UserAnonym and "@Anonymous" or "@" .. tostring(LocalPlayer.Name),
			TextColor3 = Color3.fromRGB(255, 255, 255),
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

	Controller:MinimizeWindow()

	task.delay(0.5, function()
		if not Data.Minimized then
			Controller:UnMinimizeWindow()
		end
	end)

	return Controller, Body
end

function Library:Notify() end

OnDestroy:Connect(function()
	Signal:DisconnectAll()
	Library.DestroyAll()
end)

return Library
