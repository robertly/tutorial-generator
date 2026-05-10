-- Coerce a YAML/JSON-native value into the correct Roblox-typed value for a
-- given property. The plugin inspects the target property's declared type
-- via reflection, picks the right conversion, and returns the typed value.
--
-- Conventions (match SCHEMA.md):
--   Vector3 / Vector2 / Vector3int16 -> { x, y, z }
--   CFrame   -> { px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 }
--   Color3   -> { r, g, b }   (0..1)
--   UDim     -> { scale, offset }
--   UDim2    -> { sx, ox, sy, oy }
--   EnumItem -> "Enum.Material.Metal"
--   Instance -> "Workspace.Emitter.Base"  (resolved via ResolvePath)
--   Primitives pass through.

local ResolvePath = require(script.Parent.ResolvePath)

local function toVector3(v)
	return Vector3.new(v[1], v[2], v[3])
end

local function toCFrame(v)
	return CFrame.new(
		v[1], v[2], v[3],
		v[4], v[5], v[6],
		v[7], v[8], v[9],
		v[10], v[11], v[12]
	)
end

local function toColor3(v)
	return Color3.new(v[1], v[2], v[3])
end

local function toUDim2(v)
	return UDim2.new(v[1], v[2], v[3], v[4])
end

local function resolveEnum(s: string): EnumItem?
	-- "Enum.Material.Metal" -> Enum.Material.Metal
	local _, enumName, itemName = string.match(s, "^(Enum)%.([^.]+)%.(.+)$")
	if not enumName or not itemName then
		return nil
	end
	local ok, enum = pcall(function() return Enum[enumName] end)
	if not ok or not enum then
		return nil
	end
	local ok2, item = pcall(function() return enum[itemName] end)
	if not ok2 then
		return nil
	end
	return item
end

-- Given `instance`, `propertyName`, and a `yamlValue`, return the coerced
-- value. Falls back to returning yamlValue unchanged if we can't introspect.
local function coerce(instance: Instance, propertyName: string, yamlValue: any): any
	if yamlValue == nil then
		return nil
	end

	-- BrickColor special-case: allow plain string.
	if typeof(yamlValue) == "string" then
		if string.sub(yamlValue, 1, 5) == "Enum." then
			return resolveEnum(yamlValue) or yamlValue
		end
		-- Instance reference: if the property wants an Instance, resolve the path.
		-- Otherwise, string pass-through.
		local ok, currentValue = pcall(function() return (instance :: any)[propertyName] end)
		if ok and typeof(currentValue) == "Instance" then
			return ResolvePath.resolve(yamlValue)
		end
		if ok and typeof(currentValue) == "BrickColor" then
			return BrickColor.new(yamlValue)
		end
		return yamlValue
	end

	if typeof(yamlValue) == "number" or typeof(yamlValue) == "boolean" then
		return yamlValue
	end

	if typeof(yamlValue) == "table" then
		local count = #yamlValue
		if count == 2 then
			return Vector2.new(yamlValue[1], yamlValue[2])
		elseif count == 3 then
			-- Ambiguous: Vector3 or Color3. Pick by current value's type.
			local ok, currentValue = pcall(function() return (instance :: any)[propertyName] end)
			if ok and typeof(currentValue) == "Color3" then
				return toColor3(yamlValue)
			end
			return toVector3(yamlValue)
		elseif count == 4 then
			return toUDim2(yamlValue)
		elseif count == 12 then
			return toCFrame(yamlValue)
		end
	end

	return yamlValue
end

return {
	coerce = coerce,
}
