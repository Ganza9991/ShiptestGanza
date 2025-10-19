/mob/living/simple_animal/hostile/pandora_horrors
	name = "Unimaginable thing"
	desc = "Try to imagine it."
	faction = list("hostile", "pandora")

	/// Our tumor
	var/obj/structure/elite_tumor/tumor
	/// Our pandora
	var/mob/living/simple_animal/hostile/asteroid/elite/pandora/pandora

/mob/living/simple_animal/hostile/pandora_horrors/Initialize(_pandora)
	. = ..()
	pandora = _pandora
	tumor = pandora.tumor

// ================= Brute =================
// MARK: BRUTE

// Толстый, имеет броню для эффективности АП, но энивей имеет резист к урону.

/mob/living/simple_animal/hostile/pandora_horrors/brute
	name = "Brute"
	desc = "A massive, purple glowing armored construct built to spearhead attacks and soak up enemy fire."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "juggernaut"
	icon_living = "juggernaut"
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	AIStatus = AI_ON
	deathmessage = "vanishes into purple dust."

	maxHealth = 150
	health = 150
	armor = list("melee" = 15, "bullet" = 35, "laser" = 25)
	damage_coeff = list(BRUTE = 0.75, BURN = 0.85)
	force_threshold = 10
	speed = -0.8
	ricochet_chance_mod = 10

	melee_damage_lower = 20
	melee_damage_upper = 40
	attack_verb_continuous = "smashes armored gauntlet into"
	attack_verb_simple = "smashes armored gauntlet into"
	attack_sound = 'sound/weapons/punch3.ogg'

	obj_damage = 90
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES

/mob/living/simple_animal/hostile/pandora_horrors/brute/proc/abil_shield()
	return TRUE

// ================= Wraith =================
// MARK: WRAITH

// При получении урона random_spot_arena_blink(), становится невидимым(95%) до первой атаки и создаёт иллюзию на старом месте, мили по которой слепит (иллюзия не моб).
// Атаки вызывают лёгкое кровотечение

/mob/living/simple_animal/hostile/pandora_horrors/wraith
	name = "Wraith"
	real_name = "Wraith"
	desc = "A wicked, clawed shell constructed to assassinate enemies and sow chaos behind enemy lines."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "wraith"
	icon_living = "wraith"
	maxHealth = 30
	health = 30
	damage_coeff = list(BRUTE = 0.8, BURN = 1.5)
	melee_damage_lower = 40
	melee_damage_upper = 40
	dodge_prob = 75
	sidestep_per_cycle = 3
	speed = 2
	retreat_distance = 2 //AI wraiths will move in and out of combat
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	AIStatus = AI_ON

	var/blink_cd = 0

/mob/living/simple_animal/hostile/pandora_horrors/wraith/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_MOB_APPLY_DAMGE, PROC_REF(random_spot_arena_blink))

/mob/living/simple_animal/hostile/pandora_horrors/wraith/proc/random_spot_arena_blink()
	SIGNAL_HANDLER

	if(blink_cd < world.time && prob(80))
		return
	var/list/turf/T = RANGE_TURFS(tumor.arena_range, tumor)
	T -= RANGE_TURFS(3, src)
	animate(alpha = 15, time = 1)
	forceMove(pick(T))
	new /obj/effect_orb/wraith_illusion(get_turf(src), src)
	blink_cd = world.time + 20 SECONDS

/mob/living/simple_animal/hostile/pandora_horrors/wraith/AttackingTarget()
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		var/bleed_
		for(var/obj/item/bodypart/BP as anything in C.bodyparts)
			BP.bleeding += bleed_
		bleed_ = bleed_ > 0.2 ? min(0.2, bleed_) : max(0.2, bleed_)
		C.cause_bleeding(bleed_)

