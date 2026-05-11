local AssetService = game:GetService("AssetService")

local W, H = 256, 256
local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
local buf = buffer.create(W * H * 4)

local function fbm(x, y)
	local v, amp, freq = 0, 1, 0.02
	for _ = 1, 5 do
		v += math.noise(x * freq, y * freq) * amp
		amp *= 0.5
		freq *= 2
	end
	return v
end

local function colorFor(h)
	if h < -0.1 then return 30, 60, 150       -- deep water
	elseif h < 0.05 then return 70, 130, 200   -- shore
	elseif h < 0.15 then return 220, 200, 140  -- sand
	elseif h < 0.35 then return 80, 150, 70    -- grass
	elseif h < 0.55 then return 50, 100, 50    -- forest
	elseif h < 0.75 then return 120, 110, 100  -- rock
	else                 return 240, 240, 250 end -- snow
end

local k = 0
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local h = fbm(x, y)
		local r, g, b = colorFor(h)
		-- cheap shading: compare to neighbor
		local hn = fbm(x - 1, y - 1)
		local shade = 0.85 + math.clamp((h - hn) * 4, -0.15, 0.15)
		buffer.writeu8(buf, k,     math.clamp(math.floor(r * shade), 0, 255))
		buffer.writeu8(buf, k + 1, math.clamp(math.floor(g * shade), 0, 255))
		buffer.writeu8(buf, k + 2, math.clamp(math.floor(b * shade), 0, 255))
		buffer.writeu8(buf, k + 3, 255)
		k += 4
	end
end

img:WritePixelsBuffer(Vector2.zero, img.Size, buf)
label.ImageContent = Content.fromObject(img)
