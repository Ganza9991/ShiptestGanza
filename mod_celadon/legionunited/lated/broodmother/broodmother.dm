#define TENTACLE_PATCH 1
#define SPAWN_CHILDREN 2
#define RAGE 3
#define CALL_CHILDREN 4

/**
 * # Goliath Broodmother
 *
 * A stronger, faster variation of the goliath.  Has the ability to spawn baby goliaths, which it can later detonate at will.
 * When it's health is below half, tendrils will spawn randomly around it.  When it is below a quarter of health, this effect is doubled.
 * It's attacks are as follows:
 * - Spawns a 3x3/plus shape of tentacles on the target location
 * - Spawns 2 baby goliaths on its tile, up to a max of 8. Children blow up when they die.
 * - The broodmother lets out a noise, and is able to move faster for 6.5 seconds.
 * - Summons your children around you.
 * The broodmother is a fight revolving around stage control, as the activator has to manage the baby goliaths and the broodmother herself, along with all the tendrils.

 * Абилки:
	• Каждую четверть потерянного ХП призывает детей
	• После 50% испускает визг, после чего все спавны детей ускорены, а сами дети усилены.
	• Связывает ближайших врагов тентаклями, не давая отойти дальше чем на 2 тайла, также нанося урон стамине (2%/sec).


 */
// ================= Elite set =================
// MARK: SET
/datum/tumor_elite_set/broodmother
	elite = /mob/living/simple_animal/hostile/asteroid/elite/broodmother

// ================= Elite =================
// MARK: ELITE

/mob/living/simple_animal/hostile/asteroid/elite/broodmother
	name = "goliath broodmother"
	desc = "Goliaths are sequential hermaphrodites, and will rarely enter an egg-bearing or \"female\" phase. As this specimen clearly demonstrates, Goliaths in this phase become significantly larger and more aggressive. These \"Broodmothers\" are even more dangerous than the common variety, and are best avoided entirely."
	gender = FEMALE
	icon = 'icons/mob/lavaland/lavaland_elites_64.dmi'
	faction = list("hostile", "elitefauna", "broodmother")
	icon_state = "broodmother"
	icon_living = "broodmother"
	icon_aggro = "broodmother"
	icon_dead = "egg_sac"
	icon_gib = "syndicate_gib"
	armor = list("melee" = 10, "bullet" = 20, "laser" = 20, "energy" = 30, "bomb" = 40, "bio" = 20, "rad" = 20, "fire" = 40, "acid" = 20)
	pixel_x = -16
	base_pixel_x = -16
	health_doll_icon = "broodmother"
	melee_damage_lower = 10
	melee_damage_upper = 10
	armour_penetration = 0
	attack_verb_continuous = "beats down on"
	attack_verb_simple = "beat down on"
	attack_sound = 'sound/weapons/punch1.ogg'
	throw_message = "does nothing to the thick hide of the"
	speed = 2
	move_to_delay = 5
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	deathmessage = "explodes into gore!"
	//loot_drop = /obj/item/mob_trophy/broodmother_tongue

	attack_action_types = list(/datum/action/innate/elite_attack/tentacle_patch,
								/datum/action/innate/elite_attack/spawn_children,
								/datum/action/innate/elite_attack/rage,
								/datum/action/innate/elite_attack/call_children)

	var/childragecall = 0

	var/rand_tent = 0
	var/list/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/children_list = list()

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/Destroy()
	children_list.Cut()
	return ..()

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/update_stat()
	. = ..()
	if(hp_state<1 && health < maxHealth * 0.75 && health >= maxHealth * 0.5) // between 75 and 50
		spawn_children()
		hp_state++
		return
	if(hp_state<2 && health < maxHealth * 0.50 && health >= maxHealth * 0.25) // between 50 and 25
		spawn_children()
		hp_state++
		return
	if(hp_state<3 && health < maxHealth * 0.25 && health >= 1) // between 25 and 0
		spawn_children()
		hp_state++
		return

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/death(gibbed)
	. = ..()
	spawn_children()

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/OpenFire()
	var/aiattack = rand(1,4)
	switch(aiattack)
		if(TENTACLE_PATCH)
			tentacle_patch(target)
		if(SPAWN_CHILDREN)
			spawn_children()
		if(RAGE)
			rage()
		if(CALL_CHILDREN)
			call_children()

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/Life()
	. = ..()
	if(!.) //Checks if they are dead as a rock.
		return
	if(health < maxHealth * 0.5 && rand_tent < world.time)
		rand_tent = world.time + 30
		var/tentacle_amount = 5
		if(health < maxHealth * 0.25)
			tentacle_amount = 10
		var/tentacle_loc = spiral_range_turfs(5, get_turf(src))
		for(var/i in 1 to tentacle_amount)
			var/turf/t = pick_n_take(tentacle_loc)
			new /obj/effect/temp_visual/goliath_tentacle/broodmother(t, src)

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/AttackingTarget()
	if(target && isliving(target))
		if(childragecall != 0)
			call_children()
			childragecall = 0
	return ..()


