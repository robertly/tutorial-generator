local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")

local ResolvePath = require(script.Parent.ResolvePath)

local function apply(focus)
	if not focus then return end

	if focus.selection then
		local paths = if typeof(focus.selection) == "table" then focus.selection else { focus.selection }
		local instances = {}
		for _, path in ipairs(paths) do
			local inst = ResolvePath.resolve(path)
			if inst then
				table.insert(instances, inst)
			end
		end
		Selection:Set(instances)
	end

	if focus.script then
		local script_ = ResolvePath.resolve(focus.script.path)
		if script_ and script_:IsA("LuaSourceContainer") then
			ScriptEditorService:OpenScriptDocumentAsync(script_)
			-- Line highlight: post-open, try to position the cursor.
			local doc = ScriptEditorService:FindScriptDocument(script_)
			if doc and focus.script.startLine then
				local startLine = focus.script.startLine
				local endLine = focus.script.endLine or startLine
				pcall(function()
					doc:ForceSetSelectionAsync(startLine, 1, endLine, 1)
				end)
			end
		end
	end
end

return { apply = apply }
