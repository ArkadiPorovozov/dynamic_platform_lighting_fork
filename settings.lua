data.extend({
	{
		type = "int-setting",
		name = "dynamic_platform_max_solar_power_in_space",
		setting_type = "startup",
		minimum_value = 0,
		default_value = 400,
		maximum_value = 1000,
		order = "dynamic_platform_lighting_a",
	},
	{
		type = "bool-setting",
		name = "dynamic_platform_deep_darkness",
		setting_type = "startup",
		default_value = true,
		order = "dynamic_platform_lighting_b",
	},
	{
		type = "int-setting",
		name = "dynamic_platform_min_light",
		setting_type = "runtime-global",
		minimum_value = 0,
		default_value = 30,
		maximum_value = 100,
		order = "dynamic_platform_lighting_c",
	},
})
