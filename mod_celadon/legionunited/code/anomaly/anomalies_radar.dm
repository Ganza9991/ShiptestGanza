// Добавить в \code\game\objects\effects\spawners\random\anomaly.dm

/obj/effect/anomaly/radar
	name = "radar"
	icon_state = "static"
	desc = "A hole in the world emitting an endless buzzing. It hides something precious."
	density = FALSE
	effectrange = 4
	pulse_delay = 4 SECONDS
	speech_span = SPAN_ITALICS
	immortal = TRUE	// stationary and indefinite
	immobile = TRUE
	core = null
	var/datum/proximity_monitor/advanced/brainmelter/bmelter

/obj/effect/anomaly/radar/

/obj/effect/anomaly/radar/proc/brain_melt_message()
	var/chars = "/|\#"
	var/length = rand(10,20)
	var/result = ""
	for(var/i in 1 to length)
		var/random_pos = rand(1, chars.len)
		result += copytext(chars, random_pos, random_pos + 1)
	return result

/datum/proximity_monitor/advanced/brainmelter


/obj/effect/anomaly/radar/examine(mob/user)
	. = ..()
	if(!iscarbon(user))
		return
	if(iscarbon(user) && !user.research_scanner) //this'll probably cause some weirdness when I start using research scanner in more places / on more items. Oh well.
		var/mob/living/carbon/victim = user
		to_chat(victim, span_userdanger("Your head aches as you stare into [src]!"))
		victim.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5, 100)

/obj/effect/anomaly/radar/anomalyEffect()
	..()

	var/turf/spot = locate(rand(src.x-effectrange, src.x+effectrange), rand(src.y-effectrange, src.y+effectrange), src.z)
	new /obj/effect/particle_effect/staticball(spot)


	if(!COOLDOWN_FINISHED(src, pulse_cooldown))
		return

	COOLDOWN_START(src, pulse_cooldown, pulse_delay)

	for(var/mob/living/carbon/human/looking in range(effectrange, src))
		playsound(src, 'sound/effects/walkietalkie.ogg', 75)
		if(stored_mob && looking.stat != DEAD && prob(25))
			say_fucky_things()
		if(HAS_TRAIT(looking, TRAIT_MINDSHIELD) || looking.stat == DEAD || looking.research_scanner || HAS_TRAIT(looking, TRAIT_DEAF))
			continue
		looking.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10, 200)
		playsound(src, 'sound/effects/stall.ogg', 50)
		if(looking.getOrganLoss(ORGAN_SLOT_BRAIN) >= 150 && looking.stat != DEAD)
			if(prob(20))
				var/mob/living/carbon/victim = looking
				var/obj/effect/anomaly/tvstatic/planetary/expansion
				expansion = new(get_turf(victim))
				visible_message(span_warning("[src] overtakes [victim], [expansion] taking their place!"))
				victim.death()
				expansion.stored_mob = victim
				victim.forceMove(expansion)


/obj/effect/anomaly/radar/Bumped(atom/movable/AM)
	anomalyEffect()

/obj/effect/anomaly/radar/detonate()
	. = ..()

/obj/effect/anomaly/radar/anomalyNeutralize()
	var/turf/T = get_turf(src)
	if(T)
		if(stored_mob)
			visible_message(span_warning("[src] spits out [stored_mob], their body coming out in a burst!"))
			stored_mob.forceMove(get_turf(src))
			stored_mob = null
	. = ..()

/obj/effect/particle_effect/staticball
	name = "static blob"
	desc = "An unsettling mass of free floating static"
	icon = 'icons/effects/anomalies.dmi'
	icon_state = "static"

/obj/effect/particle_effect/staticball/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/particle_effect/staticball/LateInitialize()
	flick(icon_state, src)
	playsound(src, "walkietalkie", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	QDEL_IN(src, 20)

