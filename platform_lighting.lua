
local M = {}

local function build_platform_lut()
	if settings.startup["dynamic_platform_deep_darkness"].value then
		return {
			{ 0.0, "__core__/graphics/color_luts/identity-lut.png" },
			{ 0.2, "__core__/graphics/color_luts/identity-lut.png" },
			{ 0.8, "__dynamic_platform_lighting_fork__/graphics/max-dark.png" },
			{ 0.99, "__dynamic_platform_lighting_fork__/graphics/max-dark.png" },
			{ 0.9905, "__core__/graphics/color_luts/lut-night.png" },
			{ 1.0, "__core__/graphics/color_luts/identity-lut.png" },
		}
	else
		return {
			{ 0.0, "__core__/graphics/color_luts/identity-lut.png" },
			{ 0.2, "__core__/graphics/color_luts/identity-lut.png" },
			{ 0.8, "__dynamic_platform_lighting_fork__/graphics/max-dark.png" },
			{ 0.99, "__core__/graphics/color_luts/lut-night.png" },
			{ 1.0, "__core__/graphics/color_luts/identity-lut.png" },
		}
	end
end

local function copy_lut(lut)
	local out = {}
	for i, entry in ipairs(lut) do
		out[i] = { entry[1], entry[2] }
	end
	return out
end

local function build_global_lut(original, deep_darkness)
	local out = {}
	if type(original) == "table" then
		local entries = {}
		for _, entry in ipairs(original) do
			if type(entry) == "table" and type(entry[1]) == "number" and entry[1] < 0.985 then
				entries[#entries + 1] = { entry[1], entry[2] }
			end
		end
		table.sort(entries, function(a, b) return a[1] < b[1] end)
		out = entries
	end
	if #out == 0 then
		out = {
			{ 0.00, "identity" },
			{ 0.25, "identity" },
			{ 0.45, "__core__/graphics/color_luts/lut-night.png" },
			{ 0.55, "__core__/graphics/color_luts/lut-night.png" },
			{ 0.75, "identity" },
		}
	end
	out[#out + 1] = { 0.985, "identity" }
	out[#out + 1] = { 0.99, "__dynamic_platform_lighting_fork__/graphics/max-dark.png" }
	if deep_darkness then
		out[#out + 1] = { 0.9905, "__core__/graphics/color_luts/lut-night.png" }
	end
	out[#out + 1] = { 1.0, "identity" }
	return out
end

function M.apply()
	local deep_darkness = settings.startup["dynamic_platform_deep_darkness"].value
	local platform_lut = build_platform_lut()

	for _, prototype_type in ipairs({ "planet", "space-location" }) do
		if data.raw[prototype_type] then
			for _, location in pairs(data.raw[prototype_type]) do
				location.platform_surface_render_parameters =
					location.platform_surface_render_parameters or {}
				location.platform_surface_render_parameters.day_night_cycle_color_lookup =
					copy_lut(platform_lut)
			end
		end
	end

	local utility = data.raw["utility-constants"] and data.raw["utility-constants"].default
	if utility then

		local original_global = utility.daytime_color_lookup

		utility.default_platform_surface_render_parameters =
			utility.default_platform_surface_render_parameters or {}
		utility.default_platform_surface_render_parameters.day_night_cycle_color_lookup =
			copy_lut(platform_lut)

		if data.raw["planet"] and type(original_global) == "table" then

			local pristine = {}
			for _, entry in ipairs(original_global) do
				if type(entry) == "table" and type(entry[1]) == "number" and entry[1] < 0.985 then
					pristine[#pristine + 1] = { entry[1], entry[2] }
				end
			end
			if #pristine > 0 then
				for _, planet in pairs(data.raw["planet"]) do
					local render = planet.surface_render_parameters
					if render and not render.day_night_cycle_color_lookup then
						render.day_night_cycle_color_lookup = copy_lut(pristine)
					end
				end
			end
		end

		utility.daytime_color_lookup = build_global_lut(original_global, deep_darkness)
	end

	local hub = data.raw["space-platform-hub"] and data.raw["space-platform-hub"]["space-platform-hub"]
	if hub then
		hub.surface_render_parameters = hub.surface_render_parameters or {}
		hub.surface_render_parameters.day_night_cycle_color_lookup = copy_lut(platform_lut)
	end
end

return M
