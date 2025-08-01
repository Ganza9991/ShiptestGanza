/**
 * # Pandora
 * Магия \ Phoron
 * Босс уникален своей ареной, которая состоит из бесконечной битвы до победы.

	Визуал арены выглядит как внутренность самой коробки, словно помещая бойцов внутрь.
		Пол Хиерофанта (Белая плитка)
		По арене рандомно спавнятся партиклы ревенанта (effect/temp_visual/revenant)
		Стенки арены фиолетовая энергия (реколор стенок арены)

 * Игроки могут столбить места за определённых мобов или за любых и тогда их вытащат из гостов для битвы
 * Абилки:
	• Каждые несколько секунд спавнит мобов, убийство которых дамажит босса. adjustBruteLoss(forced = TRUE). Моб не спавнится если его тип уже есть на арене.
		Если все вся пачка умерла достаточно быстро, то сразу спавнится усиленная пачка пачка мобов, убийство которой дамажит босса больше
	• Призывает звёзды упасть с неба. Рефлавнутный falling_stars
	Создаваемые угрозы:
		• Фабрикатор легион-черепов
		• Юла, создающая вокруг себя по каждому диру по одному бласту
		• Брут, жирный и мешающий
		• Асасин, дамажащий, уворотливый, но тощий
		• Варлок, защищающий союзников и бегающий
	• (Phoron enhance only) Magic Rifts: Каждые 30 секунд создаёт импульс дамага стамины. После этого на арене появляется разрыв бездны, из которого do_after(50) можно вытащить либо хилку, либо патроны для одного из оружия, либо уникальный предмет для арены.
		Разрывы пространства остаются после битвы, но из них нельзя будет вытащить уникальный лут. Их можно будет изучить продвинутым сурвеем.
		* Уникальные предметы:
			• Кинжал судьб - ваншотает моба арены. Исчезает после применения

 */
// ================= Elite set =================
// MARK: SET
/datum/tumor_elite_set/pandora
	elite = /mob/living/simple_animal/hostile/asteroid/elite/pandora

// ================= Elite =================
// MARK: ELITE

/mob/living/simple_animal/hostile/asteroid/elite/pandora
	name = "pandora"
	desc = "A large magic box with similar power and design to the Hierophant. Once it opens, it's not easy to close it."
	faction = list("hostile", "elitefauna", "pandora")
	damage_coeff = list(BRUTE = 0, BURN = 0)
	icon_state = "pandora"
	icon_living = "pandora"
	icon_aggro = "pandora"
	icon_dead = "pandora_dead"
	icon_gib = "syndicate_gib"
	health_doll_icon = "pandora"
	melee_damage_lower = 0
	melee_damage_upper = 0
	friendly_verb_continuous = "wails at"
	friendly_verb_simple = "wails at"
	attack_verb_continuous = "smashes into the side of"
	attack_verb_simple = "smash into the side of"
	attack_sound = 'sound/weapons/sonic_jackhammer.ogg'
	throw_message = "merely dinks off of the"
	speed = 0
	move_to_delay = 10
	mouse_opacity = MOUSE_OPACITY_ICON
	deathsound = 'sound/magic/repulse.ogg'
	deathmessage = "'s lights flicker, before its top part falls down."
	loot_drop = /obj/item/clothing/accessory/pandora_hope

	var/cooldown_time = 20
	var/hostiles_to_spawn = list()
	var/list/hostiles_list = list(/mob/living/simple_animal/cow,)
	var/blast_charges = 0
	var/orig_arena_range

/mob/living/simple_animal/hostile/asteroid/elite/pandora/Initialize(mapload)
	. = ..()
	orig_arena_range = tumor.arena_range

/mob/living/simple_animal/hostile/asteroid/elite/pandora/update_stat()
	. = ..()
	tumor.arena_range = max(orig_arena_range * round(health / maxHealth, 0.1), orig_arena_range*0.5) // Decrease arena range until it's 50% of original range

// completely stationary
/mob/living/simple_animal/hostile/asteroid/elite/pandora/Move(atom/newloc, dir, step_x , step_y)
	return FALSE

/mob/living/simple_animal/hostile/asteroid/elite/pandora/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/asteroid/elite/pandora/OpenFire()
	return FALSE

