local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 256, 256
local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local function sdCircle(px, py, cx, cy, r)
	return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2) - r
end

local function sdBox(px, py, cx, cy, bx, by)
	local dx = math.max(math.abs(px - cx) - bx, 0)
	local dy = math.max(math.abs(py - cy) - by, 0)
	return math.sqrt(dx * dx + dy * dy)
end

local function smin(a, b, k)
	local h = math.clamp(0.5 + 0.5 * (b - a) / k, 0, 1)
	return b * (1 - h) + a * h - k * h * (1 - h)
end

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local k = 0
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local c1 = sdCircle(x, y, 96 + math.sin(t) * 30, 128, 30)
			local c2 = sdCircle(x, y, 160 + math.cos(t * 1.3) * 30, 128, 30)
			local b1 = sdBox(x, y, 128, 80 + math.sin(t * 0.7) * 20, 40, 20)
			local d = smin(smin(c1, c2, 20), b1, 20)
			local inside = d < 0
			local edge = math.abs(d) < 1.5
			local col = inside and (0.4 + 0.6 * math.exp(d * 0.03)) or 0
			local r = edge and 1 or col * 0.9
			local g = edge and 0.4 or col * 0.5
			local b = edge and 0.1 or col * 0.2
			buffer.writeu8(buf, k, math.floor(math.clamp(r, 0, 1) * 255))
			buffer.writeu8(buf, k + 1, math.floor(math.clamp(g, 0, 1) * 255))
			buffer.writeu8(buf, k + 2, math.floor(math.clamp(b, 0, 1) * 255))
			buffer.writeu8(buf, k + 3, 255)
			k += 4
		end
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end)

label.ImageContent = Content.fromObject(img)
