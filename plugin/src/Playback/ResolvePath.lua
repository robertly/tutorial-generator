-- Resolve a dot-path like "Workspace.Emitter.Handler" to an Instance.
-- Paths start at a DataModel service (Workspace, ReplicatedStorage, etc.)
-- Not at `game`. Case-sensitive. Names with spaces are allowed in
-- non-leading segments.

local function split(path: string): { string }
	local parts = {}
	for segment in string.gmatch(path, "[^.]+") do
		table.insert(parts, segment)
	end
	return parts
end

local function resolve(path: string): Instance?
	local parts = split(path)
	if #parts == 0 then
		return nil
	end

	local service = game:FindService(parts[1])
	if not service then
		return nil
	end

	local current: Instance = service
	for i = 2, #parts do
		local child = current:FindFirstChild(parts[i])
		if not child then
			return nil
		end
		current = child
	end
	return current
end

-- Resolve a parent path, returning the parent Instance plus a leaf name if
-- we want to create a child at the end. e.g. "Workspace.Emitter.Handler"
-- with createMissingLeaf=true returns (Workspace.Emitter, "Handler").
local function resolveParentAndName(path: string): (Instance?, string?)
	local parts = split(path)
	if #parts < 2 then
		return nil, nil
	end

	local leaf = parts[#parts]
	local parentParts = table.move(parts, 1, #parts - 1, 1, {})
	local parent = resolve(table.concat(parentParts, "."))
	return parent, leaf
end

return {
	resolve = resolve,
	resolveParentAndName = resolveParentAndName,
	split = split,
}