// ================= Abilities =================
// MARK: ABILITIES

/// Chooses a random arena wall and walks blasts in dir of Pandora
/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/random_row_blast()
	var/turf/picked_turf = pick(tumor.arena_walls)
	var/list/turf/line = list()
	var/turf/next_turf = picked_turf
	for(var/N in 1 to tumor.arena_range)
		var/turf/T = get_step_towards(next_turf, src)
		if(T == next_turf)
			break	// if we didnt moved
		line += T
		next_turf = T

	for(var/turf/T in line)
		new /obj/effect/temp_visual/hierophant/blast/pandora(T, src)
		sleep(5-hp_state)
	aoe_squares(src)

/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/singular_shot(target)
	ranged_cooldown = world.time + (cooldown_time * 0.5)
	var/dir_to_target = get_dir(get_turf(src), get_turf(target))
	var/turf/T = get_step(get_turf(src), dir_to_target)
	singular_shot_line(8, dir_to_target, T)

/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/singular_shot_line(procsleft, angleused, turf/T)
	if(procsleft <= 0)
		return
	new /obj/effect/temp_visual/hierophant/blast/pandora(T, src)
	T = get_step(T, angleused)
	procsleft--
	addtimer(CALLBACK(src, PROC_REF(singular_shot_line), procsleft, angleused, T), 2)

/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/magic_box(target)
	ranged_cooldown = world.time + cooldown_time
	var/turf/T = get_turf(target)
	for(var/t in spiral_range_turfs(3, T))
		if(get_dist(t, T) > 1)
			new /obj/effect/temp_visual/hierophant/blast/pandora(t, src)

/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/falling_stars()
	if(stat != DEAD && blast_charges)
		blast_charges--
		var/list/turf/blast_turfs = RANGE_TURFS(max(tumor.arena_range-2, 2), src)
		var/list/turf/blast_picked_turfs = list()
		for(var/i in 1 to 50)
			var/turf/T = pick_n_take(blast_turfs)
			blast_picked_turfs += T
			new /obj/effect/temp_visual/pandora/falling_star(T, src)
		addtimer(CALLBACK(src, PROC_REF(falling_stars)), 3 SECONDS)

/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/conjure_hostile(dir)
	// var/turf/stepturf = get_turf(src)
	// var/turf/startingturf = get_turf(src)
	// var/pickconstruct = pick(hostiles_list)
	// for(var/T in 1 to 5)
	// 	stepturf = get_open_turf_in_dir(stepturf, dir)
	// 	sleep(2)
	// 	if(get_dist(startingturf, stepturf) > 4)
	// 		new /obj/effect/temp_visual/hierophant/blast/pandora(stepturf)
	// 		sleep(7)
	// 		new pickconstruct(stepturf)
	// 	else
	// 		if(get_open_turf_in_dir_null(stepturf, dir) == null)
	// 			new /obj/effect/temp_visual/hierophant/blast/pandora(stepturf)
	// 			sleep(7)
	// 			new pickconstruct(stepturf)
	// 		else
	// 			new /obj/effect/temp_visual/revenant(stepturf)

	var/foes = hostiles_list.len
	if(foes < 3)
		var/list/T
		for(var/C in 1 to foes-3)
			var/tt = pick(tumor.arena_walls)
			if(!(tt in T))
				T += tt
			var/thing_to_spawn = pick(hostiles_to_spawn)
			var/mob/living/L = new thing_to_spawn(pick_n_take(T))
			L.Move(step_towards(src, tumor))

// AoE squares
/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/aoe_squares(target)
	ranged_cooldown = world.time + cooldown_time
	var/turf/T = get_turf(src)
	new /obj/effect/temp_visual/hierophant/blast/pandora(T, src)
	addtimer(CALLBACK(src, PROC_REF(aoe_squares_2), T, 0, 2), 2)

/mob/living/simple_animal/hostile/asteroid/elite/pandora/proc/aoe_squares_2(turf/T, ring, max_size)
	if(ring > max_size)
		return
	for(var/t in spiral_range_turfs(ring, T))
		if(get_dist(t, T) == ring)
			new /obj/effect/temp_visual/hierophant/blast/pandora(t, src)
	addtimer(CALLBACK(src, PROC_REF(aoe_squares_2), T, (ring + 1), max_size), 2)

