local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local W, H = 256, 256
local WORLD_RADIUS = 200
local REVEAL_RADIUS = 10

local fogLabel = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
img:DrawRectangle(Vector2.zero, img.Size, Color3.new(0, 0, 0), 0, Enum.ImageCombineType.Overwrite)
fogLabel.ImageContent = Content.fromObject(img)

local player = Players.LocalPlayer

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local x = (hrp.Position.X / WORLD_RADIUS + 1) * 0.5 * W
	local y = (hrp.Position.Z / WORLD_RADIUS + 1) * 0.5 * H
	img:DrawCircle(Vector2.new(x, y), REVEAL_RADIUS, Color3.new(0, 0, 0), 1, Enum.ImageCombineType.Overwrite)
end)
