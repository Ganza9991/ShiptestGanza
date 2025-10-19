// An anomaly which simular to tvstatic. Chooses random open tursf around itself to spawn a lesser version of anomaly to them. After few attempts relocates around the z-lvl
/obj/effect/anomaly/radar
	name = "radar"
	icon_state = "crusher"
	desc = "A hole in the world emitting an endless buzzing. It hides something precious."
	density = FALSE
	effectrange = 3
	pulse_delay = 1
	immortal = TRUE	// stationary and indefinite
	immobile = TRUE
	core = null
	drops_core = FALSE
	var/list/radar_group = list()
	var/datum/looping_sound/radar/ls_radar
	var/list/kids = list()

/obj/effect/anomaly/radar/lesser
	effectrange = 2
	icon_state = "bouncer"
	var/parent

/obj/effect/anomaly/radar/lesser/brain_melt_message()
	return

/obj/effect/anomaly/radar/lesser/anomalyEffect(seconds_per_tick)
	return

/obj/effect/anomaly/radar/Initialize(mapload, new_lifespan, drops_core)
	. = ..()
	ls_radar = new(list(src), FALSE)
	if(src.type != /obj/effect/anomaly/radar/lesser) // not for lesser version
		addtimer(CALLBACK(src, PROC_REF(spread_strings), 5, rand(3,5)), 60 SECONDS, TIMER_LOOP)

/obj/effect/anomaly/radar/proc/spread_strings(range, count)
	say("spread_strings")
	var/list/Turfs = list()
	for(var/turf/open/T in range(3,src))
		Turfs += T

	if(Turfs.len)
		for(var/C in 1 to count)
			if(kids.len < count) // add if lesser
				var/obj/effect/anomaly/radar/lesser/kid = new (get_turf(src))
				kid.parent = src
				kids += kid
			else
				break
		for(var/obj/effect/anomaly/radar/lesser/kid in kids) // remove is exceeds
			if(kids.len > count)
				kid -= kids
				qdel(kid)
			else
				break
		for(var/obj/effect/anomaly/radar/lesser/kid in kids) // move kids
			var/turf/open/Tt = pick_n_take(Turfs)
			kid.forceMove(Tt)

/obj/effect/anomaly/radar/proc/brain_melt_message(victim)
	var/chars = "0123456789/|*-—––˜`';:#{}()+=_&^v<>%@ABCDEFGHIJKLMNOPQRSTUVWXYZАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
	var/result = ""
	for(var/i in 1 to rand(80,160)) // one huge is better than multiple small
		var/random_pos = rand(1, length_char(chars))
		result += copytext(chars, random_pos, random_pos + 1)
	to_chat(victim, span_boldwarning(result))

/obj/effect/anomaly/radar/anomalyEffect(seconds_per_tick)
	var/list/victims = list()
	for(var/mob/living/carbon/C in range(effectrange, src)) // Check for victims around me
		if((C.stat != DEAD) && !(C in victims))	victims += C

	for(var/obj/effect/anomaly/radar/lesser/kid in kids) // Check for victims around every kid
		for(var/mob/living/carbon/C in range(kid.effectrange, kid))
			if(C.stat != DEAD && !(C in victims))	victims += C

	for(var/mob/living/L in victims) // Affect every victim caught in any range. This way we avoid effect stacking (and specially sound stacking)
		L.playsound_local(L, 'mod_celadon/legionunited/code/anomaly/radar_scream.ogg', 100)
		L.adjustOrganLoss(ORGAN_SLOT_BRAIN, 4, 200)
		if(L.client)
			flash_color(L.client, "#ff0000", 7)
		brain_melt_message(L)

	if(prob(5) && kids.len) // exchange pos with random kid
		var/my_turf = get_turf(src)
		var/obj/picked_kid = pick(kids)
		var/kids_turf = get_turf(picked_kid)
		forceMove(kids_turf)
		picked_kid.forceMove(my_turf)

/datum/looping_sound/radar
	mid_sounds = list('mod_celadon/legionunited/code/anomaly/radar_idle.ogg')
	volume = 200
/*
/obj/effect/anomaly/radar/examine(mob/user)
	. = ..()
	if(!iscarbon(user))
		return
	if(iscarbon(user) && !user.research_scanner) //this'll probably cause some weirdness when I start using research scanner in more places / on more items. Oh well.
		var/mob/living/carbon/victim = user
		to_chat(victim, span_userdanger("Your head aches as you stare into [src]!"))
		victim.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5, 100)

*/
