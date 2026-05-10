-- Minimal line-level diff for codeEdit previews. Computes an LCS between
-- two arrays of lines and emits a stream of { kind, text } events where
-- kind is "same", "add", or "remove".
--
-- Not fast — O(m*n) memory — but codeEdit sources are tens of lines at
-- most, so it doesn't matter.

local function splitLines(s: string): { string }
	local out = {}
	for line in string.gmatch(s .. "\n", "([^\n]*)\n") do
		table.insert(out, line)
	end
	-- gmatch leaves a trailing empty "" from the appended newline; drop it.
	if #out > 0 and out[#out] == "" then
		table.remove(out, #out)
	end
	return out
end

-- Classic LCS DP returning a 2-D length table.
local function lcsLengths(a: { string }, b: { string })
	local m, n = #a, #b
	local dp = table.create(m + 1)
	for i = 0, m do
		dp[i] = table.create(n + 1, 0)
	end
	for i = 1, m do
		for j = 1, n do
			if a[i] == b[j] then
				dp[i][j] = dp[i - 1][j - 1] + 1
			else
				dp[i][j] = math.max(dp[i - 1][j], dp[i][j - 1])
			end
		end
	end
	return dp
end

local function diff(oldSource: string, newSource: string)
	local a = splitLines(oldSource or "")
	local b = splitLines(newSource or "")
	local dp = lcsLengths(a, b)

	local events = {}
	local i, j = #a, #b
	while i > 0 or j > 0 do
		if i > 0 and j > 0 and a[i] == b[j] then
			table.insert(events, 1, { kind = "same", text = a[i] })
			i -= 1
			j -= 1
		elseif j > 0 and (i == 0 or dp[i][j - 1] >= dp[i - 1][j]) then
			table.insert(events, 1, { kind = "add", text = b[j] })
			j -= 1
		else
			table.insert(events, 1, { kind = "remove", text = a[i] })
			i -= 1
		end
	end
	return events
end

local function escape(text: string): string
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	return text
end

-- Render diff events as a single RichText string for a TextLabel.
-- Colors match a muted terminal diff: green for adds, red for removes,
-- faded gray for context.
local function toRichText(events): string
	local lines = {}
	for _, e in ipairs(events) do
		local text = escape(e.text)
		if e.kind == "add" then
			table.insert(lines, `<font color="#7ec37e">+ {text}</font>`)
		elseif e.kind == "remove" then
			table.insert(lines, `<font color="#d06666">- {text}</font>`)
		else
			table.insert(lines, `<font color="#888888">  {text}</font>`)
		end
	end
	return table.concat(lines, "\n")
end

return {
	diff = diff,
	toRichText = toRichText,
	splitLines = splitLines,
}
