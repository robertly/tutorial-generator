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

-- Apply a single step. Returns an undo function that reverses it (may be a
-- no-op for narrative/prompt). Wraps in ChangeHistoryService so Ctrl-Z on
-- the place also works, but the UI uses the returned undo directly so
-- narrative/prompt steps don't throw off the count.
local function applyStep(lessonId: string, step): () -> ()
	local displayName = `tutorial:{lessonId}:{step.id}`
	local recording = ChangeHistoryService:TryBeginRecording(displayName)

	local undoFn: () -> () = function() end
	local ok, err = pcall(function()
		if step.type == "narrative" or step.type == "prompt" then
			return
		elseif step.type == "scripted" then
			local fn = ACTIONS[step.action.op]
			assert(fn, `Unknown action op '{step.action.op}'`)
			local _, u = fn(step.action)
			undoFn = u or undoFn
		elseif step.type == "codeEdit" then
			local _, u = CodeEdit.apply(step)
			undoFn = u or undoFn
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
	return undoFn
end

return {
	applyStep = applyStep,
}
