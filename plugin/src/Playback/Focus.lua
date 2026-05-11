local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ResolvePath = require(script.Parent.ResolvePath)

local CAMERA_TWEEN = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PITCH_DEG = 25      -- look slightly down
local YAW_DEG = 35        -- off-axis for a 3/4 view
local PADDING = 2.5       -- how much slack past the bounding sphere

-- Collect a world-space AABB of any mix of BaseParts / Models. Returns
-- (center: Vector3, size: Vector3) or nil if nothing usable.
local function aabbOf(instances: { Instance }): (Vector3?, Vector3?)
	local lo: Vector3? = nil
	local hi: Vector3? = nil

	local function expand(cframe: CFrame, size: Vector3)
		-- Ignore rotation for the AABB; for camera framing it's good enough
		-- and cheap. Uses the CFrame position ± half size along world axes.
		local p = cframe.Position
		local h = size * 0.5
		local mn = p - h
		local mx = p + h
		if not lo then
			lo, hi = mn, mx
		else
			lo = Vector3.new(math.min(lo.X, mn.X), math.min(lo.Y, mn.Y), math.min(lo.Z, mn.Z))
			hi = Vector3.new(math.max(hi.X, mx.X), math.max(hi.Y, mx.Y), math.max(hi.Z, mx.Z))
		end
	end

	for _, inst in ipairs(instances) do
		if inst:IsA("BasePart") then
			expand(inst.CFrame, inst.Size)
		elseif inst:IsA("Model") then
			local cf, sz = inst:GetBoundingBox()
			if sz.Magnitude > 0 then
				expand(cf, sz)
			end
		end
	end

	if not lo or not hi then return nil, nil end
	return (lo + hi) * 0.5, hi - lo
end

-- Tween the edit-mode viewport camera to frame `instances`. No-op if none
-- of them are spatial (scripts, folders, etc.).
local function panCameraTo(instances: { Instance })
	local camera = Workspace.CurrentCamera
	if not camera then return end

	local center, size = aabbOf(instances)
	if not center or not size then return end

	local radius = math.max(size.Magnitude * 0.5, 2)
	local distance = math.max(radius * PADDING, 10)

	-- Direction from camera → target, spherical-offset.
	local yaw = math.rad(YAW_DEG)
	local pitch = math.rad(PITCH_DEG)
	local offset = Vector3.new(
		math.cos(pitch) * math.sin(yaw),
		math.sin(pitch),
		math.cos(pitch) * math.cos(yaw)
	) * distance

	local eye = center + offset
	local target = CFrame.lookAt(eye, center)

	local tween = TweenService:Create(camera, CAMERA_TWEEN, { CFrame = target })
	tween:Play()
end

local function apply(focus)
	if not focus then return end

	if focus.selection then
		local paths = if typeof(focus.selection) == "table" then focus.selection else { focus.selection }
		local instances = {}
		for _, path in ipairs(paths) do
			local inst = ResolvePath.resolve(path)
			if inst then
				table.insert(instances, inst)
			end
		end
		Selection:Set(instances)
		panCameraTo(instances)
	end

	if focus.script then
		local script_ = ResolvePath.resolve(focus.script.path)
		if script_ and script_:IsA("LuaSourceContainer") then
			ScriptEditorService:OpenScriptDocumentAsync(script_)
			-- Line highlight: post-open, try to position the cursor.
			local doc = ScriptEditorService:FindScriptDocument(script_)
			if doc and focus.script.startLine then
				local startLine = focus.script.startLine
				local endLine = focus.script.endLine or startLine
				pcall(function()
					doc:ForceSetSelectionAsync(startLine, 1, endLine, 1)
				end)
			end
		end
	end
end

return { apply = apply }
