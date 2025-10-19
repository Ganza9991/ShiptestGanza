// =================  =================
// MARK: TEMPLATE
/mob/living/simple_animal/hostile/pandora_horrors
	name = "Unimaginable thing"
	desc = "Try to imagine it."

	var/obj/structure/elite_tumor/tumor

// ================= Juggernaut =================
// MARK: JUGGERNAUT

/mob/living/simple_animal/hostile/pandora_horrors/juggernaut
	name = "Juggernaut"
	real_name = "Juggernaut"
	desc = "A massive, purple glowing armored construct built to spearhead attacks and soak up enemy fire."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "juggernaut"
	icon_living = "juggernaut"
	maxHealth = 150
	health = 150
	armor = list("melee" = 15, "bullet" = 35, "laser" = 35)
	damage_coeff = list(0.75,0.75)
	faction = list("pandora")
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 90
	melee_damage_lower = 20
	melee_damage_upper = 40
	deathmessage = "vanishes into purple dust."
	attack_verb_continuous = "smashes their armored gauntlet into"
	attack_verb_simple = "smash your armored gauntlet into"
	speed = -0.8
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'sound/weapons/punch3.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	force_threshold = 10
	AIStatus = AI_ON
	// construct_spells = list(/obj/effect/proc_holder/spell/targeted/forcewall/,
	// 							/obj/effect/proc_holder/spell/targeted/projectile/dumbfire/juggernaut)

/mob/living/simple_animal/hostile/construct/juggernaut/wizard/bullet_act(obj/projectile/P)
	. = ..()

// ================= Wraith =================
// MARK: WRAITH

/mob/living/simple_animal/hostile/pandora_horrors/wraith
	name = "Wraith"
	real_name = "Wraith"
	desc = "A wicked, clawed shell constructed to assassinate enemies and sow chaos behind enemy lines."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "wraith"
	icon_living = "wraith"
	maxHealth = 30
	health = 30
	damage_coeff = list(BRUTE = 0.8, BURN = 2)
	faction = list("pandora")
	melee_damage_lower = 40
	melee_damage_upper = 40
	speed = 2
	retreat_distance = 2 //AI wraiths will move in and out of combat
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	AIStatus = AI_ON
	// construct_spells = list(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift)

/mob/living/simple_animal/hostile/pandora_horrors/wraith/proc/opposite_side_arena_blink()
	// взять все турфы арены, минусануть зону 4х4 вокруг моба из листа и пикнуть турф для ТП из листа
	var/list/turf/T = RANGE_TURFS(tumor.arena_range, tumor)
	T -= RANGE_TURFS(3, src)
	forceMove(pick(T))

//////////////
/obj/effect/temp_visual/dir_setting/wraith/wizard
	name = "shadow"
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "phase_shift2_wizard"
	duration = 6

/obj/effect/temp_visual/dir_setting/wraith/wizard/out
	icon_state = "phase_shift_wizard"

/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift
	name = "Phase Shift"
	desc = "This spell allows you to pass through walls."
	invocation = "none"
	invocation_type = "none"
	range = -1
	include_user = TRUE
	jaunt_duration = 50 //in deciseconds
	action_icon = 'icons/mob/actions/actions_cult.dmi'
	action_icon_state = "phaseshift"
	action_background_icon_state = "bg_demon"
	jaunt_in_time = 6
	jaunt_in_type = /obj/effect/temp_visual/dir_setting/wraith/wizard
	jaunt_out_type = /obj/effect/temp_visual/dir_setting/wraith/wizard/out

// ================= Artificer =================
// MARK: ARTIFICER

/mob/living/simple_animal/hostile/pandora_horrors/artificer
	name = "Artificer"
	real_name = "Artificer"
	desc = "A bulbous construct dedicated to building and maintaining the Cult of Nar'Sie's armies."
	icon = 'mod_celadon/_storge_icons/icons/mobs/wizard_constructs.dmi'
	icon_state = "artificer"
	icon_living = "artificer"
	maxHealth = 50
	health = 50
	faction = list("pandora")
	response_harm_continuous = "viciously beats"
	response_harm_simple = "viciously beat"
	harm_intent_damage = 5
	obj_damage = 60
	melee_damage_lower = 5
	melee_damage_upper = 5
	retreat_distance = 10
	minimum_distance = 10 //AI artificers will flee like fuck
	attack_verb_continuous = "rams"
	attack_verb_simple = "ram"
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'sound/weapons/punch2.ogg'
	AIStatus = AI_ON
	// construct_spells = list(/obj/effect/proc_holder/spell/targeted/projectile/magic_missile/lesser)
	// can_repair_constructs = TRUE
	// can_repair_self = TRUE

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
	faction = list("pandora", "Wizard")
	loot = list()
	sight = SEE_MOBS
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	// can_repair_constructs = TRUE
