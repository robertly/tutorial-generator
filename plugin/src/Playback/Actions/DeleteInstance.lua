local ResolvePath = require(script.Parent.Parent.ResolvePath)

-- Returns (nil, undoFn). undoFn reparents the original instance back.
local function apply(action)
	local instance = ResolvePath.resolve(action.target)
	if not instance then
		return nil, function() end
	end

	local oldParent = instance.Parent
	instance.Parent = nil

	local function undo()
		instance.Parent = oldParent
	end

	return nil, undo
end

return { apply = apply }
