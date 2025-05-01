/datum/tumor_elite_set
	/// Elite mob itself
	var/mob/living/simple_animal/hostile/asteroid/elite/elite

	/// Turf that arena wall will be reskined to
	var/turf/walls
	/// Turf that floor inside the arena will be reskined to.
	var/turf/floor
	/// List of ignored turfs that will not be reskined
	var/static/list/turf/ignore_turf_list = typecacheof(list(
		/turf/open/lava,
		/turf/open/space,
		/turf/open/water,
		/turf/open/chasm)
		)
