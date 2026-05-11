local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 192, 192
local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local k = 0
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local fx, fy = x / W, y / H
			local v = math.sin(fx * 10 + t) + math.sin(fy * 10 + t * 0.8)
				+ math.sin((fx + fy) * 8 + t * 1.3)
				+ math.sin(math.sqrt((fx - 0.5) ^ 2 + (fy - 0.5) ^ 2) * 20 + t * 2)
			v = v * 0.25
			buffer.writeu8(buf, k, math.floor((math.sin(v * math.pi) * 0.5 + 0.5) * 255))
			buffer.writeu8(buf, k + 1, math.floor((math.sin(v * math.pi + 2) * 0.5 + 0.5) * 255))
			buffer.writeu8(buf, k + 2, math.floor((math.sin(v * math.pi + 4) * 0.5 + 0.5) * 255))
			buffer.writeu8(buf, k + 3, 255)
			k += 4
		end
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end)

label.ImageContent = Content.fromObject(img)
