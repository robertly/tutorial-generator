-- Native Instance-based UI. Three views:
--   Library  — list of lessons. Click one to open.
--   Lesson   — active playback: title, step counter, body, optional diff,
--              optional prompt, Prev/Next/Reset buttons.
--   Settings — paste a lesson URL to fetch and add to the library.
--
-- Restart in a fresh (empty) place before running a lesson; undo/reset
-- only reverse steps the plugin applied itself.

local Apply = require(script.Parent.Playback.Apply)
local Diff = require(script.Parent.Playback.Diff)
local Fetch = require(script.Parent.Fetch)

local SETTING_URLS = "TutorialPlugin_LessonUrls"
local SETTING_LESSONS = "TutorialPlugin_CachedLessons"
local SETTING_SEEDED = "TutorialPlugin_DefaultRegistrySeeded"

-- First-launch default: points at this project's public samples repo so the
-- library isn't empty on first open. Only written if the user has never had
-- any URLs — clearing the list by hand stays cleared.
local DEFAULT_REGISTRY_URL = "https://raw.githubusercontent.com/robertly/tutorial-generator/master/examples"

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

	-- ---- Step strip (clickable dots for scrubbing) -----------------------
	local stripScroll = Instance.new("ScrollingFrame")
	stripScroll.LayoutOrder = 3
	stripScroll.BackgroundTransparency = 1
	stripScroll.BorderSizePixel = 0
	stripScroll.Size = UDim2.new(1, 0, 0, 30)
	stripScroll.CanvasSize = UDim2.fromScale(0, 0)
	stripScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	stripScroll.ScrollBarThickness = 4
	stripScroll.ScrollingDirection = Enum.ScrollingDirection.X
	stripScroll.Parent = root

	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.Padding = UDim.new(0, 4)
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stripLayout.Parent = stripScroll

	-- ---- Step body -------------------------------------------------------
	local body = Instance.new("TextLabel")
	body.LayoutOrder = 4
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
	diffScroll.LayoutOrder = 5
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
	promptBox.LayoutOrder = 6
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

	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = "CopyPrompt"
	copyBtn.AnchorPoint = Vector2.new(1, 0)
	copyBtn.Position = UDim2.new(1, -6, 0, 6)
	copyBtn.Size = UDim2.new(0, 60, 0, 22)
	copyBtn.BackgroundColor3 = ROW
	copyBtn.BorderSizePixel = 0
	copyBtn.Font = Enum.Font.Gotham
	copyBtn.TextSize = 11
	copyBtn.TextColor3 = TEXT
	copyBtn.Text = "⧉ Copy"
	copyBtn.AutoButtonColor = true
	copyBtn.Parent = promptBox
	corner(copyBtn, 4)
	copyBtn.Activated:Connect(function()
		local text = promptBox.Text
		local ok = pcall(setclipboard, text)
		if ok then
			copyBtn.Text = "✓ Copied"
			task.delay(1.2, function()
				copyBtn.Text = "⧉ Copy"
			end)
		else
			copyBtn.Text = "× Fail"
			task.delay(1.2, function()
				copyBtn.Text = "⧉ Copy"
			end)
		end
	end)

	-- ---- Button row ------------------------------------------------------
	local buttonRow = Instance.new("Frame")
	buttonRow.LayoutOrder = 7
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
	local autoBtn = makeBtn("Auto", "▶ Auto", 3)
	local resetBtn = makeBtn("Reset", "Reset", 4)

	-- ---- State + render --------------------------------------------------
	local currentIndex = 0
	local undoStack: { () -> () } = {}
	local autoTask: thread? = nil
	local AUTO_SECONDS = 2.5

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

		-- On the last step (whether previewing or already applied), swap
		-- Next for a terminal "Finish" button.
		local isLastPreview = currentIndex < #lesson.steps
			and (currentIndex + 1) == #lesson.steps
		local isComplete = currentIndex >= #lesson.steps

		if isLastPreview or isComplete then
			nextBtn.Text = "✓ Finish"
			nextBtn.Size = UDim2.new(0, 110, 1, 0)
			nextBtn.Active = true
			nextBtn.AutoButtonColor = true
			nextBtn.BackgroundColor3 = Color3.fromRGB(90, 150, 90)
		else
			nextBtn.Text = "Next ▶"
			nextBtn.Size = UDim2.new(0, 90, 1, 0)
			nextBtn.Active = true
			nextBtn.AutoButtonColor = true
			nextBtn.BackgroundColor3 = ACCENT
		end

		-- Strip: highlight applied steps, outline the previewed-next one.
		for i, btn in ipairs(stripButtons) do
			local base = typeColor(lesson.steps[i].type)
			if i <= currentIndex then
				btn.BackgroundColor3 = base
				btn.TextTransparency = 0
				btn.BackgroundTransparency = 0
			elseif i == previewIndex and not isComplete then
				btn.BackgroundColor3 = base
				btn.TextTransparency = 0
				btn.BackgroundTransparency = 0.3
			else
				btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				btn.TextTransparency = 0.4
				btn.BackgroundTransparency = 0
			end
		end
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

	-- Give focus back to the 3D viewport by closing any open script docs
	-- (so they stop covering the view) and selecting the first BasePart we
	-- can find in Workspace so the viewport has something to orbit.
	local function focusViewport()
		pcall(function()
			local ScriptEditorService = game:GetService("ScriptEditorService")
			for _, doc in ipairs(ScriptEditorService:GetScriptDocuments()) do
				if not doc:IsCommandBar() then
					doc:CloseAsync()
				end
			end
		end)
		pcall(function()
			local Selection = game:GetService("Selection")
			for _, child in ipairs(workspace:GetDescendants()) do
				if child:IsA("BasePart") then
					Selection:Set({ child })
					return
				end
			end
			Selection:Set({})
		end)
	end

	local function stopAutoplay()
		if autoTask then
			pcall(task.cancel, autoTask)
			autoTask = nil
		end
		autoBtn.Text = "▶ Auto"
		autoBtn.BackgroundColor3 = ROW
	end

	-- Step-type → strip-button tint
	local function typeColor(stepType: string): Color3
		if stepType == "narrative" then return Color3.fromRGB(110, 110, 120)
		elseif stepType == "scripted" then return Color3.fromRGB(70, 110, 160)
		elseif stepType == "codeEdit" then return Color3.fromRGB(140, 90, 160)
		elseif stepType == "prompt" then return Color3.fromRGB(180, 130, 60)
		else return Color3.fromRGB(90, 90, 90)
		end
	end

	-- Build the step strip once.
	local stripButtons: { TextButton } = {}
	for i, step in ipairs(lesson.steps) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 26, 0, 26)
		btn.BackgroundColor3 = typeColor(step.type)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = TEXT
		btn.Text = tostring(i)
		btn.AutoButtonColor = true
		btn.Parent = stripScroll
		corner(btn, 13)
		table.insert(stripButtons, btn)
	end

	local scrubTo: (target: number) -> ()  -- forward declaration

	local function applyNext(): boolean
		if currentIndex >= #lesson.steps then return false end
		local step = lesson.steps[currentIndex + 1]
		local ok, undoOrErr = pcall(Apply.applyStep, lesson.id, step)
		if not ok then
			warn(`[tutorial] step '{step.id}' failed: {undoOrErr}`)
			return false
		end
		currentIndex += 1
		undoStack[currentIndex] = undoOrErr
		render()
		return true
	end

	-- Scrub to applied-step target (0 = nothing applied, N = steps[1..N]).
	-- Implemented as replay-from-current-state: undo down to target or
	-- apply up to target, never both, so this is linear in the delta.
	scrubTo = function(target: number)
		stopAutoplay()
		target = math.max(0, math.min(target, #lesson.steps))
		while currentIndex > target do
			local undoFn = undoStack[currentIndex]
			if undoFn then pcall(undoFn) end
			undoStack[currentIndex] = nil
			currentIndex -= 1
		end
		while currentIndex < target do
			if not applyNext() then break end
		end
		render()
	end

	for i, btn in ipairs(stripButtons) do
		btn.Activated:Connect(function()
			scrubTo(i)
		end)
	end

	nextBtn.Activated:Connect(function()
		stopAutoplay()
		if currentIndex >= #lesson.steps then
			focusViewport()
			return
		end
		applyNext()
		if currentIndex >= #lesson.steps then
			focusViewport()
		end
	end)

	prevBtn.Activated:Connect(function()
		stopAutoplay()
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
		stopAutoplay()
		while currentIndex > 0 do
			local undoFn = undoStack[currentIndex]
			if undoFn then pcall(undoFn) end
			undoStack[currentIndex] = nil
			currentIndex -= 1
		end
		render()
	end)

	autoBtn.Activated:Connect(function()
		if autoTask then
			stopAutoplay()
			return
		end
		autoBtn.Text = "⏸ Pause"
		autoBtn.BackgroundColor3 = Color3.fromRGB(150, 120, 70)
		autoTask = task.spawn(function()
			while autoTask do
				if currentIndex >= #lesson.steps then
					stopAutoplay()
					focusViewport()
					return
				end
				-- Pause before prompt steps — they need reader action.
				local nextStep = lesson.steps[currentIndex + 1]
				if nextStep and nextStep.type == "prompt" then
					stopAutoplay()
					return
				end
				task.wait(AUTO_SECONDS)
				if not autoTask then return end
				if not applyNext() then
					stopAutoplay()
					return
				end
			end
		end)
	end)

	render()
end

-- ============================================================
-- Library view
-- ============================================================

local function showLibrary(parent: GuiObject, lessons, onPick: (lesson: any) -> (), onSettings: () -> ())
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

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = TEXT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Tutorials"
	title.Parent = header

	local settingsBtn = Instance.new("TextButton")
	settingsBtn.Size = UDim2.new(0, 82, 1, 0)
	settingsBtn.BackgroundColor3 = ROW
	settingsBtn.Font = Enum.Font.Gotham
	settingsBtn.TextSize = 12
	settingsBtn.TextColor3 = TEXT
	settingsBtn.Text = "⚙ Manage"
	settingsBtn.Parent = header
	corner(settingsBtn, 4)
	settingsBtn.Activated:Connect(onSettings)

	local searchBox = Instance.new("TextBox")
	searchBox.LayoutOrder = 2
	searchBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	searchBox.BorderSizePixel = 0
	searchBox.Size = UDim2.new(1, 0, 0, 28)
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 13
	searchBox.TextColor3 = TEXT
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.PlaceholderText = "🔍 Search lessons..."
	searchBox.Text = ""
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = root
	pad(searchBox, 6, 8, 6, 8)

	-- Collect all unique tags
	local tagSet: { [string]: true } = {}
	for _, lesson in ipairs(lessons) do
		for _, t in ipairs(lesson.tags or {}) do
			tagSet[t] = true
		end
	end
	local allTags: { string } = {}
	for t in pairs(tagSet) do
		table.insert(allTags, t)
	end
	table.sort(allTags)

	local tagRow = Instance.new("ScrollingFrame")
	tagRow.LayoutOrder = 3
	tagRow.BackgroundTransparency = 1
	tagRow.BorderSizePixel = 0
	tagRow.Size = UDim2.new(1, 0, 0, 26)
	tagRow.CanvasSize = UDim2.fromScale(0, 0)
	tagRow.AutomaticCanvasSize = Enum.AutomaticSize.X
	tagRow.ScrollBarThickness = 2
	tagRow.ScrollingDirection = Enum.ScrollingDirection.X
	tagRow.Parent = root
	tagRow.Visible = #allTags > 0

	local tagLayout = Instance.new("UIListLayout")
	tagLayout.FillDirection = Enum.FillDirection.Horizontal
	tagLayout.Padding = UDim.new(0, 4)
	tagLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tagLayout.Parent = tagRow

	local selectedTag: string? = nil
	local tagChips: { [string]: TextButton } = {}

	local subtitle = Instance.new("TextLabel")
	subtitle.LayoutOrder = 4
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, 0, 0, 16)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextColor3 = MUTED
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = root

	local list = Instance.new("ScrollingFrame")
	list.LayoutOrder = 5
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 1, -120)
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

	local function matchesFilter(lesson): boolean
		if selectedTag then
			local hit = false
			for _, t in ipairs(lesson.tags or {}) do
				if t == selectedTag then hit = true; break end
			end
			if not hit then return false end
		end
		local q = string.lower(searchBox.Text or "")
		if q == "" then return true end
		if string.find(string.lower(lesson.title or ""), q, 1, true) then return true end
		if string.find(string.lower(lesson.id or ""), q, 1, true) then return true end
		if string.find(string.lower(lesson.goal or ""), q, 1, true) then return true end
		return false
	end

	local function renderList()
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end

		if #lessons == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 80)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 13
			empty.TextColor3 = MUTED
			empty.TextXAlignment = Enum.TextXAlignment.Left
			empty.TextYAlignment = Enum.TextYAlignment.Top
			empty.TextWrapped = true
			empty.Text = "No lessons yet.\n\nClick ⚙ Manage above and fetch a repo like:\n\nhttps://raw.githubusercontent.com/robertly/tutorial-generator/master/examples"
			empty.Parent = list
			subtitle.Text = "0 lessons"
			return
		end

		local shown = 0
		for i, lesson in ipairs(lessons) do
			if not matchesFilter(lesson) then continue end
			shown += 1
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

		subtitle.Text = string.format("%d of %d", shown, #lessons)
	end

	local function refreshTagChips()
		for tag, chip in pairs(tagChips) do
			chip.BackgroundColor3 = if selectedTag == tag then ACCENT else ROW
		end
	end

	for _, tag in ipairs(allTags) do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.new(0, 0, 1, 0)
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.BackgroundColor3 = ROW
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.Gotham
		chip.TextSize = 11
		chip.TextColor3 = TEXT
		chip.Text = tag
		chip.Parent = tagRow
		corner(chip, 11)
		pad(chip, 0, 10, 0, 10)
		tagChips[tag] = chip
		chip.Activated:Connect(function()
			selectedTag = if selectedTag == tag then nil else tag
			refreshTagChips()
			renderList()
		end)
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(renderList)
	renderList()
end

-- ============================================================
-- Settings view
-- ============================================================

local function showSettings(parent: GuiObject, plugin: Plugin, onBack: () -> (), onAdded: (lesson: any) -> ())
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

	-- Header with back + title
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
	backBtn.BackgroundColor3 = ROW
	backBtn.Font = Enum.Font.Gotham
	backBtn.TextSize = 12
	backBtn.TextColor3 = TEXT
	backBtn.Text = "◀ Back"
	backBtn.Parent = header
	corner(backBtn, 4)
	backBtn.Activated:Connect(onBack)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = TEXT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Fetch a lesson"
	title.Parent = header

	local help = Instance.new("TextLabel")
	help.LayoutOrder = 2
	help.BackgroundTransparency = 1
	help.Size = UDim2.new(1, 0, 0, 32)
	help.Font = Enum.Font.Gotham
	help.TextSize = 12
	help.TextColor3 = MUTED
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextYAlignment = Enum.TextYAlignment.Top
	help.TextWrapped = true
	help.Text = "Paste a lesson.json URL for a single lesson, or a repo base URL (the folder containing index.json) to fetch all lessons in it."
	help.Parent = root

	local urlBox = Instance.new("TextBox")
	urlBox.LayoutOrder = 3
	urlBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	urlBox.BorderSizePixel = 0
	urlBox.Size = UDim2.new(1, 0, 0, 28)
	urlBox.Font = Enum.Font.Code
	urlBox.TextSize = 12
	urlBox.TextColor3 = TEXT
	urlBox.TextXAlignment = Enum.TextXAlignment.Left
	urlBox.PlaceholderText = "https://raw.githubusercontent.com/.../lesson.json  or  .../samples"
	urlBox.ClearTextOnFocus = false
	urlBox.Text = ""
	urlBox.Parent = root
	pad(urlBox, 6, 8, 6, 8)

	local btnRow = Instance.new("Frame")
	btnRow.LayoutOrder = 4
	btnRow.BackgroundTransparency = 1
	btnRow.Size = UDim2.new(1, 0, 0, 28)
	btnRow.Parent = root

	local btnRowLayout = Instance.new("UIListLayout")
	btnRowLayout.FillDirection = Enum.FillDirection.Horizontal
	btnRowLayout.Padding = UDim.new(0, 6)
	btnRowLayout.Parent = btnRow

	local fetchLessonBtn = Instance.new("TextButton")
	fetchLessonBtn.Size = UDim2.new(0, 120, 1, 0)
	fetchLessonBtn.BackgroundColor3 = ACCENT
	fetchLessonBtn.BorderSizePixel = 0
	fetchLessonBtn.Font = Enum.Font.Gotham
	fetchLessonBtn.TextSize = 13
	fetchLessonBtn.TextColor3 = TEXT
	fetchLessonBtn.Text = "Fetch lesson"
	fetchLessonBtn.Parent = btnRow
	corner(fetchLessonBtn, 4)

	local fetchRepoBtn = Instance.new("TextButton")
	fetchRepoBtn.Size = UDim2.new(0, 120, 1, 0)
	fetchRepoBtn.BackgroundColor3 = Color3.fromRGB(70, 110, 160)
	fetchRepoBtn.BorderSizePixel = 0
	fetchRepoBtn.Font = Enum.Font.Gotham
	fetchRepoBtn.TextSize = 13
	fetchRepoBtn.TextColor3 = TEXT
	fetchRepoBtn.Text = "Fetch repo"
	fetchRepoBtn.Parent = btnRow
	corner(fetchRepoBtn, 4)

	local status = Instance.new("TextLabel")
	status.LayoutOrder = 5
	status.BackgroundTransparency = 1
	status.Size = UDim2.new(1, 0, 0, 48)
	status.Font = Enum.Font.Gotham
	status.TextSize = 12
	status.TextColor3 = MUTED
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.TextWrapped = true
	status.Text = ""
	status.Parent = root

	local renderManageList: () -> ()

	local function persistLesson(url: string, lesson)
		local urls = plugin:GetSetting(SETTING_URLS) or {}
		local cached = plugin:GetSetting(SETTING_LESSONS) or {}
		local replaced = false
		for i, u in ipairs(urls) do
			if u == url then
				cached[i] = lesson
				replaced = true
				break
			end
		end
		if not replaced then
			table.insert(urls, url)
			table.insert(cached, lesson)
		end
		plugin:SetSetting(SETTING_URLS, urls)
		plugin:SetSetting(SETTING_LESSONS, cached)
	end

	fetchLessonBtn.Activated:Connect(function()
		local url = urlBox.Text
		if url == "" then return end
		status.Text = "Fetching..."
		status.TextColor3 = MUTED
		task.spawn(function()
			local lesson, err = Fetch.fromUrl(url)
			if not lesson then
				status.TextColor3 = Color3.fromRGB(210, 100, 100)
				status.Text = `Failed: {err}`
				return
			end
			persistLesson(url, lesson)
			status.TextColor3 = Color3.fromRGB(120, 200, 120)
			status.Text = `Added "{lesson.title}" ({#lesson.steps} steps).`
			onAdded(lesson)
		end)
	end)

	fetchRepoBtn.Activated:Connect(function()
		local baseUrl = urlBox.Text
		if baseUrl == "" then return end
		status.Text = "Fetching repo index + lessons..."
		status.TextColor3 = MUTED
		task.spawn(function()
			local lessons, errorsOrErr = Fetch.fromRepoIndex(baseUrl)
			if not lessons then
				status.TextColor3 = Color3.fromRGB(210, 100, 100)
				status.Text = `Failed: {errorsOrErr}`
				return
			end
			local trimmed = if string.sub(baseUrl, -1) == "/"
				then string.sub(baseUrl, 1, -2)
				else baseUrl
			for _, lesson in ipairs(lessons) do
				persistLesson(trimmed .. "::" .. lesson.id, lesson)
				onAdded(lesson)
			end
			local errs = errorsOrErr :: { string }
			if #errs > 0 then
				status.TextColor3 = Color3.fromRGB(210, 170, 80)
				status.Text = `Added {#lessons} lesson(s). {#errs} failed:\n{errs[1]}`
			else
				status.TextColor3 = Color3.fromRGB(120, 200, 120)
				status.Text = `Added {#lessons} lesson(s) from repo.`
			end
			-- Refresh the manage list below.
			renderManageList()
		end)
	end)

	-- ---- Manage: list of cached lessons with remove buttons --------------
	local manageTitle = Instance.new("TextLabel")
	manageTitle.LayoutOrder = 6
	manageTitle.BackgroundTransparency = 1
	manageTitle.Size = UDim2.new(1, 0, 0, 20)
	manageTitle.Font = Enum.Font.GothamBold
	manageTitle.TextSize = 13
	manageTitle.TextColor3 = TEXT
	manageTitle.TextXAlignment = Enum.TextXAlignment.Left
	manageTitle.Text = "Fetched lessons"
	manageTitle.Parent = root

	local manageList = Instance.new("ScrollingFrame")
	manageList.LayoutOrder = 7
	manageList.BackgroundTransparency = 1
	manageList.BorderSizePixel = 0
	manageList.Size = UDim2.new(1, 0, 0, 160)
	manageList.CanvasSize = UDim2.fromScale(0, 0)
	manageList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	manageList.ScrollBarThickness = 4
	manageList.Parent = root

	local manageLayout = Instance.new("UIListLayout")
	manageLayout.FillDirection = Enum.FillDirection.Vertical
	manageLayout.Padding = UDim.new(0, 4)
	manageLayout.Parent = manageList

	local clearAllBtn = Instance.new("TextButton")
	clearAllBtn.LayoutOrder = 8
	clearAllBtn.Size = UDim2.new(0, 120, 0, 24)
	clearAllBtn.BackgroundColor3 = Color3.fromRGB(160, 70, 70)
	clearAllBtn.BorderSizePixel = 0
	clearAllBtn.Font = Enum.Font.Gotham
	clearAllBtn.TextSize = 12
	clearAllBtn.TextColor3 = TEXT
	clearAllBtn.Text = "Clear all"
	clearAllBtn.Parent = root
	corner(clearAllBtn, 4)

	renderManageList = function()
		for _, child in ipairs(manageList:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end
		local urls = plugin:GetSetting(SETTING_URLS) or {}
		local cached = plugin:GetSetting(SETTING_LESSONS) or {}
		if #urls == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 24)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextColor3 = MUTED
			empty.TextXAlignment = Enum.TextXAlignment.Left
			empty.Text = "(none)"
			empty.Parent = manageList
			return
		end
		for i, url in ipairs(urls) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -4, 0, 26)
			row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
			row.BorderSizePixel = 0
			row.Parent = manageList
			corner(row, 3)
			pad(row, 0, 6, 0, 8)

			local rowLayout = Instance.new("UIListLayout")
			rowLayout.FillDirection = Enum.FillDirection.Horizontal
			rowLayout.Padding = UDim.new(0, 6)
			rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			rowLayout.Parent = row

			local lessonTitle = Instance.new("TextLabel")
			lessonTitle.Size = UDim2.new(1, -40, 1, 0)
			lessonTitle.BackgroundTransparency = 1
			lessonTitle.Font = Enum.Font.Gotham
			lessonTitle.TextSize = 12
			lessonTitle.TextColor3 = TEXT
			lessonTitle.TextXAlignment = Enum.TextXAlignment.Left
			lessonTitle.TextTruncate = Enum.TextTruncate.AtEnd
			local lesson = cached[i]
			lessonTitle.Text = if lesson then lesson.title else url
			lessonTitle.Parent = row

			local rm = Instance.new("TextButton")
			rm.Size = UDim2.new(0, 28, 0, 22)
			rm.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
			rm.BorderSizePixel = 0
			rm.Font = Enum.Font.GothamBold
			rm.TextSize = 12
			rm.TextColor3 = TEXT
			rm.Text = "✕"
			rm.Parent = row
			corner(rm, 3)
			rm.Activated:Connect(function()
				local us = plugin:GetSetting(SETTING_URLS) or {}
				local cs = plugin:GetSetting(SETTING_LESSONS) or {}
				table.remove(us, i)
				table.remove(cs, i)
				plugin:SetSetting(SETTING_URLS, us)
				plugin:SetSetting(SETTING_LESSONS, cs)
				renderManageList()
				onAdded(nil :: any)  -- signal router to refresh
			end)
		end
	end

	clearAllBtn.Activated:Connect(function()
		plugin:SetSetting(SETTING_URLS, {})
		plugin:SetSetting(SETTING_LESSONS, {})
		renderManageList()
		onAdded(nil :: any)
	end)

	renderManageList()
end

-- ============================================================
-- Router
-- ============================================================

local function create(parent: GuiObject, plugin: Plugin, builtinLessons)
	-- First launch: seed the default registry URL and kick off a background
	-- fetch. Guarded by SETTING_SEEDED so clearing the list later stays cleared.
	if not plugin:GetSetting(SETTING_SEEDED) then
		plugin:SetSetting(SETTING_SEEDED, true)
		local urls = plugin:GetSetting(SETTING_URLS) or {}
		if #urls == 0 then
			table.insert(urls, DEFAULT_REGISTRY_URL)
			plugin:SetSetting(SETTING_URLS, urls)
			task.spawn(function()
				local lessons = Fetch.fromRepoIndex(DEFAULT_REGISTRY_URL)
				if lessons and #lessons > 0 then
					local cs = plugin:GetSetting(SETTING_LESSONS) or {}
					for _, l in ipairs(lessons) do
						table.insert(cs, l)
					end
					plugin:SetSetting(SETTING_LESSONS, cs)
				end
			end)
		end
	end

	local cached = plugin:GetSetting(SETTING_LESSONS) or {}

	local function allLessons()
		local out = {}
		for _, l in ipairs(builtinLessons) do table.insert(out, l) end
		for _, l in ipairs(cached) do table.insert(out, l) end
		return out
	end

	local goLibrary
	local goSettings
	goLibrary = function()
		showLibrary(parent, allLessons(), function(lesson)
			showLesson(parent, lesson, goLibrary)
		end, function()
			goSettings()
		end)
	end
	goSettings = function()
		showSettings(parent, plugin, goLibrary, function(lesson)
			-- Refresh cache from settings after add.
			cached = plugin:GetSetting(SETTING_LESSONS) or {}
		end)
	end

	goLibrary()
end

return {
	create = create,
}
