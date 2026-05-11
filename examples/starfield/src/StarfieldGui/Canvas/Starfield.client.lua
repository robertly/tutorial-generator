local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 256, 256
local NUM_STARS = 200

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })

local stars = {}
for i = 1, NUM_STARS do
	stars[i] = {
		x = math.random() * W - W / 2,
		y = math.random() * H - H / 2,
		z = math.random() * W,
	}
end

RunService.Heartbeat:Connect(function(dt)
	img:DrawRectangle(Vector2.zero, img.Size, Color3.new(0, 0, 0.05), 0, Enum.ImageCombineType.Overwrite)
	for _, s in stars do
		s.z -= dt * 100
		if s.z <= 1 then
			s.x = math.random() * W - W / 2
			s.y = math.random() * H - H / 2
			s.z = W
		end
		local px = s.x / s.z * W + W / 2
		local py = s.y / s.z * H + H / 2
		local bright = math.clamp(1 - s.z / W, 0, 1)
		local r = math.floor(bright * 2) + 1
		if px >= 0 and px < W and py >= 0 and py < H then
			img:DrawCircle(Vector2.new(px, py), r, Color3.new(bright, bright, bright), 0, Enum.ImageCombineType.AlphaBlend)
		end
	end
end)

label.ImageContent = Content.fromObject(img)
