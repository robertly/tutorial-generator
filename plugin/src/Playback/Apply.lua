local ChangeHistoryService = game:GetService("ChangeHistoryService")

local CreateInstance = require(script.Parent.Actions.CreateInstance)
local SetProperty = require(script.Parent.Actions.SetProperty)
local DeleteInstance = require(script.Parent.Actions.DeleteInstance)
local ParentTo = require(script.Parent.Actions.ParentTo)
local CloneFromAssets = require(script.Parent.Actions.CloneFromAssets)
local InsertAsset = require(script.Parent.Actions.InsertAsset)
local CodeEdit = require(script.Parent.CodeEdit)
local Focus = require(script.Parent.Focus)

local ACTIONS = {
	createInstance = CreateInstance.apply,
	setProperty = SetProperty.apply,
	deleteInstance = DeleteInstance.apply,
	parentTo = ParentTo.apply,
	cloneFromAssets = CloneFromAssets.apply,
	insertAsset = InsertAsset.apply,
}

-- Apply a single step inside a ChangeHistoryService transaction so Ctrl-Z
-- undoes exactly one step.
local function applyStep(lessonId: string, step)
	local displayName = `tutorial:{lessonId}:{step.id}`
	local recording = ChangeHistoryService:TryBeginRecording(displayName)

	local ok, err = pcall(function()
		if step.type == "narrative" then
			-- no-op
		elseif step.type == "scripted" then
			local fn = ACTIONS[step.action.op]
			assert(fn, `Unknown action op '{step.action.op}'`)
			fn(step.action)
		elseif step.type == "codeEdit" then
			CodeEdit.apply(step)
		elseif step.type == "prompt" then
			-- no-op; the reader copies the suggested prompt into Assistant
		else
			error(`Unknown step type '{step.type}'`)
		end
	end)

	if recording then
		ChangeHistoryService:FinishRecording(
			recording,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end

	if not ok then
		error(err)
	end

	Focus.apply(step.focus)
end

-- Replay steps [1..endIndex] from scratch. Caller is responsible for
-- resetting the place to a clean state (usually: reopen the .rbxlx).
local function replayTo(lessonId: string, lesson, endIndex: number)
	for i = 1, endIndex do
		applyStep(lessonId, lesson.steps[i])
	end
end

return {
	applyStep = applyStep,
	replayTo = replayTo,
}
