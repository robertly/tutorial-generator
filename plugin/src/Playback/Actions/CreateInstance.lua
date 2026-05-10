local ResolvePath = require(script.Parent.Parent.ResolvePath)
local Coerce = require(script.Parent.Parent.Coerce)

-- action: { op = "createInstance", class, parent, props? }
local function apply(action)
	local parent = ResolvePath.resolve(action.parent)
	assert(parent, `createInstance: parent '{action.parent}' not found`)

	local instance = Instance.new(action.class)

	local props = action.props or {}
	-- Name first, then everything else, to keep later path-based references valid.
	if props.Name then
		instance.Name = props.Name
	end

	for name, rawValue in pairs(props) do
		if name ~= "Name" then
			local value = Coerce.coerce(instance, name, rawValue);
			(instance :: any)[name] = value
		end
	end

	instance.Parent = parent
	return instance
end

return {
	apply = apply,
}
