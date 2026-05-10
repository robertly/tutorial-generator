-- Native Instance-based UI for the MVP plugin. No React, no Roact.
-- Renders a vertical stack inside the DockWidget:
--   [Title]
--   [Step N of M — step.type]
--   [Step body text]
--   [Previous] [Next] [Reset]
--
-- The "Reset" button walks back to step 0 by undoing via ChangeHistoryService.

local Apply = require(script.Parent.Playback.Apply)

local function createUI(parent: GuiObject, lesson)
	-- ---- Layout container ------------------------------------------------
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	root.Size = UDim2.fromScale(1, 1)
	root.BorderSizePixel = 0
	root.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = root

	-- ---- Title -----------------------------------------------------------
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 1
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 24)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(230, 230, 230)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = lesson.title
	title.Parent = root

	-- ---- Step counter ----------------------------------------------------
	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.LayoutOrder = 2
	counter.BackgroundTransparency = 1
	counter.Size = UDim2.new(1, 0, 0, 16)
	counter.Font = Enum.Font.Gotham
	counter.TextSize = 12
	counter.TextColor3 = Color3.fromRGB(160, 160, 160)
	counter.TextXAlignment = Enum.TextXAlignment.Left
	counter.Parent = root

	-- ---- Step body -------------------------------------------------------
	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.LayoutOrder = 3
	body.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	body.BorderSizePixel = 0
	body.Size = UDim2.new(1, 0, 0, 140)
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextColor3 = Color3.fromRGB(220, 220, 220)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Parent = root

	local bodyPadding = Instance.new("UIPadding")
	bodyPadding.PaddingTop = UDim.new(0, 8)
	bodyPadding.PaddingBottom = UDim.new(0, 8)
	bodyPadding.PaddingLeft = UDim.new(0, 10)
	bodyPadding.PaddingRight = UDim.new(0, 10)
	bodyPadding.Parent = body

	-- ---- Prompt box (only shown for prompt steps) -------------------------
	local promptBox = Instance.new("TextBox")
	promptBox.Name = "Prompt"
	promptBox.LayoutOrder = 4
	promptBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	promptBox.BorderSizePixel = 0
	promptBox.Size = UDim2.new(1, 0, 0, 100)
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

	local promptPadding = Instance.new("UIPadding")
	promptPadding.PaddingTop = UDim.new(0, 8)
	promptPadding.PaddingBottom = UDim.new(0, 8)
	promptPadding.PaddingLeft = UDim.new(0, 10)
	promptPadding.PaddingRight = UDim.new(0, 10)
	promptPadding.Parent = promptBox

	-- ---- Button row ------------------------------------------------------
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.LayoutOrder = 5
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 32)
	buttonRow.Parent = root

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 6)
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = buttonRow

	local function makeButton(name, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.Size = UDim2.new(0, 90, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 13
		btn.TextColor3 = Color3.fromRGB(230, 230, 230)
		btn.Text = text
		btn.Parent = buttonRow

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn

		return btn
	end

	local prevBtn = makeButton("Prev", "◀ Prev", 1)
	local nextBtn = makeButton("Next", "Next ▶", 2)
	local resetBtn = makeButton("Reset", "Reset", 3)

	-- ---- State -----------------------------------------------------------
	-- `currentIndex` is the index of the LAST APPLIED step. 0 = nothing
	-- applied yet. `undoStack[i]` reverses the step at index i, so Prev and
	-- Reset just pop and call. Independent of ChangeHistoryService so
	-- narrative/prompt steps (which don't mutate) don't throw off the count.
	local currentIndex = 0
	local undoStack: { () -> () } = {}

	local function render()
		local previewIndex = math.min(currentIndex + 1, #lesson.steps)
		if currentIndex >= #lesson.steps then
			previewIndex = #lesson.steps
		end
		-- If everything has been applied, show the last step; otherwise show
		-- the step that would be applied next.
		local stepToShow
		if currentIndex == 0 then
			stepToShow = lesson.steps[1]
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

		if stepToShow.type == "prompt" and stepToShow.suggestedPrompt then
			promptBox.Visible = true
			promptBox.Text = stepToShow.suggestedPrompt
		else
			promptBox.Visible = false
		end

		prevBtn.Active = currentIndex > 0
		prevBtn.AutoButtonColor = currentIndex > 0
		prevBtn.BackgroundColor3 = if currentIndex > 0
			then Color3.fromRGB(60, 60, 60)
			else Color3.fromRGB(40, 40, 40)

		nextBtn.Active = currentIndex < #lesson.steps
		nextBtn.AutoButtonColor = currentIndex < #lesson.steps
		nextBtn.BackgroundColor3 = if currentIndex < #lesson.steps
			then Color3.fromRGB(70, 100, 70)
			else Color3.fromRGB(40, 40, 40)
	end

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
			if undoFn then
				pcall(undoFn)
			end
			undoStack[currentIndex] = nil
			currentIndex -= 1
		end
		render()
	end)

	render()
end

return {
	create = createUI,
}
