// If its here than i forgot to delete it
/obj/machinery/drill/New(loc, ...)
	if(ispath(/obj/machinery/heavy_mining_drill))
		new /obj/machinery/heavy_mining_drill(get_turf(src))
		qdel(src)
		return
	else
		. = ..()

/*
//For handling the types of randomized malfunctions
#define MALF_LASER 1
#define MALF_SENSOR 2
#define MALF_CAPACITOR 3
#define MALF_STRUCTURAL 4
#define MALF_CALIBRATE 5

//For handling the repair of a completely destroyed drill
#define METAL_ABSENT 0
#define METAL_PLACED 1
#define METAL_SECURED 2
*/

/* TODO:
Переписать malfuntion под list("capasitor")
все проверки vein в терминал, а там из vein в deep_drilling_site
Замена частей через радиалку
Нельзя отключить батарею если работаем
Сделать портативный глубинный сканер. В нём должен лежать Т2 сканер. Сканирование планеты на точку добычи идёт в 3 этапа: Вокруг точки добычи создаётся невидимый эффект (зона сканирования) вокруг которой нужно просканировать и повторить этот этап 3 раза. После 3 раза даётся точка копания.
Сделать устанавливаемые схемы. При установке они создают голограмму объекта, в которую нужно пихать ресурсы чтобы построить.
Доп машинерия должна иметь лазеры и капаситоры минимум 3 рейтинга
Возможно в будущем перевести часть повторяющегося кода в один прок, а от туда уже воспроизводить команды через switch(text)
возможно лучше будет перевести всё на русский или сделать переключаемый язык внутри терминала
Батарейку можно вытащить во время работы только в харм интенте. При этом все части визуально выходят из строя в терминали (но 50% на реальную полому) и система выключается
\
Обычное бурение будет спавнить просто глубинных мобов. Суть бурения без задания - руды
Особое задание на глубинную дрель будет подразумевать бурение из глубинного комплекса. В таком случае бурение идёт в 3 этапа: Поверхность/Глубина/Комплекс.
	Будут несколько "видов" комплексов, различия будут в основном спавн мобов: Заброшенный (Зомби), Работающий (Гуманоиды)
	Цель компи комплекса: Диск данных; Сейф; Труп человека/питомца

*/

// ================= Designator for drilling site =================
// MARK: DESIGNATOR
/obj/effect/deep_drilling_site
	icon_state = "phasein"
	var/rock_density
	var/list/possible_ores = list(
		/obj/item/stack/ore/iron,
		/obj/item/stack/ore/silver,
		/obj/item/stack/ore/uranium,
		/obj/item/stack/ore/gold,
		/obj/item/stack/ore/plasma,
		/obj/item/stack/ore/diamond,
		/obj/item/stack/ore/titanium)
	var/ore_left
	var/list/surface_drilling_progress = list(0,200) // list[1] is current progress, list[2] is max progress
	var/list/deep_drilling_progress = list(0,400)
	var/list/progress_until_ore

/obj/effect/deep_drilling_site/Initialize(mapload)
	. = ..()
	rock_density = rand(1,3)
	ore_left = rand(15,20)
	progress_until_ore = list(0,floor(deep_drilling_progress[2] % ore_left))
	surface_drilling_progress[2] += rand(0,200)
	deep_drilling_progress[2] += rand(0,200)

/obj/effect/deep_drilling_site/proc/is_in_drilling_range(atom/A)
	if(A in range(3,src))
		return TRUE
	return FALSE

// ================= Objects =================
// MARK: DRILL

