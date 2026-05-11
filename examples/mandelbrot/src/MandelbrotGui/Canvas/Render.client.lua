local AssetService = game:GetService("AssetService")

local WIDTH, HEIGHT = 256, 256
local MAX_ITER = 64

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(WIDTH, HEIGHT) })
local buf = buffer.create(WIDTH * HEIGHT * 4)

local cx, cy, zoom = -0.5, 0, 1.5

local function render()
	local i = 0
	for y = 0, HEIGHT - 1 do
		local im0 = cy + (y / HEIGHT - 0.5) * 2 * zoom
		for x = 0, WIDTH - 1 do
			local re0 = cx + (x / WIDTH - 0.5) * 2 * zoom
			local re, imv, n = 0, 0, 0
			while re * re + imv * imv < 4 and n < MAX_ITER do
				re, imv = re * re - imv * imv + re0, 2 * re * imv + im0
				n += 1
			end
			local t = n / MAX_ITER
			buffer.writeu8(buf, i,     math.floor(9 * (1 - t) * t * t * t * 255))
			buffer.writeu8(buf, i + 1, math.floor(15 * (1 - t) * (1 - t) * t * t * 255))
			buffer.writeu8(buf, i + 2, math.floor(8.5 * (1 - t) * (1 - t) * (1 - t) * t * 255))
			buffer.writeu8(buf, i + 3, 255)
			i += 4
		end
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end

render()
label.ImageContent = Content.fromObject(img)

label.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local ap = label.AbsolutePosition
		local as = label.AbsoluteSize
		local fx = (input.Position.X - ap.X) / as.X - 0.5
		local fy = (input.Position.Y - ap.Y) / as.Y - 0.5
		cx += fx * 2 * zoom
		cy += fy * 2 * zoom
		zoom *= 0.5
		render()
	end
end)
