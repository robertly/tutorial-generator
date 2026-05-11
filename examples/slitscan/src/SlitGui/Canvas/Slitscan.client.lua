local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 256, 256
local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local k = 0
	for y = 0, H - 1 do
		-- Each row reads a different point in "time" based on its vertical position.
		local rowT = t + y * 0.02
		for x = 0, W - 1 do
			local fx = x / W
			local r = math.sin(fx * 10 + rowT * 2) * 0.5 + 0.5
			local g = math.sin(fx * 10 + rowT * 2 + 2) * 0.5 + 0.5
			local b = math.sin(fx * 10 + rowT * 2 + 4) * 0.5 + 0.5
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