/obj/machinery/heavy_mining_drill
	name = "deep core laser mining drill"
	desc = "A large scale laser drill. It's able to mine vast amounts of minerals from near-surface ore pockets, however the seismic activity tends to anger local fauna."
	icon = 'icons/obj/machines/drill.dmi'
	icon_state = "deep_core_drill"
	max_integrity = 400
	density = TRUE
	anchored = FALSE
	use_power = NO_POWER_USE
	layer = ABOVE_ALL_MOB_LAYER
	armor = list("melee" = 50, "bullet" = 30, "laser" = 30, "energy" = 30, "bomb" = 30, "bio" = 0, "rad" = 0, "fire" = 90, "acid" = 90)
	component_parts = list()

	// All of the messages inside interface containts here
	var/list/message_log = list("Use command 'help' to access available commands.")
	var/command_in_progress = FALSE

	// First layer of health. After breaking the machine will take irreversable damage to internals
	var/plating_integrity = 2000
	var/metal_attached = METAL_ABSENT

	// = = = Drilling Mining
	var/obj/effect/deep_drilling_site/drsite
	var/drilling_timer

	// = = = Terminal Machinery
	var/is_active = FALSE
	var/maintenance = FALSE
	// List of malfunctions
	var/list/malfunctions = list("capacitor" = FALSE, "scanning_module" = FALSE, "micro_laser" = FALSE)

	var/datum/looping_sound/drill/soundloop
	var/obj/item/stock_parts/cell/super/cell
	var/power_cost = 100

/obj/machinery/heavy_mining_drill/Initialize()
	. = ..()
	cell = new(null)
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stock_parts/scanning_module(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)
	soundloop = new(list(src), is_active)

/obj/machinery/heavy_mining_drill/Destroy()
	qdel(soundloop)
	return ..()

/* MARK: PROCCESS()
/obj/machinery/heavy_mining_drill/process(seconds_per_tick)
	if(machine_stat & BROKEN || (is_active && !drsite))
		is_active = FALSE
		soundloop.stop()
		update_overlays()
		update_icon_state()
	if(!is_active && drsite?.currently_spawning)
		drsite.toggle_spawning()
*/
/obj/machinery/heavy_mining_drill/examine(mob/user)
	. = ..()
	if(maintenance)
		. += "Maintenance panel is open."

/obj/machinery/heavy_mining_drill/proc/soft_calibration_check(turf/open/T)
	if(drsite.is_in_drilling_range(src))
		return TRUE
	else
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		to_varlog("ERROR", "Calibrated is out of range now.")
		drsite = null
		return FALSE

// ========= Drill side part =========
// MARK: DRILL SIDE PART

/* todo:
Два лазера по бокам (верт или горизонт). Они и выполняют копку и доставку ресурсов на поверхность
essential: два лазера и капаситор
Потребление в дрель
Каждый лазер при установке добавляет свой % эффективности в основу, от чего уже высчитывается эфф копки
*/

/obj/machinery/heavy_mining_drill_side
	name = "hmd side part"
	anchored = FALSE

/obj/machinery/heavy_mining_drill_side/Initialize()
	. = ..()
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)

// ================= User Interface =================
// MARK: UI

/obj/machinery/heavy_mining_drill/attack_hand(mob/living/user)
	. = ..()
	playsound(src, 'sound/machines/terminal_prompt.ogg', 75)

/obj/machinery/heavy_mining_drill/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DrillControl", name)
		ui.open()

/obj/machinery/heavy_mining_drill/ui_data(mob/user)
	var/list/data = list()
	data["is_active"] = is_active
	data["integrity"] = obj_integrity
	data["max_integrity"] = max_integrity
	data["cell_charge"] = cell.charge
	data["cell_maxcharge"] = cell.maxcharge
	data["message_log"] = message_log
	data["malfunctions"] = malfunctions
	return data

/obj/machinery/heavy_mining_drill/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("command_input")
			command_input(params["message"])
	return FALSE

/obj/machinery/heavy_mining_drill/proc/to_varlog(logtype, message)
	switch(logtype)
		if("ERROR")
			playsound(src, 'sound/machines/triple_beep.ogg', 50)
		if("REGULAR")
		if("SILENT")
		if("SUCCESS")
			playsound(src, 'sound/machines/synth_yes.ogg', 50)

	if(message)
		message_log += "[message]"

// ================= System Commands =================
// MARK: COMMANDS

