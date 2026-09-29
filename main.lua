local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local STUDIO_ONLY = false
local MAX_LOGS = 200
local TOGGLE_KEY = Enum.KeyCode.RightShift

if STUDIO_ONLY and not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer

---------------------------------------------------------------------
-- Theme + helpers
---------------------------------------------------------------------

local THEME = {
	window  = Color3.fromRGB(22, 22, 30),
	titleBar = Color3.fromRGB(28, 28, 38),
	panel   = Color3.fromRGB(30, 30, 41),
	row     = Color3.fromRGB(40, 40, 54),
	button  = Color3.fromRGB(44, 44, 60),
	stroke  = Color3.fromRGB(58, 58, 78),
	text    = Color3.fromRGB(232, 232, 242),
	muted   = Color3.fromRGB(135, 135, 160),
	accent  = Color3.fromRGB(124, 108, 255),
	out     = Color3.fromRGB(96, 214, 145),
	inc     = Color3.fromRGB(95, 165, 255),
	danger  = Color3.fromRGB(232, 92, 104),
}

local FONT = Enum.Font.Gotham
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function make(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, thickness)
	return make("UIStroke", {
		Color = color or THEME.stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(px)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px),
	})
end

local function lighten(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount or 0.08)
end

local function tween(inst, props, time)
	TweenService:Create(inst, TweenInfo.new(time or 0.12, Enum.EasingStyle.Quad), props):Play()
end

local function addHover(button, baseColor)
	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = lighten(baseColor) })
	end)
	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = baseColor })
	end)
end

---------------------------------------------------------------------
-- Build the GUI
---------------------------------------------------------------------

local gui = make("ScreenGui", {
	Name = "RemoteSpy",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local WINDOW_SIZE = UDim2.fromOffset(660, 410)

local window = make("Frame", {
	Name = "main frame",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = WINDOW_SIZE,
	BackgroundColor3 = THEME.window,
	ClipsDescendants = true,
	Parent = gui,
}, { corner(10), stroke() })

-- Title bar
local titleBar = make("Frame", {
	Name = "titleBar",
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = THEME.titleBar,
	Active = true,
	Parent = window,
}, { corner(10) })

-- square off the bottom corners of the title bar
make("Frame", {
	Size = UDim2.new(1, 0, 0, 10),
	Position = UDim2.new(0, 0, 1, -10),
	BackgroundColor3 = THEME.titleBar,
	BorderSizePixel = 0,
	Parent = titleBar,
})

make("Frame", {
	Name = "accentDot",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(10, 10),
	BackgroundColor3 = THEME.accent,
	Parent = titleBar,
}, { corner(5) })

make("TextLabel", {
	Name = "title",
	Position = UDim2.fromOffset(32, 0),
	Size = UDim2.new(0, 220, 1, 0),
	BackgroundTransparency = 1,
	Font = FONT_BOLD,
	TextSize = 15,
	Text = "Maz's Remote Spy",
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBar,
})

local statusLabel = make("TextLabel", {
	Name = "status",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -84, 0, 0),
	Size = UDim2.new(0, 240, 1, 0),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 12,
	Text = "0 logs",
	TextColor3 = THEME.muted,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = titleBar,
})

local function titleButton(name, text, xOffset, hoverColor)
	local btn = make("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = THEME.button,
		AutoButtonColor = false,
		Font = FONT_BOLD,
		TextSize = 14,
		Text = text,
		TextColor3 = THEME.muted,
		Parent = titleBar,
	}, { corner(6) })
	btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = hoverColor, TextColor3 = THEME.text }) end)
	btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = THEME.button, TextColor3 = THEME.muted }) end)
	return btn
end

local closeButton = titleButton("close", "X", -10, THEME.danger)
local minimizeButton = titleButton("minimize", "-", -42, lighten(THEME.button, 0.15))

-- Body
local body = make("Frame", {
	Name = "body",
	Position = UDim2.fromOffset(12, 52),
	Size = UDim2.new(1, -24, 1, -64),
	BackgroundTransparency = 1,
	Parent = window,
})

-- Left: remote list
local LIST_WIDTH = 220

make("TextLabel", {
	Size = UDim2.new(0, LIST_WIDTH, 0, 18),
	BackgroundTransparency = 1,
	Font = FONT_BOLD,
	TextSize = 11,
	Text = "REMOTES",
	TextColor3 = THEME.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = body,
})

