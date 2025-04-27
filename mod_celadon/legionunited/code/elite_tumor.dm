#define TUMOR_INACTIVE 0
#define TUMOR_ACTIVE 1
#define TUMOR_PASSIVE 2

//The Pulsing Tumor, the actual "spawn-point" of elites, handles the spawning, arena, and procs for dealing with basic scenarios.

/obj/structure/elite_tumor
	name = "pulsing tumor"
	desc = "An odd, pulsing tumor sticking out of the ground.  You feel compelled to reach out and touch it..."
	armor = list("melee" = 100, "bullet" = 100, "laser" = 100, "energy" = 100, "bomb" = 100, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)
	resistance_flags = INDESTRUCTIBLE
	icon = 'mod_celadon/_storge_icons/icons/obj/tumor.dmi'
	icon_state = "tumor"
	pixel_x = -16
	base_pixel_x = -16
	light_color = COLOR_SOFT_RED
	light_range = 3
	anchored = TRUE
	density = FALSE
	var/activity = TUMOR_INACTIVE
	var/boosted = FALSE
	var/times_won = 0
	var/doom = FALSE
	var/mfauna
	var/list/mob/living/fighters = list()
	var/mob/living/simple_animal/hostile/asteroid/elite/mychild = null
	var/potentialspawns = list(/mob/living/simple_animal/hostile/asteroid/elite/broodmother,
								/mob/living/simple_animal/hostile/asteroid/elite/pandora,
								/mob/living/simple_animal/hostile/asteroid/elite/legionnaire,
								/mob/living/simple_animal/hostile/asteroid/elite/herald)

	var/list/arena_walls = list()
	var/arena_range = 10

/obj/structure/elite_tumor/attack_hand(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	switch(activity)
		if(TUMOR_PASSIVE)
			// Prevents the user from being forcemoved back and forth between two elite arenas.
			if(HAS_TRAIT(user, TRAIT_ELITE_CHALLENGER))
				user.visible_message(span_warning("[user] reaches for [src] with [user.p_their()] arm, but nothing happens."),
					span_warning("You reach for [src] with your arm... but nothing happens."))
				return
			activity = TUMOR_ACTIVE
			user.visible_message(span_boldwarning("[src] convulses as [user]'s arm enters its radius.  Uh-oh..."),
				span_boldwarning("[src] convulses as your arm enters its radius.  Your instincts tell you to step back."))
			make_fighter(user)
			if(boosted)
				mychild.playsound_local(get_turf(mychild), 'sound/effects/magic.ogg', 40, 0)
				to_chat(mychild, "<b>Someone has activated your tumor.  You will be returned to fight shortly, get ready!</b>")
			addtimer(CALLBACK(src, PROC_REF(return_elite)), 30)
			INVOKE_ASYNC(src, PROC_REF(arena_checks))
		if(TUMOR_INACTIVE)
			if(HAS_TRAIT(user, TRAIT_ELITE_CHALLENGER))
				user.visible_message(span_warning("[user] reaches for [src] with [user.p_their()] arm, but nothing happens."),
					span_warning("You reach for [src] with your arm... but nothing happens."))
				return
			activity = TUMOR_ACTIVE
			var/mob/dead/observer/elitemind = null
			visible_message(span_boldwarning("[src] begins to convulse. Your instincts tell you to step back."))
			make_fighter(user)
			if(!boosted)
				addtimer(CALLBACK(src, PROC_REF(spawn_elite)), 30)
				return
			visible_message(span_boldwarning("Something within [src] stirs..."))
			var/list/candidates = pollCandidatesForMob("Do you want to play as a lavaland elite?", ROLE_SENTIENCE, null, ROLE_SENTIENCE, 50, src, POLL_IGNORE_SENTIENCE_POTION)
			if(candidates.len)
				audible_message(span_boldwarning("The stirring sounds increase in volume!"))
				elitemind = pick(candidates)
				elitemind.playsound_local(get_turf(elitemind), 'sound/effects/magic.ogg', 40, 0)
				to_chat(elitemind, "<b>You have been chosen to play as a Lavaland Elite.\nIn a few seconds, you will be summoned on Lavaland as a monster to fight your fighters, in a fight to the death.\n\
					Your attacks can be switched using the buttons on the top left of the HUD, and used by clicking on targets or tiles similar to a gun.\n\
					While the opponent might have an upper hand with  powerful mining equipment and tools, you have great power normally limited by AI mobs.\n\
					If you want to win, you'll have to use your powers in creative ways to ensure the kill. It's suggested you try using them all as soon as possible.\n\
					Should you win, you'll receive extra information regarding what to do after. Good luck!</b>")
				addtimer(CALLBACK(src, PROC_REF(spawn_elite), elitemind), 100)
			else
				visible_message(span_boldwarning("The stirring stops, and nothing emerges.  Perhaps try again later."))
				activity = TUMOR_INACTIVE
				clear_fighter(user)

/obj/structure/elite_tumor/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/gps, "Menacing Signal")
	START_PROCESSING(SSobj, src)