// MARK: —Manual input
/// Команды из терминала от юзера летят сюда
/obj/machinery/heavy_mining_drill/proc/command_input(message)
	if(!message)
		return FALSE

	to_varlog("SILENT", "/drillv02.exe>[message]")

	var/correct_promt = TRUE
	command_in_progress = TRUE
	switch(message)
		if("help")
			to_varlog("SILENT", "help; version; components; startup; calibrate;")
			command_in_progress = FALSE
		if("cellcheck")
			if(command_battery_check())
				command_in_progress = FALSE
		if("activate")
			if(is_active)
				to_varlog("SILENT", "System already already in operating mode.")
				break
			command_turn_on()
		if("deactivate")
			if(!is_active)
				to_varlog("SILENT", "System is not operating.")
				break
			command_turn_off()
		if("startdrilling")
		if("calibrate")
			command_calibrate()
		if("components")
			command_component_check()
		if("anchor")
			command_anchor()
		if("version")
			to_varlog("SILENT", "UnionDox Operating system <Version 0.10.14798.8093 (PRIVATE)>")
			to_varlog("SILENT", "Copyright (c) AsteroidDynamics. All rights reserved.")
			command_in_progress = FALSE
		else
			to_varlog("SILENT","command not recognised")
			command_in_progress = FALSE
			correct_promt = FALSE

	if(correct_promt)
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50)
	else
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50)

// MARK: —Turn on
// Включаем компутер
// Ступени дрели: Включение компа (turn_on) -> Калибровка (calibrate) -> Якорь (anchor) -> Копаем (drilling)
/obj/machinery/heavy_mining_drill/proc/command_turn_on()
	playsound(src, 'sound/machines/switch2.ogg', 75)
	to_varlog("SILENT", "Starting function initiated.")
	dot_spam(rand(3,5),10,50)

	if(!locate(/obj/item/stock_parts/capacitor) in component_parts)
		to_varlog("ERROR", "ERROR#23: Capacitor is broken or not present in the system.")
		return FALSE
	if(!cell.charge < 20000)
		to_varlog("ERROR", "WARNING! Battery charge is less than recomended.")
		sleep(2)
	if(!anchored) // Лучше заменить на anchored_check чтобы проверить все составные в округе, либо сделать эти чеки в команде
		to_varlog("ERROR", "ERROR#7: Drill or additional machinery is not anchored together and/or to the ground.")
		return FALSE


	to_varlog("SILENT", "Turning on the system...")
	//playsound() звуки запуска дрелли, шипения, крехтения
	//soundloop
	sleep(rand(100,200))
	to_varlog("SUCCESS", "System start up successful.")
	// запихнуть поверх оверлеев свечения, света и звуков
	is_active = TRUE

// MARK: —Turn off
/obj/machinery/heavy_mining_drill/proc/command_turn_off()
	is_active = FALSE
	return TRUE

// MARK: —Battery check
/obj/machinery/heavy_mining_drill/proc/command_battery_check()
	to_varlog("SILENT", "Testing present battery.")
	if(!cell)
		sleep(10)
		to_varlog("ERROR", "ERROR#4: Battery either broken or not present in the system.")
		return FALSE
	dot_spam(rand(3),10,30)

	if(cell.maxcharge < 20000) // less than super-cell
		to_varlog("ERROR", "WARNING! Capacity of the present cell is less than recomended.")
	if(!cell.use(100,0))
		to_varlog("ERROR", "ERROR#5: Not enough power in the system.")
		return FALSE
	if(cell.maxcharge < power_cost)
		to_varlog("ERROR", "ERROR#4: System requires a higher capacity cell.")
		return FALSE

	return TRUE