local logList = make("ScrollingFrame", {
	Name = "remotes",
	Position = UDim2.fromOffset(0, 22),
	Size = UDim2.new(0, LIST_WIDTH, 1, -22),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.stroke,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = body,
}, {
	corner(8),
	stroke(),
	padding(6),
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}),
})

local emptyLabel = make("TextLabel", {
	Name = "empty",
	LayoutOrder = 1e9,
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 12,
	Text = "Waiting for remotes...",
	TextColor3 = THEME.muted,
	Parent = logList,
})

-- Right side
local right = make("Frame", {
	Name = "right",
	Position = UDim2.fromOffset(LIST_WIDTH + 12, 0),
	Size = UDim2.new(1, -(LIST_WIDTH + 12), 1, 0),
	BackgroundTransparency = 1,
	Parent = body,
})

local BUTTON_AREA = 84

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	Font = FONT_BOLD,
	TextSize = 11,
	Text = "DATA",
	TextColor3 = THEME.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = right,
})

local codeFrame = make("ScrollingFrame", {
	Name = "code",
	Position = UDim2.fromOffset(0, 22),
	Size = UDim2.new(1, 0, 1, -(22 + BUTTON_AREA + 10)),
	BackgroundColor3 = Color3.fromRGB(18, 18, 25),
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.stroke,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = right,
}, { corner(8), stroke() })

local codeBox = make("TextBox", {
	Name = "codeText",
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.new(1, -20, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ClearTextOnFocus = false,
	TextEditable = true,
	MultiLine = true,
	TextWrapped = true,
	Font = Enum.Font.Code,
	TextSize = 13,
	TextColor3 = THEME.text,
	PlaceholderColor3 = THEME.muted,
	PlaceholderText = "Click a remote to see the data it sent",
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = codeFrame,
})

local functions = make("Frame", {
	Name = "functions",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, BUTTON_AREA),
	BackgroundTransparency = 1,
	Parent = right,
}, {
	make("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellSize = UDim2.new(1 / 3, -4, 0.5, -3),
		CellPadding = UDim2.fromOffset(6, 6),
	}),
})

local function actionButton(name, text, order, color)
	local base = color or THEME.button
	local btn = make("TextButton", {
		Name = name,
		LayoutOrder = order,
		BackgroundColor3 = base,
		AutoButtonColor = false,
		Font = FONT_MEDIUM,
		TextSize = 13,
		Text = text,
		TextColor3 = THEME.text,
		Parent = functions,
	}, { corner(7), stroke() })
	addHover(btn, base)
	return btn
end

actionButton("copy", "Copy", 1)
actionButton("run", "Replicate", 2, THEME.accent)
actionButton("ignore", "Ignore", 3)
actionButton("unignore", "Unignore", 4)
actionButton("unignore all", "Unignore All", 5)
actionButton("clear logs", "Clear Logs", 6, Color3.fromRGB(92, 44, 54))

---------------------------------------------------------------------
-- Window behaviour: drag, minimize, close, toggle key
---------------------------------------------------------------------

do
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	tween(window, {
		Size = minimized and UDim2.fromOffset(WINDOW_SIZE.X.Offset, 40) or WINDOW_SIZE,
	}, 0.18)
end)

closeButton.MouseButton1Click:Connect(function()
	window.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == TOGGLE_KEY then
		window.Visible = not window.Visible
	end
end)

---------------------------------------------------------------------
-- Serialization: turn values into Lua source
---------------------------------------------------------------------

local function quoteName(name)
	if name:match("^[%a_][%w_]*$") then
		return "." .. name
	end
	return string.format("[%q]", name)
end

local function instancePath(inst)
	if inst == game then return "game" end
	if inst == workspace then return "workspace" end

	local chain = {}
	local current = inst
	while current and current.Parent ~= game do
		table.insert(chain, 1, current)
		current = current.Parent
	end
	if not current then
		return "nil --[[ " .. inst:GetFullName() .. " (not in game) ]]"
	end

	local ok, service = pcall(function()
		return game:GetService(current.ClassName)
	end)
	local root
	if ok and service == current then
		root = string.format('game:GetService("%s")', current.ClassName)
	else
		root = "game" .. quoteName(current.Name)
	end

	for _, child in ipairs(chain) do
		root ..= quoteName(child.Name)
	end
	return root
end

local serialize

