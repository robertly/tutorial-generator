local ResolvePath = require(script.Parent.Parent.ResolvePath)

local function apply(action)
	local instance = ResolvePath.resolve(action.target)
	assert(instance, `parentTo: target '{action.target}' not found`)
	local parent = ResolvePath.resolve(action.parent)
	assert(parent, `parentTo: parent '{action.parent}' not found`)
	instance.Parent = parent
end

return { apply = apply }