// MARK: —Calibrate
/obj/machinery/heavy_mining_drill/proc/command_calibrate()
// Также выдаём сводку о твёрдости пароды (время на копание) и рудах
	if(!is_active)
		dot_dot_dot()
		to_varlog("ERROR", "ERROR#2: No response from the system. Make sure the machine is turned on.")
		return FALSE
	if(!locate(/obj/item/stock_parts/scanning_module) in component_parts)
		to_varlog("ERROR","ERROR#24: Scanning module is broken or not present in the system.")
		return FALSE
	dot_spam(3,20,60)

	var/obj/effect/deep_drilling_site/drilling_site = locate(/obj/effect/deep_drilling_site) in view(4, src)
	if(!drilling_site)
		to_varlog("ERROR", "ERROR#57: No valid drilling sites were detected.")
		return FALSE
	else if(drilling_site.is_in_drilling_range(src))
		to_varlog("SILENT", "Drilling site detected, calibrating systems.")
		//playsound() Звуки крехтения и наведения
		hex_spam(10)
		to_varlog("SILENT", "done.")
		sleep(10)
		to_varlog("SILENT", "{0.000000@0 deinterlace0(med):0x7dd00000 - 0X800000(35)}")
		sleep(10)
		to_varlog("SUCCESS", "Calibration complete.")
		drsite = drilling_site
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(soft_calibration_check))

		var/ores
		for(var/obj/item/stack/ore/ore in drsite.possible_ores)
			ores+= ore.name + "; "
		to_varlog("SILENT", "Ores detected: [ores]")
		to_varlog("SILENT", "Rock density is: [drsite.rock_density]")
	else // step 1 tile closer
		to_varlog("ERROR", "ERROR#59: Drilling site is detected but out of range.")
		return FALSE
	command_in_progress = FALSE

// MARK: —Component check
/obj/machinery/heavy_mining_drill/proc/command_component_check()
	to_varlog("SILENT", "Testing system performance...")
	sleep(rand(10,30))
	for(var/C in 1 to 4)
		var/output
		switch(C)
			if(1)
				output = "Capacitor: "
				output += (/obj/item/stock_parts/capacitor in component_parts)?"✓":"X"
			if(2)
				output = "Micro-laser: "
				output += (/obj/item/stock_parts/micro_laser in component_parts)?"✓":"X"

			if(3)
				output = "Scanning module: "
				output += (/obj/item/stock_parts/scanning_module in component_parts)?"✓":"X"
			if(4)
				output = "Calibration: "
				output += drsite?"✓":"X"
		to_varlog("SUCCESS", output)
		sleep(rand(20,40))
	command_in_progress = FALSE

// MARK: —Anchor
/obj/machinery/heavy_mining_drill/proc/command_anchor() // сюда нужно запихнуть крепление боковых частей но если их нет то предупреждать
	command_in_progress = TRUE
	playsound(src,anchored?'sound/machines/airlocks/open_force.ogg':'sound/machines/airlocks/close_force.ogg',100)
	to_varlog("SILENT", anchored?"Lifting the fixing bolts":"Lowering the fixing bolts")
	dot_dot_dot()
	playsound(src,anchored?'sound/machines/airlocks/bolts_up.ogg':'sound/machines/airlocks/bolts_down.ogg',100)
	set_anchored(!anchored)
	to_varlog("SUCCESS", anchored?"Bolts lifted.":"Bolts lowered.")

	var/C
	for(var/obj/machinery/heavy_mining_drill_side/side_part in range(1))
		C++
		side_part.anchored?side_part.set_anchored(FALSE):side_part.set_anchored(TRUE)
		to_varlog("SILENT", "Side part#[C] is now "+side_part.anchored?"anchored":"unanchored.")

	to_varlog("SILENT", "Detected [C] additional machinery.")

	command_in_progress = FALSE

// MARK: —Start drilling
// Копание происходит в 2 этапа: Поверхностная порода копается, потом уже сама руда. Прогресс копания сохраняется в drilling_site
/obj/machinery/heavy_mining_drill/proc/command_start_drilling()
	if(!locate(/obj/item/stock_parts/micro_laser) in component_parts)
		to_varlog("ERROR","ERROR#24: Micro-laser is broken or not present in the system.")
	if(!locate(/obj/item/stock_parts/scanning_module) in component_parts)
		to_varlog("ERROR","ERROR#25: Scanning module is broken or not present in the system.")
	if(!drsite)
		to_varlog("SILENT", "no drsite")
		return FALSE

	// звуки лазерного бурения
	var/mining_time = 20 * drsite.rock_density
	drilling_timer = addtimer(CALLBACK(src, PROC_REF(process_drilling)), mining_time, TIMER_STOPPABLE|TIMER_LOOP)
	to_varlog("SUCCESS", "Mining started")

