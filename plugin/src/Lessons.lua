-- MVP: lessons embedded as Lua tables instead of fetched YAML.
-- Shape matches schema.json. Once the Fetch layer lands, these become the
-- offline defaults; fetched lessons are appended on top.

local raycastBasics = {
	schemaVersion = 1,
	id = "raycast-basics",
	title = "Raycast basics",
	goal = "Cast a ray from a Part and react to what it hits.",
	tags = { "raycasting", "beginner", "events" },

	steps = {
		{
			id = "s1-intro",
			type = "narrative",
			body = "Raycasting lets you detect what a ray crosses in the world. We'll build an emitter Part in Workspace that fires a ray straight down whenever it's touched.",
		},
		{
			id = "s2-create-emitter",
			type = "scripted",
			body = "Create the Emitter part in Workspace — flat, anchored, red.",
			action = {
				op = "createInstance",
				class = "Part",
				parent = "Workspace",
				props = {
					Name = "Emitter",
					Anchored = true,
					Size = { 4, 1, 4 },
					Position = { 0, 10, 0 },
					Material = "Enum.Material.Metal",
					BrickColor = "Really red",
				},
			},
			focus = {
				selection = "Workspace.Emitter",
			},
		},
		{
			id = "s3-add-handler",
			type = "codeEdit",
			body = "Add a Handler script under the emitter. On Touched, cast a ray 50 studs down.",
			target = {
				path = "Workspace.Emitter.Handler",
				create = true,
				class = "Script",
			},
			source = [[local emitter = script.Parent

local function onTouch(hit)
	local origin = emitter.Position
	local direction = Vector3.yAxis * -50
	local result = workspace:Raycast(origin, direction)
	if result then
		print("Ray hit:", result.Instance:GetFullName(), "at", result.Position)
	else
		print("Ray hit nothing.")
	end
end

emitter.Touched:Connect(onTouch)
]],
			focus = {
				script = {
					path = "Workspace.Emitter.Handler",
				},
			},
		},
		{
			id = "s4-ignore-self",
			type = "codeEdit",
			body = "Add a RaycastParams that filters out the emitter so we only see other things.",
			target = {
				path = "Workspace.Emitter.Handler",
			},
			source = [[local emitter = script.Parent

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { emitter }

local function onTouch(hit)
	local origin = emitter.Position
	local direction = Vector3.yAxis * -50
	local result = workspace:Raycast(origin, direction, params)
	if result then
		print("Ray hit:", result.Instance:GetFullName(), "at", result.Position)
	else
		print("Ray hit nothing.")
	end
end

emitter.Touched:Connect(onTouch)
]],
			focus = {
				script = {
					path = "Workspace.Emitter.Handler",
					startLine = 3,
					endLine = 5,
				},
			},
		},
		{
			id = "s5-add-target",
			type = "scripted",
			body = "Drop a plain Part below the emitter so the ray has something to hit.",
			action = {
				op = "createInstance",
				class = "Part",
				parent = "Workspace",
				props = {
					Name = "Target",
					Anchored = true,
					Size = { 4, 1, 4 },
					Position = { 0, 2, 0 },
					BrickColor = "Bright green",
				},
			},
			focus = {
				selection = "Workspace.Target",
			},
		},
		{
			id = "s6-continuous",
			type = "prompt",
			body = "Make the ray fire continuously instead of only on Touched — a good moment to hand off to Assistant. After applying, press Playtest to try it: walk onto the emitter and watch the Output window.",
			suggestedPrompt = "Modify Workspace.Emitter.Handler so the ray fires every 0.5 seconds using a while loop and task.wait, instead of firing on Touched. When the ray hits Workspace.Target, print 'Target spotted!'. Keep the RaycastParams exclusion for the emitter itself.",
			focus = {
				script = {
					path = "Workspace.Emitter.Handler",
				},
			},
		},
	},
}

local partColorCycle = {
	schemaVersion = 1,
	id = "part-color-cycle",
	title = "Cycling a Part's color",
	goal = "Animate a property on an anchored Part with a simple loop.",
	tags = { "animation", "beginner" },

	steps = {
		{
			id = "s1-intro",
			type = "narrative",
			body = "A lot of 'aliveness' in Roblox worlds comes from simple property-over-time loops. We'll make a Part cycle through colors once per second.",
		},
		{
			id = "s2-create-part",
			type = "scripted",
			body = "Make a cube hovering at eye level. Anchored so nothing pushes it around.",
			action = {
				op = "createInstance",
				class = "Part",
				parent = "Workspace",
				props = {
					Name = "Cycler",
					Anchored = true,
					Size = { 3, 3, 3 },
					Position = { 0, 5, 0 },
					Material = "Enum.Material.Neon",
					BrickColor = "Electric blue",
				},
			},
			focus = {
				selection = "Workspace.Cycler",
			},
		},
		{
			id = "s3-add-cycler",
			type = "codeEdit",
			body = "Drop a Script under the Part that cycles three colors on a timer.",
			target = {
				path = "Workspace.Cycler.Cycle",
				create = true,
				class = "Script",
			},
			source = [[local part = script.Parent

local colors = {
	Color3.fromRGB(235, 70, 90),
	Color3.fromRGB(80, 220, 130),
	Color3.fromRGB(90, 130, 255),
}

local i = 1
while true do
	part.Color = colors[i]
	i = i % #colors + 1
	task.wait(1)
end
]],
			focus = {
				script = {
					path = "Workspace.Cycler.Cycle",
				},
			},
		},
		{
			id = "s4-try-tween",
			type = "prompt",
			body = "Hard color swaps are stark. Ask Assistant to smooth them out with TweenService. When applied, press Playtest — the cube should cycle red → green → blue on a loop.",
			suggestedPrompt = "Replace Workspace.Cycler.Cycle so the part tweens between the three colors over 1 second each using TweenService. Loop forever.",
			focus = {
				script = {
					path = "Workspace.Cycler.Cycle",
				},
			},
		},
	},
}

return {
	raycastBasics,
	partColorCycle,
}
