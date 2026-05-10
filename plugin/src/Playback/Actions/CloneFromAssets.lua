local ResolvePath = require(script.Parent.Parent.ResolvePath)

-- action: { op = "cloneFromAssets", source, parent, name? }
-- source must live under ReplicatedStorage.TutorialAssets.*
local function apply(action)
	assert(
		string.sub(action.source, 1, #"ReplicatedStorage.TutorialAssets.") == "ReplicatedStorage.TutorialAssets.",
		`cloneFromAssets: source must start with ReplicatedStorage.TutorialAssets (got '{action.source}')`
	)

	local template = ResolvePath.resolve(action.source)
	assert(
		template,
		`cloneFromAssets: '{action.source}' not found. Open TutorialsPlace.rbxlx or ensure the asset is bundled.`
	)

	local parent = ResolvePath.resolve(action.parent)
	assert(parent, `cloneFromAssets: parent '{action.parent}' not found`)

	local clone = template:Clone()
	if action.name then
		clone.Name = action.name
	end
	clone.Parent = parent
	return clone
end

return { apply = apply }
