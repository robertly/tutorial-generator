local AssetService = game:GetService("AssetService")

local W, H = 256, 256
local PALETTE = {
	{ 20, 12, 28 }, { 68, 36, 52 }, { 48, 52, 109 }, { 78, 74, 78 },
	{ 133, 76, 48 }, { 52, 101, 36 }, { 208, 70, 72 }, { 117, 113, 97 },
	{ 89, 125, 206 }, { 210, 125, 44 }, { 133, 149, 161 }, { 109, 170, 44 },
	{ 210, 170, 153 }, { 109, 194, 202 }, { 218, 212, 94 }, { 222, 238, 214 },
}

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local function nearest(r, g, b)
	local best, bestD = PALETTE[1], math.huge
	for _, c in PALETTE do
		local dr, dg, db = r - c[1], g - c[2], b - c[3]
		local d = dr * dr + dg * dg + db * db
		if d < bestD then bestD, best = d, c end
	end
	return best
end

local k = 0
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local fx, fy = x / W, y / H
		local r = math.floor((math.sin(fx * 6) * 0.5 + 0.5) * 255)
		local g = math.floor((math.sin(fy * 6 + 2) * 0.5 + 0.5) * 255)
		local b = math.floor((math.sin((fx + fy) * 4 + 4) * 0.5 + 0.5) * 255)
		local c = nearest(r, g, b)
		buffer.writeu8(buf, k, c[1])
		buffer.writeu8(buf, k + 1, c[2])
		buffer.writeu8(buf, k + 2, c[3])
		buffer.writeu8(buf, k + 3, 255)
		k += 4
	end
end

img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
label.ImageContent = Content.fromObject(img)
