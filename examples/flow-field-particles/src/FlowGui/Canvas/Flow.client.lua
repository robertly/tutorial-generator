local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 256, 256
local NUM_PARTICLES = 500
local FADE = 8

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

img:DrawRectangle(Vector2.zero, img.Size, Color3.new(0, 0, 0), 0, Enum.ImageCombineType.Overwrite)

local particles = {}
for i = 1, NUM_PARTICLES do
	particles[i] = { x = math.random() * W, y = math.random() * H, hue = math.random() }
end

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	-- Fade the whole image using ReadPixelsBuffer + subtract
	local size = img.Size
	img:ReadPixelsBuffer(Vector2.zero, size, buf)
	for k = 0, W * H * 4 - 1, 4 do
		buffer.writeu8(buf, k, math.max(0, buffer.readu8(buf, k) - FADE))
		buffer.writeu8(buf, k + 1, math.max(0, buffer.readu8(buf, k + 1) - FADE))
		buffer.writeu8(buf, k + 2, math.max(0, buffer.readu8(buf, k + 2) - FADE))
	end
	img:WritePixelsBuffer(Vector2.zero, size, buf)

	for _, p in particles do
		local angle = (math.sin(p.x * 0.02 + t * 0.3) + math.cos(p.y * 0.02)) * math.pi
		p.x += math.cos(angle) * 2
		p.y += math.sin(angle) * 2
		if p.x < 0 or p.x >= W or p.y < 0 or p.y >= H then
			p.x = math.random() * W
			p.y = math.random() * H
		end
		img:DrawCircle(
			Vector2.new(p.x, p.y), 1,
			Color3.fromHSV(p.hue, 0.8, 1),
			0, Enum.ImageCombineType.AlphaBlend
		)
	end
end)

label.ImageContent = Content.fromObject(img)
