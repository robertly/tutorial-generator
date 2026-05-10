-- A tiny built-in lesson so the plugin isn't empty on first launch.
-- Fetched lessons appear alongside it. If a fetched lesson shares this
-- id, it's shown separately — dedupe manually via ⚙ Manage if needed.

local helloWorld = {
	schemaVersion = 1,
	id = "hello-world",
	title = "Hello, world",
	goal = "The shortest possible tutorial: one Part, one Script, one greeting.",
	tags = { "beginner", "intro" },

	steps = {
		{
			id = "s1-welcome",
			type = "narrative",
			body = "Welcome! This is a tiny tutorial to show you how playback works. Click Next to watch each step apply in real time. You can also scrub back and forth with the numbered dots above.",
		},
		{
			id = "s2-create-greeter",
			type = "scripted",
			body = "First, a glowing neon Part to greet visitors. Anchored so it stays put, neon so it pops.",
			action = {
				op = "createInstance",
				class = "Part",
				parent = "Workspace",
				props = {
					Name = "Greeter",
					Anchored = true,
					Size = { 4, 4, 4 },
					Position = { 0, 5, 0 },
					Material = "Enum.Material.Neon",
					BrickColor = "Toothpaste",
				},
			},
			focus = {
				selection = "Workspace.Greeter",
			},
		},
		{
			id = "s3-add-hello",
			type = "codeEdit",
			body = "Add a Script that prints a greeting whenever something touches the Greeter.",
			target = {
				path = "Workspace.Greeter.Hello",
				create = true,
				class = "Script",
			},
			source = [[local greeter = script.Parent

greeter.Touched:Connect(function(other)
	print("Hello from the Greeter — you were touched by " .. other.Name)
end)
]],
			focus = {
				script = {
					path = "Workspace.Greeter.Hello",
				},
			},
		},
		{
			id = "s4-playtest",
			type = "narrative",
			body = "Press ▶ Play (or F5). Walk your character into the glowing cyan cube — you should see a 'Hello from the Greeter...' line in the Output window. Shift+F5 to stop. That's it — now try fetching a real repo from ⚙ Manage.",
		},
	},
}

return {
	helloWorld,
}
