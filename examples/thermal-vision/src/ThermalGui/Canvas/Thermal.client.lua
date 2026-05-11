local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 256, 256
local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local function heatmap(t)
	-- jet-ish palette
	local r = math.clamp(1.5 - math.abs(t * 4 - 3), 0, 1)
	local g = math.clamp(1.5 - math.abs(t * 4 - 2), 0, 1)
	local b = math.clamp(1.5 - math.abs(t * 4 - 1), 0, 1)
	return r, g, b
end

local time = 0
RunService.Heartbeat:Connect(function(dt)
	time += dt
	local k = 0
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local fx, fy = x / W - 0.5, y / H - 0.5
			-- two moving heat sources
			local d1 = math.sqrt((fx - math.sin(time) * 0.3) ^ 2 + (fy - math.cos(time) * 0.3) ^ 2)
			local d2 = math.sqrt((fx + math.sin(time * 1.3) * 0.3) ^ 2 + (fy + math.cos(time * 0.9) * 0.3) ^ 2)
			local heat = math.clamp(0.2 / (d1 + 0.05) + 0.15 / (d2 + 0.05), 0, 1)
			local r, g, b = heatmap(heat)
			buffer.writeu8(buf, k, math.floor(r * 255))
			buffer.writeu8(buf, k + 1, math.floor(g * 255))
			buffer.writeu8(buf, k + 2, math.floor(b * 255))
			buffer.writeu8(buf, k + 3, 255)
			k += 4
		end
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end)

label.ImageContent = Content.fromObject(img)
