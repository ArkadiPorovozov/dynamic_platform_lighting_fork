
local M = {}

local IDENTITY = "__core__/graphics/color_luts/identity-lut.png"
local LUT_NIGHT = "__core__/graphics/color_luts/lut-night.png"
local MAX_DARK = "__dynamic_platform_lighting_fork__/graphics/max-dark.png"

local function lookup_day_night(lut)
	local day, day_time
	local night, night_dist = nil, math.huge
	if type(lut) == "table" then
		for _, entry in ipairs(lut) do
			if type(entry) == "table" and type(entry[1]) == "number" then
				local time, image = entry[1], entry[2]
				if day_time == nil or time < day_time then
					day, day_time = image, time
				end
				local dist = math.abs(time - 0.5)
				if dist < night_dist then
					night, night_dist = image, dist
				end
			end
		end
	end
	return day, night
end

local function copy_lut(lut)
	local out = {}
	for i, entry in ipairs(lut) do
		out[i] = { entry[1], entry[2] }
	end
	return out
end

local function build_platform_lut(day, night, deep_darkness)
	day = day or IDENTITY
	local low = deep_darkness and MAX_DARK or (night or LUT_NIGHT)
	return {
		{ 0.0, day },
		{ 0.9, day },
		{ 0.99, low },
		{ 1.0, day },
	}
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

	local utility = data.raw["utility-constants"] and data.raw["utility-constants"].default
	local original_global = utility and utility.daytime_color_lookup
	local global_day, global_night = lookup_day_night(original_global)

	for _, prototype_type in ipairs({ "planet", "space-location" }) do
		if data.raw[prototype_type] then
			for _, location in pairs(data.raw[prototype_type]) do
				local source_lut = location.surface_render_parameters
					and location.surface_render_parameters.day_night_cycle_color_lookup
				local day, night = lookup_day_night(source_lut)
				location.platform_surface_render_parameters =
					location.platform_surface_render_parameters or {}
				location.platform_surface_render_parameters.day_night_cycle_color_lookup =
					build_platform_lut(day or global_day, night or global_night, deep_darkness)
			end
		end
	end

	if utility then
		utility.default_platform_surface_render_parameters =
			utility.default_platform_surface_render_parameters or {}
		utility.default_platform_surface_render_parameters.day_night_cycle_color_lookup =
			build_platform_lut(global_day, global_night, deep_darkness)

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
		hub.surface_render_parameters.day_night_cycle_color_lookup =
			build_platform_lut(global_day, global_night, deep_darkness)
	end
end

return M
