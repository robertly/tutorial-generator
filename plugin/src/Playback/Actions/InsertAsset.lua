local InsertService = game:GetService("InsertService")

local ResolvePath = require(script.Parent.Parent.ResolvePath)

local function apply(action)
	local numericId = tonumber(string.match(action.assetId, "rbxassetid://(%d+)"))
	assert(numericId, `insertAsset: malformed assetId '{action.assetId}'`)

	local parent = ResolvePath.resolve(action.parent)
	assert(parent, `insertAsset: parent '{action.parent}' not found`)

	local model = InsertService:LoadAsset(numericId)
	local inserted = {}
	for _, child in ipairs(model:GetChildren()) do
		if action.name then
			child.Name = action.name
		end
		child.Parent = parent
		table.insert(inserted, child)
	end
	model:Destroy()

	local function undo()
		for _, child in ipairs(inserted) do
			child:Destroy()
		end
	end

	return inserted[1], undo
end

return { apply = apply }
