local AssetService = game:GetService("AssetService")

local part = script.Parent
local W, H = 256, 256
local BRICK_W, BRICK_H = 64, 24
local MORTAR = 3

local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
img:DrawRectangle(Vector2.zero, img.Size, Color3.fromRGB(40, 40, 40), 0, Enum.ImageCombineType.Overwrite)

for y = 0, H // BRICK_H do
	local offset = (y % 2) * (BRICK_W / 2)
	for x = -1, W // BRICK_W + 1 do
		local px = x * BRICK_W + offset + MORTAR
		local py = y * BRICK_H + MORTAR
		local shade = 0.75 + math.random() * 0.2
		local color = Color3.fromRGB(150 * shade, 60 * shade, 45 * shade)
		img:DrawRectangle(
			Vector2.new(px, py),
			Vector2.new(BRICK_W - MORTAR * 2, BRICK_H - MORTAR * 2),
			color, 0, Enum.ImageCombineType.Overwrite
		)
	end
end

local surface = Instance.new("SurfaceAppearance")
surface.ColorMap = Content.fromObject(img)
surface.Parent = part
