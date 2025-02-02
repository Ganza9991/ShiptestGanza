///Fish feed can
/obj/item/fish_feed
	name = "fish feed can"
	desc = "Autogenerates nutritious fish feed based on sample inside."
	icon = 'icons/obj/aquarium.dmi'
	icon_state = "fish_feed"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/fish_feed/Initialize(mapload)
	. = ..()
	create_reagents(5, OPENCONTAINER)
	reagents.add_reagent(/datum/reagent/consumable/nutriment, 1) //Default fish diet

///Stasis fish case container for moving fish between aquariums safely.
/obj/item/storage/fish_case
	name = "stasis fish case"
	desc = "A small case keeping the fish inside in stasis."
	icon_state = "fishbox"

	item_state = "syringe_kit"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

	component_type = /datum/component/storage/concrete/fish_case

/obj/item/storage/fish_case/Initialize(mapload)
	ADD_TRAIT(src, TRAIT_FISH_SAFE_STORAGE, TRAIT_GENERIC) // Before populate so fish instatiates in ready container already
	. = ..()

/obj/item/aquarium_kit
	name = "DIY Aquarium Construction Kit"
	desc = "Everything you need to build your own aquarium. Raw materials sold separately."
	icon = 'icons/obj/aquarium.dmi'
	icon_state = "construction_kit"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/aquarium_kit/attack_self(mob/user)
	. = ..()
	to_chat(user,span_notice("There's instruction and tools necessary to build aquarium inside. All you need is to start crafting."))

/obj/item/aquarium_prop
	name = "generic aquarium prop"
	desc = "very boring"
	icon = 'icons/obj/aquarium.dmi'

	w_class = WEIGHT_CLASS_TINY
	var/layer_mode = AQUARIUM_LAYER_MODE_BOTTOM

/obj/item/aquarium_prop/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/aquarium_content)

/obj/item/aquarium_prop/rocks
	name = "rocks"
	icon_state = "rocks"

/obj/item/aquarium_prop/seaweed_top
	name = "dense seaweeds"
	icon_state = "seaweeds_front"
	layer_mode = AQUARIUM_LAYER_MODE_TOP

/obj/item/aquarium_prop/seaweed
	name = "seaweeds"
	icon_state = "seaweeds_back"
	layer_mode = AQUARIUM_LAYER_MODE_BOTTOM

/obj/item/aquarium_prop/rockfloor
	name = "rock floor"
	icon_state = "rockfloor"
	layer_mode = AQUARIUM_LAYER_MODE_BOTTOM

/obj/item/aquarium_prop/treasure
	name = "tiny treasure chest"
	icon_state = "treasure"
	layer_mode = AQUARIUM_LAYER_MODE_BOTTOM

/obj/item/storage/box/aquarium_props
	name = "aquarium props box"
	desc = "All you need to make your aquarium look good."

/obj/item/storage/box/aquarium_props/PopulateContents()
	for(var/prop_type in subtypesof(/obj/item/aquarium_prop))
		new prop_type(src)
