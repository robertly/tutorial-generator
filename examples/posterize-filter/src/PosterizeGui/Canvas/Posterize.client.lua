local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 256, 256
local LEVELS = 4

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local function posterize(v)
	return math.floor(v / 255 * (LEVELS - 1) + 0.5) / (LEVELS - 1) * 255
end

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local k = 0
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local fx, fy = x / W - 0.5, y / H - 0.5
			local d = math.sqrt(fx * fx + fy * fy)
			local r = (math.sin(d * 20 - t * 2) * 0.5 + 0.5) * 255
			local g = (math.sin(d * 20 - t * 2 + 2) * 0.5 + 0.5) * 255
			local b = (math.sin(d * 20 - t * 2 + 4) * 0.5 + 0.5) * 255
			buffer.writeu8(buf, k, math.floor(posterize(r)))
			buffer.writeu8(buf, k + 1, math.floor(posterize(g)))
			buffer.writeu8(buf, k + 2, math.floor(posterize(b)))
			buffer.writeu8(buf, k + 3, 255)
			k += 4
		end
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end)

label.ImageContent = Content.fromObject(img)
