local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local W, H = 256, 128
local BARS = 32
local BAR_W = W / BARS

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })

local history = table.create(BARS, 0)

RunService.Heartbeat:Connect(function()
	img:DrawRectangle(Vector2.zero, img.Size, Color3.new(0, 0, 0), 0, Enum.ImageCombineType.Overwrite)
	local loud = SoundService:GetPropertyChangedSignal and SoundService:GetOutputLoudness() or 0
	table.remove(history, 1)
	table.insert(history, loud)
	for i = 1, BARS do
		local v = math.clamp(history[i] / 40, 0, 1)
		local barH = math.floor(v * H)
		local hue = (i - 1) / BARS
		img:DrawRectangle(
			Vector2.new((i - 1) * BAR_W, H - barH),
			Vector2.new(BAR_W - 1, barH),
			Color3.fromHSV(hue, 0.8, 1),
			0,
			Enum.ImageCombineType.Overwrite
		)
	end
end)

label.ImageContent = Content.fromObject(img)
