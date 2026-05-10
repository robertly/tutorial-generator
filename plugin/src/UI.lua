-- Native Instance-based UI. Two views:
--   Library  — list of lessons. Click one to open.
--   Lesson   — active playback: title, step counter, body, optional diff,
--              optional prompt, Prev/Next/Reset buttons.
--
-- Restart in a fresh (empty) place before running a lesson; undo/reset
-- only reverse steps the plugin applied itself.

local Apply = require(script.Parent.Playback.Apply)
local Diff = require(script.Parent.Playback.Diff)

local BG = Color3.fromRGB(40, 40, 40)
local PANEL = Color3.fromRGB(32, 32, 32)
local TEXT = Color3.fromRGB(230, 230, 230)
local MUTED = Color3.fromRGB(160, 160, 160)
local ACCENT = Color3.fromRGB(80, 130, 80)
local ROW = Color3.fromRGB(52, 52, 52)
local ROW_HOVER = Color3.fromRGB(68, 68, 68)

local function pad(inst: Instance, top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top)
	p.PaddingRight = UDim.new(0, right)
	p.PaddingBottom = UDim.new(0, bottom)
	p.PaddingLeft = UDim.new(0, left)
	p.Parent = inst
end

local function corner(inst: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
end

-- Find previous codeEdit's source for the same target path, walking back
-- through already-applied steps. Returns "" if this is the first edit.
local function previousSourceFor(lesson, stepIndex: number): string
	local path = lesson.steps[stepIndex].target.path
	for i = stepIndex - 1, 1, -1 do
		local prev = lesson.steps[i]
		if prev.type == "codeEdit" and prev.target.path == path then
			return prev.source
		end
	end
	return ""
end

-- ============================================================
-- Lesson view
-- ============================================================

local function showLesson(parent: GuiObject, lesson, onBack: () -> ())
	for _, child in ipairs(parent:GetChildren()) do
		child:Destroy()
	end

	local root = Instance.new("Frame")
	root.BackgroundColor3 = BG
	root.Size = UDim2.fromScale(1, 1)
	root.BorderSizePixel = 0
	root.Parent = parent
	pad(root, 12, 12, 12, 12)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	-- ---- Header (back + title) -------------------------------------------
	local header = Instance.new("Frame")
	header.LayoutOrder = 1
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 26)
	header.Parent = root

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.Padding = UDim.new(0, 8)
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.Parent = header

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0, 52, 1, 0)
	backBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	backBtn.Font = Enum.Font.Gotham
	backBtn.TextSize = 12
	backBtn.TextColor3 = TEXT
	backBtn.Text = "◀ Back"
	backBtn.Parent = header
	corner(backBtn, 4)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = TEXT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = lesson.title
	title.Parent = header

	-- ---- Step counter ----------------------------------------------------
	local counter = Instance.new("TextLabel")
	counter.LayoutOrder = 2
	counter.BackgroundTransparency = 1
	counter.Size = UDim2.new(1, 0, 0, 16)
	counter.Font = Enum.Font.Gotham
	counter.TextSize = 12
	counter.TextColor3 = MUTED
	counter.TextXAlignment = Enum.TextXAlignment.Left
	counter.Parent = root

	-- ---- Step body -------------------------------------------------------
	local body = Instance.new("TextLabel")
	body.LayoutOrder = 3
	body.BackgroundColor3 = PANEL
	body.BorderSizePixel = 0
	body.Size = UDim2.new(1, 0, 0, 110)
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextColor3 = TEXT
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Parent = root
	pad(body, 8, 10, 8, 10)

	-- ---- Diff view (codeEdit steps) --------------------------------------
	local diffScroll = Instance.new("ScrollingFrame")
	diffScroll.LayoutOrder = 4
	diffScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	diffScroll.BorderSizePixel = 0
	diffScroll.Size = UDim2.new(1, 0, 0, 220)
	diffScroll.CanvasSize = UDim2.fromScale(0, 0)
	diffScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	diffScroll.ScrollBarThickness = 6
	diffScroll.Visible = false
	diffScroll.Parent = root

	local diffLabel = Instance.new("TextLabel")
	diffLabel.BackgroundTransparency = 1
	diffLabel.Size = UDim2.new(1, -4, 0, 0)
	diffLabel.AutomaticSize = Enum.AutomaticSize.Y
	diffLabel.Font = Enum.Font.Code
	diffLabel.TextSize = 12
	diffLabel.TextXAlignment = Enum.TextXAlignment.Left
	diffLabel.TextYAlignment = Enum.TextYAlignment.Top
	diffLabel.TextWrapped = false
	diffLabel.RichText = true
	diffLabel.Text = ""
	diffLabel.Parent = diffScroll
	pad(diffLabel, 8, 10, 8, 10)

	-- ---- Prompt box (prompt steps) --------------------------------------
	local promptBox = Instance.new("TextBox")
	promptBox.LayoutOrder = 5
	promptBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	promptBox.BorderSizePixel = 0
	promptBox.Size = UDim2.new(1, 0, 0, 110)
	promptBox.Font = Enum.Font.Code
	promptBox.TextSize = 12
	promptBox.TextColor3 = Color3.fromRGB(200, 220, 240)
	promptBox.TextXAlignment = Enum.TextXAlignment.Left
	promptBox.TextYAlignment = Enum.TextYAlignment.Top
	promptBox.TextWrapped = true
	promptBox.MultiLine = true
	promptBox.ClearTextOnFocus = false
	promptBox.Visible = false
	promptBox.Parent = root
	pad(promptBox, 8, 10, 8, 10)

	-- ---- Button row ------------------------------------------------------
	local buttonRow = Instance.new("Frame")
	buttonRow.LayoutOrder = 6
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 32)
	buttonRow.Parent = root

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 6)
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = buttonRow

	local function makeBtn(name, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.Size = UDim2.new(0, 90, 1, 0)
		btn.BackgroundColor3 = ROW
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 13
		btn.TextColor3 = TEXT
		btn.Text = text
		btn.Parent = buttonRow
		corner(btn, 4)
		return btn
	end

	local prevBtn = makeBtn("Prev", "◀ Prev", 1)
	local nextBtn = makeBtn("Next", "Next ▶", 2)
	local resetBtn = makeBtn("Reset", "Reset", 3)

	-- ---- State + render --------------------------------------------------
	local currentIndex = 0
	local undoStack: { () -> () } = {}

	local function render()
		local previewIndex
		local stepToShow
		if currentIndex == 0 then
			stepToShow = lesson.steps[1]
			previewIndex = 1
		elseif currentIndex >= #lesson.steps then
			stepToShow = lesson.steps[#lesson.steps]
			previewIndex = #lesson.steps
		else
			stepToShow = lesson.steps[currentIndex + 1]
			previewIndex = currentIndex + 1
		end

		counter.Text = string.format(
			"Step %d of %d — %s",
			previewIndex, #lesson.steps, stepToShow.type
		)
		body.Text = stepToShow.body

		-- Diff shown when the step being previewed/applied is a codeEdit.
		if stepToShow.type == "codeEdit" then
			local prev = previousSourceFor(lesson, previewIndex)
			local events = Diff.diff(prev, stepToShow.source)
			diffLabel.Text = Diff.toRichText(events)
			diffScroll.Visible = true
		else
			diffScroll.Visible = false
		end

		if stepToShow.type == "prompt" and stepToShow.suggestedPrompt then
			promptBox.Visible = true
			promptBox.Text = stepToShow.suggestedPrompt
		else
			promptBox.Visible = false
		end

		prevBtn.Active = currentIndex > 0
		prevBtn.AutoButtonColor = currentIndex > 0
		prevBtn.BackgroundColor3 = if currentIndex > 0 then ROW else Color3.fromRGB(34, 34, 34)

		nextBtn.Active = currentIndex < #lesson.steps
		nextBtn.AutoButtonColor = currentIndex < #lesson.steps
		nextBtn.BackgroundColor3 = if currentIndex < #lesson.steps then ACCENT else Color3.fromRGB(34, 34, 34)
	end

	backBtn.Activated:Connect(function()
		-- Walk the stack back before leaving so the place is clean.
		while currentIndex > 0 do
			local undoFn = undoStack[currentIndex]
			if undoFn then pcall(undoFn) end
			undoStack[currentIndex] = nil
			currentIndex -= 1
		end
		onBack()
	end)

	nextBtn.Activated:Connect(function()
		if currentIndex >= #lesson.steps then return end
		local step = lesson.steps[currentIndex + 1]
		local ok, undoOrErr = pcall(Apply.applyStep, lesson.id, step)
		if not ok then
			warn(`[tutorial] step '{step.id}' failed: {undoOrErr}`)
			return
		end
		currentIndex += 1
		undoStack[currentIndex] = undoOrErr
		render()
	end)

	prevBtn.Activated:Connect(function()
		if currentIndex <= 0 then return end
		local undoFn = undoStack[currentIndex]
		if undoFn then
			local ok, err = pcall(undoFn)
			if not ok then
				warn(`[tutorial] undo step {currentIndex} failed: {err}`)
			end
		end
		undoStack[currentIndex] = nil
		currentIndex -= 1
		render()
	end)

	resetBtn.Activated:Connect(function()
		while currentIndex > 0 do
			local undoFn = undoStack[currentIndex]
			if undoFn then pcall(undoFn) end
			undoStack[currentIndex] = nil
			currentIndex -= 1
		end
		render()
	end)

	render()
end

-- ============================================================
-- Library view
-- ============================================================

local function showLibrary(parent: GuiObject, lessons, onPick: (lesson: any) -> ())
	for _, child in ipairs(parent:GetChildren()) do
		child:Destroy()
	end

	local root = Instance.new("Frame")
	root.BackgroundColor3 = BG
	root.Size = UDim2.fromScale(1, 1)
	root.BorderSizePixel = 0
	root.Parent = parent
	pad(root, 12, 12, 12, 12)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	local title = Instance.new("TextLabel")
	title.LayoutOrder = 1
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 24)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = TEXT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Tutorials"
	title.Parent = root

	local subtitle = Instance.new("TextLabel")
	subtitle.LayoutOrder = 2
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, 0, 0, 16)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextColor3 = MUTED
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = `{#lessons} available`
	subtitle.Parent = root

	local list = Instance.new("ScrollingFrame")
	list.LayoutOrder = 3
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 1, -48)
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.BorderSizePixel = 0
	list.Parent = root

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	for i, lesson in ipairs(lessons) do
		local row = Instance.new("TextButton")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -4, 0, 64)
		row.BackgroundColor3 = ROW
		row.BorderSizePixel = 0
		row.Text = ""
		row.Parent = list
		corner(row, 4)
		pad(row, 8, 10, 8, 10)

		row.MouseEnter:Connect(function() row.BackgroundColor3 = ROW_HOVER end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = ROW end)

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Vertical
		rowLayout.Padding = UDim.new(0, 2)
		rowLayout.Parent = row

		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.Size = UDim2.new(1, 0, 0, 18)
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = TEXT
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Text = lesson.title
		titleLabel.Parent = row

		local goalLabel = Instance.new("TextLabel")
		goalLabel.BackgroundTransparency = 1
		goalLabel.Size = UDim2.new(1, 0, 0, 16)
		goalLabel.Font = Enum.Font.Gotham
		goalLabel.TextSize = 12
		goalLabel.TextColor3 = MUTED
		goalLabel.TextXAlignment = Enum.TextXAlignment.Left
		goalLabel.TextTruncate = Enum.TextTruncate.AtEnd
		goalLabel.Text = lesson.goal or `{#lesson.steps} steps`
		goalLabel.Parent = row

		row.Activated:Connect(function()
			onPick(lesson)
		end)
	end
end

-- ============================================================
-- Router
-- ============================================================

local function create(parent: GuiObject, lessons)
	local function goLibrary()
		showLibrary(parent, lessons, function(lesson)
			showLesson(parent, lesson, goLibrary)
		end)
	end
	goLibrary()
end

return {
	create = create,
}