// ========= Illusion =========
/obj/effect_orb
	name = "effect orb"
	desc = "orb that has effects"
	max_integrity = 1
	obj_integrity = 1
	var/_mode = "emit" // "emit" - passive apply effect around; "react" - apply to the cause of attack
	var/emittion_intencity = 50 // every 5 second by default
	var/emittion_timer
	var/_range = 2
	var/list/_effects = list("stun" = 0, "knockdown" = 0, "unconscious" = 0, "irradiate" = 0, "slur" = 0, "stutter" = 0, "eyeblur" = 0, "drowsy" = 0, "blocked" = 0, "stamina" = 0, "jitter" = 0, "paralyze" = 0, "immobilize" = 0, "blindness" = 0)

/obj/effect_orb/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)
	. = ..()
	if(_mode == "react")
		for(var/mob/living/carbon/L in range(_range))
			L.apply_effects(_effects["stun"], _effects["knockdown"], _effects["unconscious"], _effects["irradiate"], _effects["slur"], _effects["stutter"], _effects["eyeblur"], _effects["drowsy"], _effects["blocked"], _effects["stamina"], _effects["jitter"], _effects["paralyze"], _effects["immobilize"])
			L.blind_eyes(_effects["blindness"])

/obj/effect_orb/proc/change_mode(mode)
	if(mode)
		_mode = mode
	switch(_mode)
		if("react")
			if(emittion_timer)
				deltimer(emittion_timer)
			return TRUE
		if("emit")
			emittion_timer = addtimer(CALLBACK(src, PROC_REF(effects_emittion)), 1 SECONDS, TIMER_LOOP)
			return TRUE

/obj/effect_orb/proc/effects_emittion()
	for(var/mob/living/carbon/L in range(_range))
		L.apply_effects(_effects["stun"], _effects["knockdown"], _effects["unconscious"], _effects["irradiate"], _effects["slur"], _effects["stutter"], _effects["eyeblur"], _effects["drowsy"], _effects["blocked"], _effects["stamina"], _effects["jitter"], _effects["paralyze"], _effects["immobilize"])
		L.blind_eyes(_effects["blindness"])

/obj/effect_orb/wraith_illusion/Initialize(mapload, atom/wraith)
	. = ..()
	name = wraith.name
	desc = wraith.desc
	icon = wraith.icon
	icon_state = wraith.icon_state
	_effects["blindness"] = 1
	_effects["eyeblur"] = 2

// ================= Artificer =================
// MARK: ARTIFICER

// Шарахается вокруг, не дамажит, срёт замедляющими снарядами и пассивно лечит союзов
// Раз в 45 секунд ограждает союзника барьером с линией до него
// Убийство его лечит союзов
/mob/living/simple_animal/hostile/pandora_horrors/artificer
	name = "Artificer"
	real_name = "Artificer"
	desc = "A bulbous construct dedicated to building and maintaining the Cult of Nar'Sie's armies."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "artificer"
	icon_living = "artificer"
	maxHealth = 50
	health = 50
	response_harm_continuous = "viciously beats"
	response_harm_simple = "viciously beat"
	harm_intent_damage = 5
	obj_damage = 60
	melee_damage_lower = 5
	melee_damage_upper = 5
	retreat_distance = 10
	minimum_distance = 10
	attack_verb_continuous = "rams"
	attack_verb_simple = "ram"
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'sound/weapons/punch2.ogg'
	AIStatus = AI_ON

/mob/living/simple_animal/hostile/pandora_horrors/artificer/AttackingTarget()
	if(istype(target, /mob/living/simple_animal/hostile/pandora_horrors))
		var/mob/living/simple_animal/T = target
		T.heal_overall_damage(15,15)
	. = ..()

// ================= Harvester =================
// MARK: HARVESTER

/mob/living/simple_animal/hostile/pandora_horrors/harvester
	name = "Harvester"
	real_name = "Harvester"
	desc = "A long, thin construct built to herald Nar'Sie's rise. It'll be all over soon."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "harvester"
	icon_living = "harvester"
	maxHealth = 40
	health = 40
	loot = list()
	sight = SEE_MOBS
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	// can_repair_constructs = TRUE
