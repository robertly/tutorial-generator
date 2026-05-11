local AssetService = game:GetService("AssetService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local W, H = 512, 512
local BRUSH_R = 12

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
img:DrawRectangle(Vector2.zero, img.Size, Color3.new(1, 1, 1), 0, Enum.ImageCombineType.Overwrite)
label.ImageContent = Content.fromObject(img)

local surfaceGui = label.Parent
local part = surfaceGui.Adornee or surfaceGui.Parent

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local painting = false

local function tryPaint()
	if mouse.Target ~= part then return end
	local ap, as = label.AbsolutePosition, label.AbsoluteSize
	local fx = (mouse.X - ap.X) / as.X
	local fy = (mouse.Y - ap.Y) / as.Y
	if fx < 0 or fx > 1 or fy < 0 or fy > 1 then return end
	img:DrawCircle(
		Vector2.new(fx * W, fy * H), BRUSH_R,
		Color3.fromHSV(tick() % 1, 0.8, 1),
		0, Enum.ImageCombineType.AlphaBlend
	)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		painting = true
		tryPaint()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		painting = false
	end
end)

mouse.Move:Connect(function()
	if painting then tryPaint() end
end)
