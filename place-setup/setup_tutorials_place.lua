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
	["raycast-basics"] = {
		-- A visible target the raycast lesson drops into Workspace. Big
		-- enough that the downward ray from the emitter can't miss; neon
		-- so the hit position reads clearly in the viewport.
		EmitterRig = function(parent)
			local model = Instance.new("Model")
			model.Name = "EmitterRig"

			local base = Instance.new("Part")
			base.Name = "Base"
			base.Anchored = true
			base.Size = Vector3.new(10, 1, 10)
			base.Position = Vector3.new(0, 1, 0)
			base.Material = Enum.Material.SmoothPlastic
			base.BrickColor = BrickColor.new("Dark stone grey")
			base.Parent = model

			local bullseye = Instance.new("Part")
			bullseye.Name = "Bullseye"
			bullseye.Anchored = true
			bullseye.Shape = Enum.PartType.Cylinder
			bullseye.Size = Vector3.new(0.2, 3, 3)
			-- Rotate so the flat face points up (cylinders extrude along +X).
			bullseye.CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90))
			bullseye.Material = Enum.Material.Neon
			bullseye.BrickColor = BrickColor.new("Really red")
			bullseye.Parent = model

			model.PrimaryPart = base
			model.Parent = parent
		end,
	},
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
