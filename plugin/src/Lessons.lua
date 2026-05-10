-- MVP: lessons embedded as Lua tables instead of fetched YAML.
-- Shape matches schema.json. Once the YAML parser + Fetch layer land, this
-- module becomes the offline fallback.

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
			body = "Make the ray fire continuously instead of only on Touched — a good moment to hand off to Assistant.",
			suggestedPrompt = "Modify Workspace.Emitter.Handler so the ray fires every 0.5 seconds using a while loop and task.wait, instead of firing on Touched. When the ray hits Workspace.Target, print 'Target spotted!'. Keep the RaycastParams exclusion for the emitter itself.",
			focus = {
				script = {
					path = "Workspace.Emitter.Handler",
				},
			},
		},
	},
}

return {
	raycastBasics,
}