/obj/structure/elite_tumor/Destroy()
	STOP_PROCESSING(SSobj, src)
	mychild = null
	clear_fighter(fighters)
	return ..()

/obj/structure/elite_tumor/process(seconds_per_tick)
	if(isturf(loc))
		for(var/mob/living/simple_animal/hostile/asteroid/elite/elitehere in loc)
			if(elitehere == mychild && activity == TUMOR_PASSIVE)
				mychild.adjustHealth(-mychild.maxHealth*0.025*seconds_per_tick)
				var/obj/effect/temp_visual/heal/H = new /obj/effect/temp_visual/heal(get_turf(mychild))
				H.color = "#FF0000"

/obj/structure/elite_tumor/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(istype(I, /obj/item/organ/regenerative_core) && activity == TUMOR_INACTIVE && !boosted && !doom)
		var/obj/item/organ/regenerative_core/core = I
		if(!core.preserved)
			return
		visible_message(span_boldwarning("As [user] drops the core into [src], [src] appears to swell."))
		icon_state = "advanced_tumor"
		boosted = TRUE
		light_range = 6
		desc = "[desc]  This one seems to glow with a strong intensity."
		qdel(core)
		return TRUE
	if(istype(I, /obj/item/gem) && activity == TUMOR_INACTIVE && !boosted && !doom)
		var/obj/item/gem/gem = I
		doom = TRUE
		light_range = 6
		switch(gem.type)
			if(/obj/item/gem/phoron)
				potentialspawns = list(/mob/living/simple_animal/hostile/megafauna/hierophant)
				mfauna = "hierophant_"
				// icon_state = "hierophant_tumor_passive"
				// flick("hierophant_tumor_rise", src)
				playsound(loc,'sound/magic/blind.ogg', 150, 0, 50, TRUE, TRUE)
				desc = "[desc] Around it appears to be glowing purple squares."
				visible_message("<span class='boldwarning'>As [user] drops the [gem] into [src], purple glowing shapes appears around [src].</span>")
			if(/obj/item/gem/bloodstone)
				potentialspawns = list(/mob/living/simple_animal/hostile/megafauna/bubblegum)
				mfauna = "bubblegum_"
				icon_state = "bubblegum_tumor_passive"
				flick("bubblegum_tumor_rise", src)
				playsound(loc,'sound/magic/blind.ogg', 150, 0, 50, TRUE, TRUE)
				desc = "[desc] This one seems to be soaked with red blood."
				visible_message("<span class='boldwarning'>As [user] drops the [gem] into [src], a burst of blood coming out.</span>")
			if(/obj/item/gem/rupee)
				potentialspawns = list(/mob/living/simple_animal/hostile/megafauna/colossus)
				mfauna = "colossus_"
				icon_state = "colossus_tumor_passive"
				flick("colossus_tumor_rise", src)
				playsound(loc,'sound/weapons/pierce_slow.ogg', 150, 0, 50, TRUE, TRUE)
				desc = "[desc] There is a spikes around it."
				visible_message("<span class='boldwarning'>As [user] drops the [gem] into [src], a small metal spikes starts to rise around it.</span>")
			if(/obj/item/gem/amber)
				potentialspawns = list(/mob/living/simple_animal/hostile/megafauna/dragon)
				mfauna = "dragon_"
				// icon_state = "dragon_tumor_passive"
				// flick("dragon_tumor_rise", src)
				playsound(loc,'sound/creatures/legion_death_far.ogg', 50, 0, 50, TRUE, TRUE)
				desc = "[desc] A black fog coming from within."
				visible_message("<span class='boldwarning'>As [user] drops the [gem] into [src], a distant growl comes from within.</span>")
			if(/obj/item/gem/void)
				potentialspawns = list(/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner)
				mfauna = "dfminer_"
				// icon_state = "demonfrostminer_tumor_passive"
				// flick("demonfrostminer_tumor_rise", src)
				playsound(loc,'sound/creatures/narsie_rises.ogg', 50, 0, 50, TRUE, TRUE)
				desc = "An odd, pulsing tumor sticking out of the ground. You feel a strange feeling, that telling you to reach out and touch it... and run away as far as you can and cannot. Ice forms on and around it."
				visible_message("<span class='boldwarning'>As [user] drops the [gem] into [src], it suddenly changes colors to void black, as a strange energy comes from within. You have awaken something terrible...</span>")
		qdel(gem)

