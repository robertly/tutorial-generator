local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 192, 192
local DAMPING = 0.985

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })

local cur = table.create(W * H, 0)
local prev = table.create(W * H, 0)
local buf = buffer.create(W * H * 4)

local function idx(x, y) return y * W + x + 1 end

local function step()
	for y = 1, H - 2 do
		for x = 1, W - 2 do
			local i = idx(x, y)
			local v = (prev[idx(x - 1, y)] + prev[idx(x + 1, y)]
				+ prev[idx(x, y - 1)] + prev[idx(x, y + 1)]) * 0.5 - cur[i]
			cur[i] = v * DAMPING
		end
	end
	cur, prev = prev, cur
end

local function draw()
	local k = 0
	for i = 1, W * H do
		local v = math.clamp(128 + prev[i] * 6, 0, 255)
		buffer.writeu8(buf, k, math.floor(v * 0.3))
		buffer.writeu8(buf, k + 1, math.floor(v * 0.6))
		buffer.writeu8(buf, k + 2, math.floor(v))
		buffer.writeu8(buf, k + 3, 255)
		k += 4
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end

label.ImageContent = Content.fromObject(img)

label.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local ap, as = label.AbsolutePosition, label.AbsoluteSize
		local px = math.floor((input.Position.X - ap.X) / as.X * W)
		local py = math.floor((input.Position.Y - ap.Y) / as.Y * H)
		for dy = -2, 2 do
			for dx = -2, 2 do
				local x = math.clamp(px + dx, 0, W - 1)
				local y = math.clamp(py + dy, 0, H - 1)
				prev[idx(x, y)] = 200
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	step()
	draw()
end)