// ========= Terminal helpers ========= Simulating computer thinking

/obj/machinery/heavy_mining_drill/proc/dot_spam(amount, minwait, maxwait)
	var/dot
	for(var/C in 1 to amount)
		dot += "."
		to_varlog(dot)
		sleep(rand(minwait,maxwait))

/obj/machinery/heavy_mining_drill/proc/hex_spam(amount)
	for(var/C in 1 to amount)
		var/CC_output
		for(var/CC in 1 to 8)
			CC_output += num2hex(rand(0,255)) + " "
		var/output = "0x[C] - [CC_output]"
		to_varlog("SILENT", output)
		sleep(10)

/obj/machinery/heavy_mining_drill/proc/dot_dot_dot()
	var/last_log = message_log.len
	for(var/C in 1 to 3)
		message_log[last_log] += "."
		sleep(5)

// ================= DRILLING =================
// MARK: DRILLING

/obj/machinery/heavy_mining_drill/proc/process_drilling()
	if(!drsite)
		return FALSE // how?

	var/obj/item/stock_parts/micro_laser/ML = locate(/obj/item/stock_parts/micro_laser) in component_parts
	if((drsite.surface_drilling_progress[1] < drsite.surface_drilling_progress[2])) // surface drilling
		drsite.surface_drilling_progress[1] += 5 * ML.rating
		return

	if((drsite.deep_drilling_progress[1] < drsite.deep_drilling_progress[2])) // deep drilling
		drsite.deep_drilling_progress[1] += 5 * ML.rating

		drsite.progress_until_ore[1] += 5 * ML.rating
		if(drsite.progress_until_ore[1] > drsite.progress_until_ore[2])
			var/ore_to_spawn = pick(drsite.possible_ores)
			new ore_to_spawn(get_turf(src))

		return

// ========= Manual Operating =========
// MARK: OPERATING

//Instead of being qdeled the drill requires mildly expensive repairs to use again
/obj/machinery/heavy_mining_drill/deconstruct(disassembled)
	if(is_active && drsite)
		say("Drill integrity failure. Engaging emergency shutdown procedure.")
		//Just to make sure mobs don't spawn infinitely from the vein and as a failure state for players
		drsite.deconstruct()
	obj_break()
	update_icon_state()
	update_overlays()

/obj/machinery/heavy_mining_drill/get_cell()
	return cell

//The RPED sort of trivializes a good deal of the malfunction mechancis, as such it will not be allowed to work
/obj/machinery/heavy_mining_drill/exchange_parts(mob/user, obj/item/storage/part_replacer/W)
	to_chat(user, "<span class='notice'>[W] does not seem to work on [src], it might require more delicate part manipulation.")
	return

// MARK: ATTACKBY
/obj/machinery/heavy_mining_drill/attackby(obj/item/tool, mob/living/user, params)
	switch(tool.type)
		if(/obj/item/stack/sheet/plasteel)
			var/obj/item/stack/sheet/plasteel/plating = tool
			if(metal_attached == METAL_ABSENT && plating_integrity <= 1500)
				if(plating.use(10,FALSE,TRUE))
					metal_attached = METAL_PLACED
					to_chat(user, span_notice("You place plasteel on the drill."))
					return
				else
					to_chat(user, span_notice("You don't have enough plasteel to fix the plating."))
					return
			else
				to_chat(user, span_notice(span_notice("Plating already placed and waiting to be <bold>welded</bold>.")))
		if(/obj/item/stock_parts/cell)
			var/obj/item/stock_parts/cell/battery = tool
			if(cell)
				to_chat(user, span_warning("[src] already has a cell!"))
				return
			if(!user.transferItemToLoc(tool, src))
				return
			to_chat(user, span_notice("You install a cell in [src]."))
			return


	switch(tool.tool_behaviour)
		if(TOOL_WELDER)
			if(metal_attached == METAL_PLACED)
				if(tool.use_tool(src, user, 30, volume=50))
					to_chat(user, "<span class='notice'>You weld the new plating onto the [src], successfully repairing it.")
					metal_attached = METAL_ABSENT
					plating_integrity += 500
					update_icon_state()
					return
			else
				.=..()
		if(TOOL_CROWBAR)
