local ResolvePath = require(script.Parent.ResolvePath)

-- Returns (script, undoFn). If we created the script, undo destroys it.
-- If we edited an existing script, undo restores the old source.
local function apply(step)
	local target = step.target
	local script_ = ResolvePath.resolve(target.path)
	local createdHere = false

	if not script_ then
		assert(
			target.create,
			`codeEdit: '{target.path}' not found and target.create is not set`
		)
		local class = target.class or "Script"
		local parent, leafName = ResolvePath.resolveParentAndName(target.path)
		assert(parent, `codeEdit: parent of '{target.path}' not found`)

		script_ = Instance.new(class)
		script_.Name = leafName
		script_.Parent = parent
		createdHere = true
	end

	assert(
		script_:IsA("LuaSourceContainer"),
		`codeEdit: target '{target.path}' is not a script (got {script_.ClassName})`
	)

	local oldSource = (script_ :: any).Source
	;(script_ :: any).Source = step.source

	local function undo()
		if createdHere then
			script_:Destroy()
		elseif script_.Parent then
			(script_ :: any).Source = oldSource
		end
	end

	return script_, undo
end

return { apply = apply }
