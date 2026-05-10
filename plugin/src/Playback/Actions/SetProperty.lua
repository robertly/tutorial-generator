local ResolvePath = require(script.Parent.Parent.ResolvePath)
local Coerce = require(script.Parent.Parent.Coerce)

-- action: { op = "setProperty", target, property, value }
-- Returns (nil, undoFn). undoFn restores the previous value.
local function apply(action)
	local instance = ResolvePath.resolve(action.target)
	assert(instance, `setProperty: target '{action.target}' not found`)

	local oldValue = (instance :: any)[action.property]
	local value = Coerce.coerce(instance, action.property, action.value);
	(instance :: any)[action.property] = value

	local function undo()
		if instance.Parent then
			(instance :: any)[action.property] = oldValue
		end
	end

	return nil, undo
end

return { apply = apply }