// MARK:!!! в радиал замену частей
			cell.update_appearance()
			try_put_in_hand(cell, user)
			to_chat(user, span_notice("You disconnect [cell] from [src]."))
			cell = null
			is_active = FALSE
			update_appearance()
			return
		if(TOOL_SCREWDRIVER)
			if(!maintenance)
				tool.use_tool(src, user, 0, volume=50)
				to_chat(user, span_notice("You unscrew the maintenance panel."))
				if(do_after(user, 15, src))
					maintenance = TRUE
			else
				tool.use_tool(src, user, 0, volume=50)
				to_chat(user, span_notice("You screw the maintenance panel."))
				if(do_after(user, 15, src))
					maintenance = FALSE

	if(default_deconstruction_screwdriver(user,icon_state,icon_state,tool))
		return TRUE
	if(panel_open) //All malfunction repair and maintenance actions are handled under
		var/list/needed_parts = list(/obj/item/stock_parts/scanning_module,/obj/item/stock_parts/micro_laser,/obj/item/stock_parts/capacitor)
		if(is_type_in_list(tool,needed_parts))
			for(var/obj/item/stock_parts/part in component_parts)
				var/obj/item/stock_parts/new_part = tool
				if(new_part.part_behaviour == part.part_behaviour)
					user.transferItemToLoc(tool,src)
					try_put_in_hand(part, user)
					component_parts += new_part
					component_parts -= part
					to_chat(user, span_notice("You replace [part] with [new_part]."))
					break
				else if(istype(new_part,missing_part))
					user.transferItemToLoc(tool,src)
					component_parts += new_part
					missing_part = null
					obj_integrity = max_integrity
					to_chat(user, span_notice("You replace the broken part with [new_part]."))
					break
			return
	return ..()

/obj/machinery/heavy_mining_drill/AltClick(mob/user)
	if(is_active)
		to_chat(user, span_notice("You begin the manual shutoff process."))
		if(is_active)
			if(do_after(user, 10, src))
				is_active = FALSE
				soundloop.stop()
				deltimer(drilling_timer)
				playsound(src, 'sound/machines/switch2.ogg', 50, TRUE)
				say("Manual shutoff engaged, ceasing mining operations.")
				update_icon_state()
				update_overlays()
		else
			to_chat(user, span_notice("You cancel the manual shutoff process."))

/obj/machinery/heavy_mining_drill/update_icon_state()
	if(anchored)
		if(machine_stat & BROKEN)
			icon_state = "deep_core_drill-deployed_broken"
			return ..()
		if(is_active)
			icon_state = "deep_core_drill-is_active"
			return ..()
		else
			icon_state = "deep_core_drill-idle"
			return ..()
	else
		if(machine_stat & BROKEN)
			icon_state = "deep_core_drill-broken"
			return ..()
		icon_state = "deep_core_drill"
		return ..()

/obj/machinery/heavy_mining_drill/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	//Cool beam of light ignores shadows.
	if(is_active && anchored)
		set_light(3, 1, "99FFFF")
		SSvis_overlays.add_vis_overlay(src, icon, "mining_beam-particles", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "mining_beam-particles", layer, EMISSIVE_PLANE, dir)
	else
		set_light(0)