// ================= Visuals =================
// MARK: VISUALS

// Blast after
/obj/effect/temp_visual/hierophant/squares/preblast
	randomdir = TRUE

/obj/effect/temp_visual/hierophant/squares/preblast/Initialize(mapload, new_caster)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(spawn_blast)), 3)

/obj/effect/temp_visual/hierophant/squares/preblast/proc/spawn_blast()
	new /obj/effect/temp_visual/hierophant/blast/pandora(loc, caster)

/obj/effect/temp_visual/hierophant/blast/pandora
	damage = 20
	monster_damage_boost = FALSE

/obj/effect/temp_visual/pandora/falling_star
	name = "falling star"
	icon = 'mod_celadon/legionunited/icons/fallingstar.dmi'
	layer = BELOW_MOB_LAYER
	icon_state = "warn"
	duration = 61
	var/list/factions = list()

/obj/effect/temp_visual/pandora/falling_star/Initialize(mob/caster)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(spawn_star)), 40)
	factions = caster.faction

/obj/effect/temp_visual/pandora/falling_star/proc/spawn_star()
	flick("star", src)
	layer = ABOVE_MOB_LAYER
	sleep(21)
	var/turf/T = get_turf(src)
	for(var/mob/living/L in T.contents) //find and damage mobs...
		if(faction_check(L.faction,factions))
			continue
		var/list/hit_things = list()
		hit_things += L
		if(L.client)
			flash_color(L.client, "#32978a", 1)
		playsound(L,'sound/weapons/sear.ogg', 50, TRUE, -4)
		to_chat(L, span_userdanger("You're struck by a [name]!"))
		var/limb_to_hit = L.get_bodypart(pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
		var/armor = L.run_armor_check(limb_to_hit, "melee", 50, FALSE, "Your armor absorbs [src]!", "Your armor blocks part of [src]!", "Your armor was penetrated by [src]!")
		L.apply_damage(25, BURN, limb_to_hit, armor)


// ================= Actions =================
// MARK: ACTIONS

/datum/action/innate/elite_attack/singular_shot
	name = "Singular Shot"
	button_icon_state = "singular_shot"
	chosen_message = span_boldwarning("You are now creating a single linear magic square.")
	chosen_attack_num = 1

/datum/action/innate/elite_attack/magic_box
	name = "Magic Box"
	button_icon_state = "magic_box"
	chosen_message = span_boldwarning("You are now attacking with a box of magic squares.")
	chosen_attack_num = 2

/datum/action/innate/elite_attack/pandora_teleport
	name = "Line Teleport"
	button_icon_state = "pandora_teleport"
	chosen_message = span_boldwarning("You will now teleport to your target.")
	chosen_attack_num = 3

/datum/action/innate/elite_attack/aoe_squares
	name = "AOE Blast"
	button_icon_state = "aoe_squares"
	chosen_message = span_boldwarning("Your attacks will spawn an AOE blast at your target location.")
	chosen_attack_num = 4

// ================= Special Loot =================
// MARK: LOOT

//Pandora's loot: Hope
/obj/item/clothing/accessory/pandora_hope
	name = "Hope"
	desc = "Found at the bottom of Pandora. After all the evil was released, this was the only thing left inside."
	icon = 'icons/obj/lavaland/elite_trophies.dmi'
	icon_state = "hope"
	resistance_flags = FIRE_PROOF
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5, "energy" = 5, "bomb" = 20, "bio" = 20, "rad" = 5, "fire" = 0, "acid" = 25)

/obj/item/clothing/accessory/pandora_hope/on_uniform_equip(obj/item/clothing/under/U, user)
	var/mob/living/L = user
	if(L && L.mind)
		SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "hope_lavaland", /datum/mood_event/hope_lavaland)

/obj/item/clothing/accessory/pandora_hope/on_uniform_dropped(obj/item/clothing/under/U, user)
	var/mob/living/L = user
	if(L && L.mind)
		SEND_SIGNAL(L, COMSIG_CLEAR_MOOD_EVENT, "hope_lavaland")
