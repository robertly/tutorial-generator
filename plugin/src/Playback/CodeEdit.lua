local ResolvePath = require(script.Parent.ResolvePath)

-- step: { type = "codeEdit", target = { path, create?, class? }, source }
-- Full-source replacement: the `source` string is the entire script body
-- after this step. Never a diff.
local function apply(step)
	local target = step.target
	local script_ = ResolvePath.resolve(target.path)

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
	end

	assert(
		script_:IsA("LuaSourceContainer"),
		`codeEdit: target '{target.path}' is not a script (got {script_.ClassName})`
	)

	;(script_ :: any).Source = step.source
	return script_
end

return { apply = apply }
