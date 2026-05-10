local ResolvePath = require(script.Parent.Parent.ResolvePath)

local function apply(action)
	local instance = ResolvePath.resolve(action.target)
	assert(instance, `parentTo: target '{action.target}' not found`)
	local parent = ResolvePath.resolve(action.parent)
	assert(parent, `parentTo: parent '{action.parent}' not found`)

	local oldParent = instance.Parent
	instance.Parent = parent

	local function undo()
		instance.Parent = oldParent
	end

	return nil, undo
end

return { apply = apply }
