local InsertService = game:GetService("InsertService")

local ResolvePath = require(script.Parent.Parent.ResolvePath)

-- action: { op = "insertAsset", assetId, parent, name? }
-- assetId is "rbxassetid://12345". We pull out the numeric id and call
-- InsertService:LoadAsset (works in Studio with sufficient permissions).
local function apply(action)
	local numericId = tonumber(string.match(action.assetId, "rbxassetid://(%d+)"))
	assert(numericId, `insertAsset: malformed assetId '{action.assetId}'`)

	local parent = ResolvePath.resolve(action.parent)
	assert(parent, `insertAsset: parent '{action.parent}' not found`)

	local model = InsertService:LoadAsset(numericId)
	-- LoadAsset returns a Model wrapping the actual asset. Reparent children to
	-- the requested parent and discard the wrapper.
	local inserted = {}
	for _, child in ipairs(model:GetChildren()) do
		if action.name then
			child.Name = action.name
		end
		child.Parent = parent
		table.insert(inserted, child)
	end
	model:Destroy()

	return inserted[1]
end

return { apply = apply }
