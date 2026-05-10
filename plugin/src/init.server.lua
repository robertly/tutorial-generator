-- Plugin entry point. Creates a toolbar button + DockWidget and mounts the
-- MVP UI driving the first embedded lesson.

local Lessons = require(script.Lessons)
local UI = require(script.UI)

local toolbar = plugin:CreateToolbar("Tutorials")
local openButton = toolbar:CreateButton(
	"OpenTutorials",
	"Open the tutorial library",
	"",
	"Tutorials"
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	420, 640,
	320, 400
)

local widget = plugin:CreateDockWidgetPluginGui("TutorialPlugin", widgetInfo)
widget.Title = "Tutorials"
widget.Name = "TutorialPlugin"

openButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

UI.create(widget, Lessons)

plugin.Unloading:Connect(function()
	widget:Destroy()
end)
