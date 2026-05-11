local AssetService = game:GetService("AssetService")
local UserInputService = game:GetService("UserInputService")

local W, H = 512, 512
local BRUSH_RADIUS = 8
local COLOR = Color3.fromRGB(255, 60, 60)

local label = script.Parent
local img = AssetService:CreateEditableImage({ Size = Vector2.new(W, H) })
img:DrawRectangle(Vector2.zero, img.Size, Color3.new(1, 1, 1), 0, Enum.ImageCombineType.Overwrite)
label.ImageContent = Content.fromObject(img)

local painting = false

local function toPixel(screenPos)
	local ap, as = label.AbsolutePosition, label.AbsoluteSize
	return Vector2.new(
		math.floor((screenPos.X - ap.X) / as.X * W),
		math.floor((screenPos.Y - ap.Y) / as.Y * H)
	)
end

label.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		painting = true
		img:DrawCircle(toPixel(input.Position), BRUSH_RADIUS, COLOR, 0, Enum.ImageCombineType.AlphaBlend)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		painting = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if painting and input.UserInputType == Enum.UserInputType.MouseMovement then
		img:DrawCircle(toPixel(input.Position), BRUSH_RADIUS, COLOR, 0, Enum.ImageCombineType.AlphaBlend)
	end
end)
