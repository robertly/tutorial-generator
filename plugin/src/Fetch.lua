-- Fetch lessons over HTTPS. JSON is the wire format — YAML is the human
-- authoring format, and /tutorial-generate emits both side-by-side.
--
-- Usage:
--   local lesson, err = Fetch.fromUrl("https://.../lesson.json")

local HttpService = game:GetService("HttpService")

local ALLOWED_STEP_TYPES = {
	narrative = true,
	scripted = true,
	codeEdit = true,
	prompt = true,
}

local ALLOWED_ACTION_OPS = {
	createInstance = true,
	setProperty = true,
	deleteInstance = true,
	parentTo = true,
	cloneFromAssets = true,
	insertAsset = true,
}

local function validate(lesson): string?
	if typeof(lesson) ~= "table" then
		return "lesson is not a table"
	end
	if lesson.schemaVersion ~= 1 then
		return `unsupported schemaVersion: {tostring(lesson.schemaVersion)}`
	end
	if typeof(lesson.id) ~= "string" or lesson.id == "" then
		return "missing or invalid lesson.id"
	end
	if typeof(lesson.title) ~= "string" or lesson.title == "" then
		return "missing or invalid lesson.title"
	end
	if typeof(lesson.steps) ~= "table" or #lesson.steps == 0 then
		return "lesson.steps must be a non-empty array"
	end

	local seen = {}
	for i, step in ipairs(lesson.steps) do
		if typeof(step) ~= "table" then
			return `step[{i}] is not a table`
		end
		if typeof(step.id) ~= "string" or step.id == "" then
			return `step[{i}].id missing`
		end
		if seen[step.id] then
			return `duplicate step id '{step.id}'`
		end
		seen[step.id] = true
		if not ALLOWED_STEP_TYPES[step.type] then
			return `step '{step.id}' has invalid type '{tostring(step.type)}'`
		end
		if step.type == "scripted" then
			if typeof(step.action) ~= "table" then
				return `step '{step.id}' scripted is missing action`
			end
			if not ALLOWED_ACTION_OPS[step.action.op] then
				return `step '{step.id}' has invalid action.op '{tostring(step.action.op)}'`
			end
		elseif step.type == "codeEdit" then
			if typeof(step.target) ~= "table" or typeof(step.target.path) ~= "string" then
				return `step '{step.id}' codeEdit is missing target.path`
			end
			if typeof(step.source) ~= "string" then
				return `step '{step.id}' codeEdit is missing source`
			end
		elseif step.type == "prompt" then
			if typeof(step.suggestedPrompt) ~= "string" or step.suggestedPrompt == "" then
				return `step '{step.id}' prompt is missing suggestedPrompt`
			end
		end
	end

	return nil
end

local function fromUrl(url: string)
	local okGet, bodyOrErr = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if not okGet then
		return nil, `HTTP error: {bodyOrErr}`
	end

	local okDecode, decoded = pcall(function()
		return HttpService:JSONDecode(bodyOrErr)
	end)
	if not okDecode then
		return nil, `JSON parse error: {decoded}`
	end

	local err = validate(decoded)
	if err then
		return nil, err
	end

	return decoded, nil
end

-- Fetch a repo index.json and each lesson it lists.
-- index.json shape: { "samples": [ { id, title, path, tags? }, ... ] }
-- Returns (lessons[], errors[]) — lessons that failed are omitted from
-- the first return and their URLs collected in the second.
local function fromRepoIndex(baseUrl: string)
	local trimmed = if string.sub(baseUrl, -1) == "/"
		then string.sub(baseUrl, 1, -2)
		else baseUrl
	local indexUrl = trimmed .. "/index.json"

	local okGet, bodyOrErr = pcall(function()
		return HttpService:GetAsync(indexUrl)
	end)
	if not okGet then
		return nil, `HTTP error fetching index: {bodyOrErr}`
	end

	local okDecode, decoded = pcall(function()
		return HttpService:JSONDecode(bodyOrErr)
	end)
	if not okDecode then
		return nil, `JSON parse error for index.json: {decoded}`
	end

	if typeof(decoded) ~= "table" or typeof(decoded.samples) ~= "table" then
		return nil, "index.json missing 'samples' array"
	end

	local lessons = {}
	local errors = {}
	for _, entry in ipairs(decoded.samples) do
		if typeof(entry) ~= "table" or typeof(entry.path) ~= "string" then
			table.insert(errors, "index entry missing path")
			continue
		end
		local lessonUrl = trimmed .. "/" .. entry.path
		local lesson, err = fromUrl(lessonUrl)
		if lesson then
			table.insert(lessons, lesson)
		else
			table.insert(errors, `{lessonUrl}: {err}`)
		end
	end

	return lessons, errors
end

return {
	fromUrl = fromUrl,
	fromRepoIndex = fromRepoIndex,
	validate = validate,
}
