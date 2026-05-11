local AssetService = game:GetService("AssetService")

local W, H = 256, 256
local NUM_SEEDS = 40

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local seeds = {}
for i = 1, NUM_SEEDS do
	seeds[i] = {
		x = math.random() * W,
		y = math.random() * H,
		r = math.random(30, 230),
		g = math.random(30, 230),
		b = math.random(30, 230),
	}
end

local k = 0
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local best, bestDist = seeds[1], math.huge
		for _, s in seeds do
			local dx, dy = x - s.x, y - s.y
			local d = dx * dx + dy * dy
			if d < bestDist then
				bestDist = d
				best = s
			end
		end
		local edge = math.clamp(math.sqrt(bestDist) / 15, 0.5, 1)
		buffer.writeu8(buf, k, math.floor(best.r * edge))
		buffer.writeu8(buf, k + 1, math.floor(best.g * edge))
		buffer.writeu8(buf, k + 2, math.floor(best.b * edge))
		buffer.writeu8(buf, k + 3, 255)
		k += 4
	end
end

img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
label.ImageContent = Content.fromObject(img)