// ================= Abilities =================
// MARK: ABILITIES

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/proc/tentacle_patch(target)
	ranged_cooldown = world.time + 15
	var/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	visible_message(span_warning("[src] digs its tentacles under [target]!"))
	new /obj/effect/temp_visual/goliath_tentacle/broodmother/patch(tturf, src)

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/proc/spawn_children(target)
	ranged_cooldown = world.time + 40
	visible_message(span_boldwarning("The ground churns behind [src]!"))
	for(var/i in 1 to 2)
		if(children_list.len >= 8)
			return
		var/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/newchild = new /mob/living/simple_animal/hostile/asteroid/elite/broodmother_child(loc, src)
		newchild.GiveTarget(target)
		newchild.faction = faction.Copy()
		visible_message(span_boldwarning("[newchild] appears below [src]!"))
		children_list += newchild

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/proc/rage()
	ranged_cooldown = world.time + 70
	playsound(src,'sound/spookoween/insane_low_laugh.ogg', 200, 1)
	visible_message(span_warning("[src] starts picking up speed!"))
	childragecall = 1
	color = "#FF0000"
	set_varspeed(0)
	move_to_delay = 3
	addtimer(CALLBACK(src, PROC_REF(reset_rage)), 65)

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/proc/reset_rage()
	color = "#FFFFFF"
	set_varspeed(2)
	move_to_delay = 5

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/proc/call_children()
	ranged_cooldown = world.time + 60
	visible_message(span_warning("The ground shakes near [src]!"))
	var/list/directions = GLOB.cardinals.Copy() + GLOB.diagonals.Copy()
	for(var/mob/child in children_list)
		var/spawndir = pick_n_take(directions)
		var/turf/T = get_step(src, spawndir)
		if(T)
			child.forceMove(T)
			playsound(src, 'sound/effects/bamf.ogg', 100, 1)

// Связывает ближайших врагов тентаклями, не давая отойти дальше чем на 2 тайла, также нанося урон стамине (2%/sec).
// Посмотреть можно ли сделать beam атакуемым чтобы досрочно отвязаться
/mob/living/simple_animal/hostile/asteroid/elite/broodmother/proc/tentacle_grip()
	var/list/mob/living/carbon/victims = list()
	for(var/mob/living/carbon/C in range(3))
		victims += C
	AddComponent(/datum/component/broodmother_tentacle_grip, victims)

// ================= Datums =================
// MARK: DATUMS

// ========= Tentacle grip =========
/datum/component/broodmother_tentacle_grip
	var/list/mob/living/carbon/victims = list()
	var/mob/living/simple_animal/hostile/asteroid/elite/broodmother/elite
	var/list/beams = list()

/datum/component/broodmother_tentacle_grip/Initialize(list/L)
	elite = parent
	preparation(L)

/datum/component/broodmother_tentacle_grip/proc/preparation(list/L)
	if(!L.len)
		return FALSE
	victims = L
	for(var/mob/living/A in victims)
		beams += elite.Beam(A, icon_state="tentacle", maxdistance = 20, beam_color = "#5e3737", override_origin_pixel_x = 0, override_origin_pixel_y = 18)
		A.apply_status_effect(/datum/status_effect/broodmother_tentacle_grip)
	addtimer(CALLBACK(src, PROC_REF(let_go)), 30 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(tension)), 1 SECONDS, TIMER_LOOP)

/datum/component/broodmother_tentacle_grip/proc/tension()
	for(var/mob/living/L in victims)
		sleep(rand(2,6))
		L.adjustStaminaLoss(2)
		var/L_dist = get_dist(elite, L)
		switch(L_dist)
			if(0 to 3)
				continue
			if(4 to 5)
				L.Move(get_step_to(L, elite))
			if(6 to INFINITY)
				L.adjustStaminaLoss(4)
				L.throw_at(elite, L_dist-2, L_dist-1, elite, 0)
				L.Knockdown(10)
				to_chat(L, span_warning("Tight tentacles pull you closer, knocking you down!"))

/datum/component/broodmother_tentacle_grip/proc/let_go()
	for(var/mob/living/L in victims)
		L.remove_status_effect(/datum/status_effect/broodmother_tentacle_grip)
	QDEL_LIST(beams)
	qdel(src)

// ========= Status effect =========
/datum/status_effect/broodmother_tentacle_grip
	id = "broodmother_tentacle_grip"
	tick_interval = 0
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/broodmother_tentacle_grip

/datum/status_effect/broodmother_tentacle_grip/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/broodmother_tentacle_grip)
	return TRUE

/datum/status_effect/broodmother_tentacle_grip/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/broodmother_tentacle_grip)

/datum/movespeed_modifier/broodmother_tentacle_grip
	multiplicative_slowdown = 0.65