// ================= Fighter Interaction =================
// MARK: FIGHTER INTERACT

/obj/structure/elite_tumor/proc/make_fighter(mob/user)
	if(user in fighters)
		return
	if(mychild && get_dist(user, mychild) > 15)
		return
	fighters += user
	ADD_TRAIT(user, TRAIT_ELITE_CHALLENGER, REF(src))
	RegisterSignal(user, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(clear_fighter))
	user.log_message("engaged in a fight with Elite Tumor!", LOG_GAME, color="#960000")

/obj/structure/elite_tumor/proc/clear_fighter(mob/source)
	SIGNAL_HANDLER
	if(!fighters)
		return
	fighters = null
	REMOVE_TRAIT(source, TRAIT_ELITE_CHALLENGER, REF(src))
	UnregisterSignal(source, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), COMSIG_PARENT_QDELETING)

// ================= Elite Interaction =================
// MARK: ELITE INTERACT

/obj/structure/elite_tumor/proc/spawn_elite(mob/dead/observer/elitemind)
	var/selectedspawn = pick(potentialspawns)
	mychild = new selectedspawn(loc)
	visible_message(span_boldwarning("[mychild] emerges from [src]!"))
	playsound(loc,'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)
	if(iselitefauna(mychild))
		for(var/mob/living/carbon/C in range(arena_range, src))
			mychild.maxHealth += 150
			mychild.health = mychild.maxHealth
	if(boosted)
		mychild.key = elitemind.key
		mychild.sentience_act()
		notify_ghosts("\A [mychild] has been awakened in \the [get_area(src)]!", source = mychild, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Lavaland Elite awakened")
	icon_state = "[mfauna]tumor_popped"
	INVOKE_ASYNC(src, PROC_REF(arena_checks))
	addtimer(CALLBACK(src, PROC_REF(arena_checks)), 50, TIMER_LOOP|TIMER_UNIQUE)

	mychild.tumor = src
	RegisterSignal(mychild, list(COMSIG_MOB_ITEM_AFTERATTACK), PROC_REF(make_fighter))

/obj/structure/elite_tumor/proc/return_elite()
	mychild.forceMove(loc)
	visible_message(span_boldwarning("[mychild] emerges from [src]!"))
	playsound(loc,'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)
	mychild.revive(full_heal = TRUE, admin_revive = TRUE)
	if(boosted)
		mychild.maxHealth = mychild.maxHealth * 2
		mychild.health = mychild.maxHealth
		notify_ghosts("\A [mychild] has been challenged in \the [get_area(src)]!", source = mychild, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Lavaland Elite challenged")

/obj/structure/elite_tumor/proc/onEliteLoss()
	playsound(loc,'sound/effects/tendril_destroyed.ogg', 200, 0, 50, TRUE, TRUE)
	visible_message(span_boldwarning("[src] begins to convulse violently before beginning to dissipate."))
	visible_message(span_boldwarning("As [src] closes, something is forced up from down below."))
	var/obj/structure/closet/crate/necropolis/tendril/lootbox = new /obj/structure/closet/crate/necropolis/tendril(loc)
	if(boosted)
		if(mychild.loot_drop != null && prob(50))
			new mychild.loot_drop(lootbox)
	clear_fighter(fighters)
	qdel(src)

/obj/structure/elite_tumor/proc/onEliteWon()
	activity = TUMOR_PASSIVE
	clear_fighter(fighters)
	mychild.revive(full_heal = TRUE, admin_revive = TRUE)
	if(boosted)
		times_won++
		mychild.maxHealth = mychild.maxHealth * 0.5
		mychild.health = mychild.maxHealth
	if(times_won == 1)
		mychild.playsound_local(get_turf(mychild), 'sound/effects/magic.ogg', 40, 0)
		to_chat(mychild, span_boldwarning("As the life in the fighters's eyes fade, the forcefield around you dies out and you feel your power subside.\nDespite this inferno being your home, you feel as if you aren't welcome here anymore.\nWithout any guidance, your purpose is now for you to decide."))
		to_chat(mychild, "<b>Your max health has been halved, but can now heal by standing on your tumor.  Note, it's your only way to heal.\nBear in mind, if anyone interacts with your tumor, you'll be resummoned here to carry out another fight.  In such a case, you will regain your full max health.\nAlso, be weary of your fellow inhabitants, they likely won't be happy to see you!</b>")
		to_chat(mychild, "<span class='big bold'>Note that you are an alien entity, and thus not allied to the sector. Your path now is up to you.</span>")

// ================= Arena Checks =================
// MARK: ARENA CHECKS

/obj/structure/elite_tumor/proc/arena_checks()
	if(activity != TUMOR_ACTIVE || QDELETED(src))
		return
	INVOKE_ASYNC(src, PROC_REF(fighters_check))  //Checks to see if our fighters died.
	INVOKE_ASYNC(src, PROC_REF(arena_trap))  //Gets another arena trap queued up for when this one runs out.
	INVOKE_ASYNC(src, PROC_REF(border_check))  //Checks to see if our fighters got out of the arena somehow.

/obj/structure/elite_tumor/proc/fighters_check()
	if(!fighters.len && activity == TUMOR_ACTIVE)
		onEliteWon()
	if(mychild != null && mychild.stat == DEAD || activity == TUMOR_ACTIVE && QDELETED(mychild))
		onEliteLoss()

/obj/structure/elite_tumor/proc/arena_trap()
	if(arena_walls.len)
		QDEL_LIST(arena_walls)
	var/turf/T = get_turf(src)
	if(loc == null)
		return
	for(var/t in RANGE_TURFS(arena_range, T))
		if(get_dist(t, T) == arena_range)
			var/obj/effect/temp_visual/elite_tumor_wall/newwall = new (t)
			newwall.fighters = src.fighters
			newwall.ourelite = src.mychild
			arena_walls += newwall

/obj/structure/elite_tumor/proc/border_check()
	if(fighters.len)
		for(var/mob/living/A in fighters)
			if(get_dist(src, A) > arena_range+5)
				A.forceMove(loc)
				visible_message(span_boldwarning("[A] suddenly reappears above [src]!"))
				playsound(loc,'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)
				A.Knockdown(10)
			else if(get_dist(src, A) > arena_range)
				var/turf/T = get_closest_atom(/obj/effect/temp_visual/elite_tumor_wall, arena_walls, get_turf(A))
				T = get_step_towards(T,src)
				A.forceMove(T)
				A.Knockdown(1)
	if(mychild != null && get_dist(src, mychild) >= 10)
		mychild.forceMove(loc)
		visible_message(span_boldwarning("[mychild] suddenly reappears above [src]!"))
		playsound(loc,'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)

// ================= Visuals =================
// MARK: VISUALS

/obj/effect/temp_visual/elite_tumor_wall
	name = "magic wall"
	icon = 'icons/turf/walls/hierophant_wall_temp.dmi'
	icon_state = "hierophant_wall_temp-0"
	base_icon_state = "hierophant_wall_temp"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_HIERO_WALL)
	canSmoothWith = list(SMOOTH_GROUP_HIERO_WALL)
	duration = 50
	layer = BELOW_MOB_LAYER
	color = rgb(255,0,0)
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	light_color = COLOR_SOFT_RED
	var/mob/living/carbon/human/fighters = null
	var/mob/living/simple_animal/hostile/asteroid/elite/ourelite = null

/obj/effect/temp_visual/elite_tumor_wall/Initialize(mapload, new_caster)
	. = ..()
	if(smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
		QUEUE_SMOOTH_NEIGHBORS(src)
		QUEUE_SMOOTH(src)

/obj/effect/temp_visual/elite_tumor_wall/Destroy()
	if(smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
		QUEUE_SMOOTH_NEIGHBORS(src)
	// [CELADON-REMOVE] - CELADON_BALANCE_MOBS
	// fighters = null
	// ourelite = null
	// [/CELADON-REMOVE]
	return ..()

/obj/effect/temp_visual/elite_tumor_wall/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	// [CELADON-EDIT] - CELADON_BALANCE_MOBS
	// if(mover == ourelite || mover == fighters)
	// 	return FALSE	// CELADON-EDIT - ORIGINAL
	return FALSE
	// [/CELADON-EDIT]


// ================= VV =================
// MARK: VV

/obj/structure/elite_tumor/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION("determine_elite", "Determine Elite to spawn")

/obj/structure/elite_tumor/vv_do_topic(list/href_list)
	. = ..()
	if(href_list["determine_elite"])
		var/atom/temp = tgui_input_list(usr, "Choose an Elite", "Elite list", list("Broodmother","Legionnare","Pandora","Herald"))
		if(!temp)
			return "Cancel"
		switch(temp)
			if("Broodmother")
				temp = /mob/living/simple_animal/hostile/asteroid/elite/broodmother
			if("Legionnare")
				temp = /mob/living/simple_animal/hostile/asteroid/elite/legionnaire
			if("Pandora")
				temp = /mob/living/simple_animal/hostile/asteroid/elite/pandora
			if("Herald")
				temp = /mob/living/simple_animal/hostile/asteroid/elite/herald
		potentialspawns = list(temp)
		to_chat(usr, "[temp.name] is choosen to be as spawn.")
