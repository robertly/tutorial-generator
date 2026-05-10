local ResolvePath = require(script.Parent.Parent.ResolvePath)
local Coerce = require(script.Parent.Parent.Coerce)

-- action: { op = "setProperty", target, property, value }
local function apply(action)
	local instance = ResolvePath.resolve(action.target)
	assert(instance, `setProperty: target '{action.target}' not found`)
	local value = Coerce.coerce(instance, action.property, action.value);
	(instance :: any)[action.property] = value
end

return { apply = apply }