local function serializeTable(t, indent, seen)
	if seen[t] then return "{} --[[ cyclic ]]" end
	seen[t] = true

	local pad = string.rep("    ", indent + 1)
	local lines = {}
	local n = #t

	for i = 1, n do
		table.insert(lines, pad .. serialize(t[i], indent + 1, seen))
	end
	for k, v in pairs(t) do
		if not (type(k) == "number" and k >= 1 and k <= n and k % 1 == 0) then
			local key
			if type(k) == "string" and k:match("^[%a_][%w_]*$") then
				key = k
			else
				key = "[" .. serialize(k, indent + 1, seen) .. "]"
			end
			table.insert(lines, pad .. key .. " = " .. serialize(v, indent + 1, seen))
		end
	end

	seen[t] = nil
	if #lines == 0 then return "{}" end
	return "{\n" .. table.concat(lines, ",\n") .. "\n" .. string.rep("    ", indent) .. "}"
end

serialize = function(v, indent, seen)
	indent = indent or 0
	seen = seen or {}
	local t = typeof(v)

	if t == "nil" then return "nil"
	elseif t == "string" then return string.format("%q", v)
	elseif t == "number" then
		if v ~= v then return "0/0" end
		if v == math.huge then return "math.huge" end
		if v == -math.huge then return "-math.huge" end
		return tostring(v)
	elseif t == "boolean" then return tostring(v)
	elseif t == "table" then return serializeTable(v, indent, seen)
	elseif t == "Instance" then return instancePath(v)
	elseif t == "Vector3" then return string.format("Vector3.new(%s, %s, %s)", v.X, v.Y, v.Z)
	elseif t == "Vector2" then return string.format("Vector2.new(%s, %s)", v.X, v.Y)
	elseif t == "CFrame" then return "CFrame.new(" .. table.concat({ v:GetComponents() }, ", ") .. ")"
	elseif t == "Color3" then return string.format("Color3.new(%s, %s, %s)", v.R, v.G, v.B)
	elseif t == "UDim" then return string.format("UDim.new(%s, %s)", v.Scale, v.Offset)
	elseif t == "UDim2" then
		return string.format("UDim2.new(%s, %s, %s, %s)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
	elseif t == "EnumItem" then return tostring(v)
	elseif t == "BrickColor" then return string.format("BrickColor.new(%q)", v.Name)
	else
		return "nil --[[ " .. t .. ": " .. tostring(v) .. " ]]"
	end
end

local function buildCode(entry)
	local path = instancePath(entry.remote)
	local lines = {
		"-- " .. entry.remote.Name .. "  |  " .. entry.method .. "  |  " .. entry.time,
		"",
	}

	local argNames = {}
	for i = 1, entry.args.n do
		table.insert(lines, string.format("local arg%d = %s", i, serialize(entry.args[i])))
		table.insert(argNames, "arg" .. i)
	end
	if entry.args.n == 0 then
		table.insert(lines, "-- (no data sent)")
	end
	table.insert(lines, "")

	if entry.method == "OnClientEvent" then
		table.insert(lines, "-- sent by the server to you on " .. path)
	else
		table.insert(lines, string.format("%s:%s(%s)", path, entry.method, table.concat(argNames, ", ")))
	end
	return table.concat(lines, "\n")
end

---------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------

local ignored = {}   -- [remote] = true
local entries = {}   -- list of { remote, method, args, time, row, outline }
local selected = nil
local order = 0

local statusToken = 0
local function updateCount()
	statusLabel.TextColor3 = THEME.muted
	statusLabel.Text = #entries .. (#entries == 1 and " log" or " logs")
	emptyLabel.Visible = #entries == 0
end

local function flash(msg, color)
	statusToken += 1
	local token = statusToken
	statusLabel.Text = msg
	statusLabel.TextColor3 = color or THEME.accent
	task.delay(1.6, function()
		if token == statusToken then updateCount() end
	end)
end

local function setSelected(entry)
	if selected and selected.outline then
		selected.outline.Enabled = false
	end
	selected = entry
	if entry then
		if entry.outline then entry.outline.Enabled = true end
		codeBox.Text = buildCode(entry)
	else
		codeBox.Text = ""
	end
	codeFrame.CanvasPosition = Vector2.zero
end

local function removeEntry(index)
	local entry = table.remove(entries, index)
	if entry.row then entry.row:Destroy() end
	if selected == entry then setSelected(nil) end
end

local function makeRow(entry)
	local isOutgoing = entry.method ~= "OnClientEvent"
	local tagColor = isOutgoing and THEME.out or THEME.inc

	local row = make("TextButton", {
		Name = "log_" .. order,
		LayoutOrder = -order, -- newest on top
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.row,
		AutoButtonColor = false,
		Text = "",
		Parent = logList,
	}, { corner(6) })

	local outline = stroke(THEME.accent, 1.5)
	outline.Enabled = false
	outline.Parent = row
	entry.outline = outline

	make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(34, 18),
		BackgroundColor3 = tagColor,
		BackgroundTransparency = 0.8,
		Font = FONT_BOLD,
		TextSize = 10,
		Text = isOutgoing and "OUT" or "IN",
		TextColor3 = tagColor,
		Parent = row,
	}, { corner(4) })

	make("TextLabel", {
		Position = UDim2.fromOffset(50, 0),
		Size = UDim2.new(1, -106, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT_MEDIUM,
		TextSize = 13,
		Text = entry.remote.Name,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0, 52, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 11,
		Text = entry.time,
		TextColor3 = THEME.muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	addHover(row, THEME.row)
	row.MouseButton1Click:Connect(function()
		setSelected(entry)
	end)
	return row
end

local function addLog(remote, method, args)
	if ignored[remote] then return end

	order += 1
	local entry = {
		remote = remote,
		method = method,
		args = args,
		time = os.date("%H:%M:%S"),
	}
	entry.row = makeRow(entry)

	table.insert(entries, entry)
	while #entries > MAX_LOGS do
		removeEntry(1)
	end
	updateCount()
end

-- Outgoing (you -> server): calls made through RemoteLogger, if you use it
task.spawn(function()
	local module = ReplicatedStorage:WaitForChild("RemoteLogger", 5)
	if module and module:IsA("ModuleScript") then
		require(module).Logged:Connect(addLog)
	end
end)

-- Incoming (server -> you)
local watched = {}
local function watch(inst)
	if watched[inst] then return end
	if inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent") then
		watched[inst] = true
		inst.OnClientEvent:Connect(function(...)
			addLog(inst, "OnClientEvent", table.pack(...))
		end)
	end
end

for _, container in ipairs({ ReplicatedStorage, workspace }) do
	for _, d in ipairs(container:GetDescendants()) do
		watch(d)
	end
	container.DescendantAdded:Connect(watch)
end

---------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------

local function bind(name, fn)
	functions:FindFirstChild(name).MouseButton1Click:Connect(fn)
end

-- Copy: selects all the text so you can press Ctrl+C
-- (normal Roblox scripts have no clipboard access)
bind("copy", function()
	if not selected then return flash("Select a remote first", THEME.danger) end
	codeBox.Text = buildCode(selected)
	codeBox:CaptureFocus()
	codeBox.CursorPosition = #codeBox.Text + 1
	codeBox.SelectionStart = 1
	flash("Selected - press Ctrl+C")
end)

-- Replicate: fires the selected remote again with the same data
bind("run", function()
	if not selected then return flash("Select a remote first", THEME.danger) end
	local e = selected
	if e.method == "FireServer" then
		e.remote:FireServer(table.unpack(e.args, 1, e.args.n))
		flash("Fired " .. e.remote.Name)
	elseif e.method == "InvokeServer" then
		task.spawn(function()
			local result = table.pack(pcall(e.remote.InvokeServer, e.remote, table.unpack(e.args, 1, e.args.n)))
			local out = {}
			for i = 2, result.n do table.insert(out, serialize(result[i])) end
			codeBox.Text = buildCode(e) .. "\n\n-- returned (" .. (result[1] and "ok" or "error") .. "): "
				.. table.concat(out, ", ")
			flash("Invoked " .. e.remote.Name)
		end)
	else
		flash("Can't replicate server -> client events", THEME.danger)
	end
end)

-- Ignore: hides the selected remote and stops logging it
bind("ignore", function()
	if not selected then return flash("Select a remote first", THEME.danger) end
	local remote = selected.remote
	ignored[remote] = true
	for i = #entries, 1, -1 do
		if entries[i].remote == remote then removeEntry(i) end
	end
	updateCount()
	flash("Ignoring " .. remote.Name)
end)

-- Unignore: starts logging the selected remote again
bind("unignore", function()
	if not selected then return flash("Select a remote first", THEME.danger) end
	ignored[selected.remote] = nil
	flash("Unignored " .. selected.remote.Name)
end)

-- Unignore All: empties the ignore list
bind("unignore all", function()
	table.clear(ignored)
	flash("Ignore list cleared")
end)

-- Clear Logs: removes every row from the list
bind("clear logs", function()
	for i = #entries, 1, -1 do removeEntry(i) end
	setSelected(nil)
	updateCount()
	flash("Logs cleared")
end)

updateCount()
