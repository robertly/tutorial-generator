local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 128, 128
local STEPS_PER_SEC = 15

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })

local cells, next_cells = table.create(W * H, 0), table.create(W * H, 0)
for i = 1, W * H do
	cells[i] = math.random() < 0.3 and 1 or 0
end

local buf = buffer.create(W * H * 4)

local function draw()
	local i = 0
	for idx = 1, W * H do
		local v = cells[idx] == 1 and 255 or 0
		buffer.writeu8(buf, i, v)
		buffer.writeu8(buf, i + 1, v)
		buffer.writeu8(buf, i + 2, v)
		buffer.writeu8(buf, i + 3, 255)
		i += 4
	end
	img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
end

local function step()
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local n = 0
			for dy = -1, 1 do
				for dx = -1, 1 do
					if dx ~= 0 or dy ~= 0 then
						local nx = (x + dx) % W
						local ny = (y + dy) % H
						n += cells[ny * W + nx + 1]
					end
				end
			end
			local i = y * W + x + 1
			local alive = cells[i] == 1
			next_cells[i] = ((alive and (n == 2 or n == 3)) or (not alive and n == 3)) and 1 or 0
		end
	end
	cells, next_cells = next_cells, cells
end

draw()
label.ImageContent = Content.fromObject(img)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc >= 1 / STEPS_PER_SEC then
		acc = 0
		step()
		draw()
	end
end)
