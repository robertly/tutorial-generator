local AssetService = game:GetService("AssetService")

local W, H = 256, 256
local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

-- Procedural source: radial gradient + noise
local gray = table.create(W * H, 0)
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local fx, fy = x / W - 0.5, y / H - 0.5
		local v = 1 - math.sqrt(fx * fx + fy * fy) * 1.3 + (math.random() - 0.5) * 0.05
		gray[y * W + x + 1] = math.clamp(v, 0, 1)
	end
end

-- Floyd-Steinberg dither to 1-bit
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local i = y * W + x + 1
		local old = gray[i]
		local new = old < 0.5 and 0 or 1
		gray[i] = new
		local err = old - new
		if x + 1 < W then gray[i + 1] += err * 7 / 16 end
		if y + 1 < H then
			if x > 0 then gray[i + W - 1] += err * 3 / 16 end
			gray[i + W] += err * 5 / 16
			if x + 1 < W then gray[i + W + 1] += err * 1 / 16 end
		end
	end
end

local k = 0
for i = 1, W * H do
	local v = math.floor(gray[i] * 255)
	buffer.writeu8(buf, k, v)
	buffer.writeu8(buf, k + 1, v)
	buffer.writeu8(buf, k + 2, v)
	buffer.writeu8(buf, k + 3, 255)
	k += 4
end

img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
label.ImageContent = Content.fromObject(img)
