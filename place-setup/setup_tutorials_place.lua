-- setup_tutorials_place.lua
--
-- Paste into Studio's command bar (View → Command Bar), hit Enter, then
-- File → Save As... "TutorialsPlace.rbxlx". The resulting place file is
-- what lessons using `cloneFromAssets` need to be opened in: their
-- sources resolve against the ReplicatedStorage.TutorialAssets.<id>
-- folders this script builds.
--
-- Idempotent — safe to rerun if you need to add more sample skeletons
-- later. Existing assets under TutorialAssets are never touched.
--
-- To add assets for a new sample:
--   1. Add an entry to SAMPLES with any placeholder children you want.
--   2. Rerun this script.
--   3. Author the real mesh/model/rig in Studio and replace the placeholders.
--   4. Save the place file.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Declared assets per sample. Keep in sync with each lesson's `assets:`
-- block. Placeholder instances below are stand-ins — replace with real
-- content once authored.
local SAMPLES: { [string]: { [string]: (parent: Instance) -> () } } = {
	-- Example: if raycast-basics gains an EmitterRig, uncomment and extend.
	-- ["raycast-basics"] = {
	-- 	EmitterRig = function(parent)
	-- 		local m = Instance.new("Model")
	-- 		m.Name = "EmitterRig"
	-- 		local p = Instance.new("Part")
	-- 		p.Name = "Core"
	-- 		p.Size = Vector3.new(2, 2, 2)
	-- 		p.Material = Enum.Material.Neon
	-- 		p.BrickColor = BrickColor.new("Really red")
	-- 		p.Parent = m
	-- 		m.PrimaryPart = p
	-- 		m.Parent = parent
	-- 	end,
	-- },
}

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local tutorialAssets = getOrCreateFolder(ReplicatedStorage, "TutorialAssets")

local created = 0
local skipped = 0
for sampleId, assetMap in pairs(SAMPLES) do
	local sampleFolder = getOrCreateFolder(tutorialAssets, sampleId)
	for assetName, builder in pairs(assetMap) do
		if sampleFolder:FindFirstChild(assetName) then
			skipped += 1
		else
			builder(sampleFolder)
			created += 1
		end
	end
end

print(
	`[TutorialsPlace setup] ReplicatedStorage.TutorialAssets ready. ` ..
	`Created: {created}, already present: {skipped}. ` ..
	`Now: File → Save As → TutorialsPlace.rbxlx`
)
