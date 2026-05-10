local ResolvePath = require(script.Parent.Parent.ResolvePath)

local function apply(action)
	local instance = ResolvePath.resolve(action.target)
	if instance then
		instance:Destroy()
	end
end

return { apply = apply }