/atom/movable/screen/alert/status_effect/broodmother_tentacle_grip
	name = "Tentacle grip"
	desc = "Massive goliath tentacles restricts effectivenes of your dexterity."
	icon_state = "weakened"

// ================= Visuals =================
// MARK: VISUALS

//Tentacles have less stun time compared to regular variant, to balance being able to use them much more often.  Also, 10 more damage.
/obj/effect/temp_visual/goliath_tentacle/broodmother/trip()
	var/latched = FALSE
	for(var/mob/living/L in loc)
		if((!QDELETED(spawner) && spawner.faction_check_mob(L)) || L.stat == DEAD)
			continue
		visible_message(span_danger("[src] grabs hold of [L]!"))
		L.Stun(10)
		L.adjustBruteLoss(rand(30,35))
		latched = TRUE
	if(!latched)
		retract()
	else
		deltimer(timerid)
		timerid = addtimer(CALLBACK(src, PROC_REF(retract)), 10, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/broodmother/patch/Initialize(mapload, new_spawner)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(createpatch))

/obj/effect/temp_visual/goliath_tentacle/broodmother/patch/proc/createpatch()
	var/tentacle_locs = spiral_range_turfs(1, get_turf(src))
	for(var/T in tentacle_locs)
		new /obj/effect/temp_visual/goliath_tentacle/broodmother(T, spawner)
	var/list/directions = GLOB.cardinals.Copy()
	for(var/i in directions)
		var/turf/T = get_step(get_turf(src), i)
		T = get_step(T, i)
		new /obj/effect/temp_visual/goliath_tentacle/broodmother(T, spawner)

// ================= Additional Mobs =================
// MARK: ADDS

//The goliath's children.  Pretty weak, simple mobs which are able to put a single tentacle under their target when at range.
/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child
	name = "baby goliath"
	desc = "Goliaths are ovoviviparous; While egg-bearing, they incubate their eggs inside the mother. Newly-hatched Goliaths like this one are precocious and can defend themselves and their mother from the moment they hatch."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "goliath_baby"
	icon_living = "goliath_baby"
	icon_aggro = "goliath_baby"
	icon_dead = "goliath_baby_dead"
	icon_gib = "syndicate_gib"
	maxHealth = 30
	health = 30
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "bashes against"
	attack_verb_simple = "bash against"
	attack_sound = 'sound/weapons/punch1.ogg'
	throw_message = "does nothing to the hide of the"
	speed = 2
	move_to_delay = 5
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/goliath_hide = 1)
	deathmessage = "falls to the ground."
	status_flags = CANPUSH
	var/datum/weakref/mother_ref

/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/Initialize(mapload, mob/living/simple_animal/hostile/asteroid/elite/broodmother/mother)
	. = ..()
	mother_ref = WEAKREF(mother)

/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/Destroy()
	var/mob/living/simple_animal/hostile/asteroid/elite/broodmother/mother = mother_ref?.resolve()
	if(mother)
		mother.children_list -= src
	return ..()

/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/OpenFire(target)
	ranged_cooldown = world.time + 40
	var/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	if(get_dist(src, target) <= 7)//Screen range check, so it can't attack people off-screen
		visible_message(span_warning("[src] digs one of its tentacles under [target]!"))
		new /obj/effect/temp_visual/goliath_tentacle/broodmother(tturf, src)

/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/death()
	. = ..()
	visible_message(span_warning("[src] explodes!"))
	explosion(get_turf(loc),0,0,0,flame_range = 3, adminlog = FALSE)
	gib()

// rockplanet mobs
/mob/living/simple_animal/hostile/asteroid/elite/broodmother_child/rockplanet
	name = "baby gruboid"
	desc = "A newly-born gruboid. As a defense mechanism, they violently explode if killed."
	icon_state = "gruboid_baby"
	icon_living = "gruboid_baby"
	icon_aggro = "gruboid_baby"
	icon_dead = "gruboid_baby_dead"
	icon_gib = "syndicate_gib"

// ================= Actions =================
// MARK: ACTIONS

/datum/action/innate/elite_attack/tentacle_patch
	name = "Tentacle Patch"
	button_icon_state = "tentacle_patch"
	chosen_message = span_boldwarning("You are now attacking with a patch of tentacles.")
	chosen_attack_num = TENTACLE_PATCH

/datum/action/innate/elite_attack/spawn_children
	name = "Spawn Children"
	button_icon_state = "spawn_children"
	chosen_message = span_boldwarning("You will spawn two children at your location to assist you in combat.  You can have up to 8.")
	chosen_attack_num = SPAWN_CHILDREN

/datum/action/innate/elite_attack/rage
	name = "Rage"
	button_icon_state = "rage"
	chosen_message = span_boldwarning("You will temporarily increase your movement speed.")
	chosen_attack_num = RAGE

/datum/action/innate/elite_attack/call_children
	name = "Call Children"
	button_icon_state = "call_children"
	chosen_message = span_boldwarning("You will summon your children to your location.")
	chosen_attack_num = CALL_CHILDREN
