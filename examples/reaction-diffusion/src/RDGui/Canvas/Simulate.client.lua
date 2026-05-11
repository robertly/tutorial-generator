local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 128, 128
local DA, DB = 1.0, 0.5
local FEED, KILL = 0.055, 0.062
local STEPS_PER_FRAME = 8

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local a = table.create(W * H, 1)
local b = table.create(W * H, 0)
local a2 = table.create(W * H, 1)
local b2 = table.create(W * H, 0)

-- Seed a square of B
for y = H // 2 - 8, H // 2 + 8 do
	for x = W // 2 - 8, W // 2 + 8 do
		b[y * W + x + 1] = 1
	end
end

local function step()
	for y = 1, H - 2 do
		for x = 1, W - 2 do
			local i = y * W + x + 1
			local av, bv = a[i], b[i]
			local lapA = a[i - 1] + a[i + 1] + a[i - W] + a[i + W] - 4 * av
			local lapB = b[i - 1] + b[i + 1] + b[i - W] + b[i + W] - 4 * bv
			local abb = av * bv * bv
			a2[i] = av + (DA * lapA - abb + FEED * (1 - av))
			b2[i] = bv + (DB * lapB + abb - (KILL + FEED) * bv)
		end
	end
	a, a2 = a2, a
	b, b2 = b2, b
end

RunService.Heartbeat:Connect(function()
	for _ = 1, STEPS_PER_FRAME do step() end
	local k = 0
	for i = 1, W * H do
		local v = math.clamp((a[i] - b[i]) * 255, 0, 255)
		local vi = math.floor(v)
		buffer.writeu8(buf, k, vi)
		buffer.writeu8(buf, k + 1, math.floor(v * 0.6))
		buffer.writeu8(buf, k + 2, math.floor(255 - v * 0.8))
		buffer.writeu8(buf, k + 3, 255)
		k += 4
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end)

label.ImageContent = Content.fromObject(img)
