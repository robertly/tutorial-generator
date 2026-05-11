-- Preflight check: before a lesson starts playback, verify the DataModel
-- has everything the lesson declares it needs. Catches the "you forgot to
-- open TutorialsPlace.rbxlx" failure mode up front rather than crashing
-- mid-step with a stack trace.

local ResolvePath = require(script.Parent.ResolvePath)

-- Returns (ok: boolean, message: string?). When ok=false, message is a
-- user-facing multi-line explanation of what's missing.
local function check(lesson): (boolean, string?)
	local assets = lesson.assets
	if not assets or #assets == 0 then
		return true, nil
	end

	-- If the lesson declares any bundled assets, the TutorialAssets folder
	-- must exist at minimum. Treat that as the primary failure mode because
	-- the message is more actionable than "asset X is missing".
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local tutorialAssets = ReplicatedStorage:FindFirstChild("TutorialAssets")

	if not tutorialAssets then
		return false, (
			"This lesson uses bundled assets, but ReplicatedStorage.TutorialAssets isn't in this place.\n\n" ..
			"Open TutorialsPlace.rbxlx from the samples repo before running this lesson. Lessons without an `assets:` block still work in any place."
		)
	end

	-- Walk each declared asset source and report the specific ones missing.
	local missing: { string } = {}
	for _, asset in ipairs(assets) do
		if asset.source then
			if not ResolvePath.resolve(asset.source) then
				table.insert(missing, asset.source)
			end
		end
		-- assetId-only assets aren't checked here; insertAsset will error
		-- at playback time if the marketplace fetch fails, which is fine.
	end

	if #missing > 0 then
		local lines = { "This lesson's bundled assets are missing from TutorialAssets:" }
		for _, src in ipairs(missing) do
			table.insert(lines, "  • " .. src)
		end
		table.insert(lines, "")
		table.insert(lines, "Rerun place-setup/setup_tutorials_place.lua in the command bar and save TutorialsPlace.rbxlx, then reopen this place.")
		return false, table.concat(lines, "\n")
	end

	return true, nil
end

return { check = check }