/*Handles all checks before starting the 30 second (on average) mining tick
// MARK:!!!
/obj/machinery/heavy_mining_drill/proc/start_mining()
	var/eta
	var/power_use
	for(var/obj/item/stock_parts/capacitor/capacitor in component_parts)
		power_use = power_cost/capacitor.rating
	if(cell.charge < power_use)
		say("Error: Internal cell charge depleted")
		is_active = FALSE
		soundloop.stop()
		update_overlays()
		return
	if(obj_integrity <= max_integrity/1.5)
		malfunction = rand(1,5)
		malfunction(malfunction)
		is_active = FALSE
		update_icon_state()
		update_overlays()
		return
	if(drsite.mining_charges >= 1)
		var/mine_time
		is_active = TRUE
		soundloop.start()
		if(!drsite.spawner_attached)
			drsite.begin_spawning()
		else if(!drsite.currently_spawning)
			drsite.toggle_spawning()
		for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
			mine_time = round((300/sqrt(laser.rating))*drsite.mine_time_multiplier)
		eta = mine_time*drsite.mining_charges
		cell.use(power_use)
		drilling_timer = addtimer(CALLBACK(src, PROC_REF(mine)), mine_time, TIMER_STOPPABLE)
		say("Estimated time until vein depletion: [time2text(eta,"mm:ss")].")
		update_icon_state()
		update_overlays()


//Called when it's time for the drill to rip that sweet ore from the earth
/obj/machinery/heavy_mining_drill/proc/mine_success()
	var/sensor_rating
	for(var/obj/item/stock_parts/scanning_module/sensor in component_parts)
		sensor_rating = round(sqrt(sensor.rating))
	drsite.drop_ore(sensor_rating, src)
*/

//Overly long proc to handle the unique properties for each malfunction type
// MARK:!!!
/obj/machinery/heavy_mining_drill/proc/malfunction(malfunction_type)
	if(is_active)
		drsite.toggle_spawning() //turns mob spawning off after a malfunction
	switch(malfunction_type)
		if(MALF_LASER)
			to_varlog("ERROR","Malfunction: Laser array damaged, please replace before continuing mining operations.")
			for (var/obj/item/stock_parts/micro_laser/laser in component_parts)
				component_parts.Remove(laser)
		if(MALF_SENSOR)
			to_varlog("ERROR","Malfunction: Ground penetrating scanner damaged, please replace before continuing mining operations.")
			for (var/obj/item/stock_parts/scanning_module/sensor in component_parts)
				component_parts.Remove(sensor)
		if(MALF_CAPACITOR)
			to_varlog("ERROR","Malfunction: Energy cell capacitor damaged, please replace before continuing mining operations.")
			for (var/obj/item/stock_parts/capacitor/capacitor in component_parts)
				component_parts.Remove(capacitor)
		if(MALF_STRUCTURAL)
			to_varlog("ERROR","Malfunction: Drill plating damaged, provide structural repairs before continuing mining operations.")
		if(MALF_CALIBRATE)
			to_varlog("ERROR","Malfunction: Drill laser calibrations out of alignment, please recalibrate before continuing.")

/obj/item/paper/guides/drill
	name = "Laser Mining Drill Operation Manual"
	default_raw_text = "<center><b>Laser Mining Drill Operation Manual</b></center><br><br><center>Thank you for opting in to the paid testing of Nanotrasen's new, experimental laser drilling device (trademark pending). We are legally obligated to mention that despite this new and wonderful drilling device being less dangerous than past iterations (note the 75% decrease in plasma ignition incidents), the seismic activity created by the drill has been noted to anger most forms of xenofauna. As such our legal team advises only armed mining expeditions make use of this drill.<br><br><c><b>How to set up your Laser Mining Drill</b></center><br><br>1. Find a suitable ore vein with the included scanner.<br>2. Wrench the drill's anchors in place over the vein.<br>3. Protect the drill from any enraged xenofauna until it has finished drilling.<br><br><center>With all this done, your ore should be well on its way out of the ground and into your pockets! Be warned though, the Laser Mining Drill is prone to numerous malfunctions when exposed to most forms of physical trauma. As such, we advise any teams utilizing this drill to bring with them a set of replacement Nanotrasen brand stock parts and a set of tools to handle repairs. If the drill suffers a total structural failure, then plasteel alloy may be needed to repair said structure.</center>"
