///How many units of a reagent is needed to make a cone.
#define CONE_REAGENT_NEEDED 1

///The vat is set to dispense ice cream.
#define VAT_MODE_ICECREAM "мороженное"
///The vat is set to dispense cones.
#define VAT_MODE_CONES "рожок"

/obj/machinery/icecream_vat
	name = "ice cream vat"
	desc = "Смотря на машину, вы вспоминаете мелодию вашего любимого кафе с мороженным. Теперь таким кафе стало Нанотрейзен!"
	icon = 'icons/obj/service/kitchen.dmi'
	icon_state = "icecream_vat"
	density = TRUE
	anchored = FALSE
	use_power = NO_POWER_USE
	layer = BELOW_OBJ_LAYER
	max_integrity = 300

	///Which mode the icecream vat is set to dispense, VAT_MODE_ICECREAM or VAT_MODE_CONES
	var/vat_mode = VAT_MODE_ICECREAM
	///Boolean on whether or not to add 'icecream_vat_reagents' into the icecream vat on Initialize.
	var/preinstall_reagents = TRUE
	///The selected flavor of ice cream that we'll dispense when hit with an ice cream cone.
	var/selected_flavour = ICE_CREAM_VANILLA
	///The beaker inside of the vat used to make custom ice cream.
	var/obj/item/reagent_containers/custom_ice_cream_beaker
	///List of ice creams as icons used for the radial menu.
	var/static/list/ice_cream_icons
	/// List of prototypes of dispensable ice cream cones. path as key, instance as assoc.
	var/static/list/obj/item/food/icecream/cone_prototypes
	///List of all reagenets the icecream vat will spawn with, if preinstall_reagents is TRUE.
	var/static/list/icecream_vat_reagents = list(
		/datum/reagent/consumable/milk = 6,
		/datum/reagent/consumable/korta_milk = 6,
		/datum/reagent/consumable/flour = 6,
		/datum/reagent/consumable/korta_flour = 6,
		/datum/reagent/consumable/sugar = 6,
		/datum/reagent/consumable/ice = 6,
		/datum/reagent/consumable/coco = 6,
		/datum/reagent/consumable/vanilla = 6,
		/datum/reagent/consumable/berryjuice = 6,
		/datum/reagent/consumable/ethanol/singulo = 6,
		/datum/reagent/consumable/lemonjuice = 6,
		/datum/reagent/consumable/caramel = 6,
		/datum/reagent/consumable/banana = 6,
		/datum/reagent/consumable/orangejuice = 6,
		/datum/reagent/consumable/cream = 6,
		/datum/reagent/consumable/peachjuice = 6,
		/datum/reagent/consumable/cherryjelly = 6,
	)

/obj/machinery/icecream_vat/no_preinstalled_reagents
	preinstall_reagents = FALSE

/obj/machinery/icecream_vat/Initialize(mapload)
	. = ..()

	if(!cone_prototypes)
		cone_prototypes = list()
		for(var/cone_path in typesof(/obj/item/food/icecream))
			var/obj/item/food/icecream/cone = new cone_path
			if(cone.ingredients)
				cone_prototypes[cone_path] = cone
			else
				stack_trace("Ice cream cone [cone] (TYPE: [cone_path]) has been found without ingredients, please make a bug report about this.")
				qdel(cone)
	if(!ice_cream_icons)
		ice_cream_icons = list()
		for(var/flavor in GLOB.ice_cream_flavours)
			var/datum/ice_cream_flavour/flavor_datum = GLOB.ice_cream_flavours[flavor]
			if(flavor_datum.hidden)
				continue
			ice_cream_icons[flavor] = make_ice_cream_color(flavor_datum)

	RegisterSignal(src, COMSIG_ATOM_REAGENT_EXAMINE, PROC_REF(allow_reagent_scan))

	var/ice_cream_day = check_holidays(ICE_CREAM_DAY) //ice cream vats are more "robust" on this holiday

	create_reagents(ice_cream_day ? 400 : 300, NO_REACT|TRANSPARENT)
	reagents.chem_temp = T0C //So ice doesn't melt
	register_context()

	if(preinstall_reagents)
		for(var/reagent in icecream_vat_reagents)
			reagents.add_reagent(reagent, icecream_vat_reagents[reagent] * (ice_cream_day ? 2.5 : 1), reagtemp = T0C)

/obj/machinery/icecream_vat/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == custom_ice_cream_beaker)
		custom_ice_cream_beaker = null

/obj/machinery/icecream_vat/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(held_item)
		if(is_reagent_container(held_item))
			context[SCREENTIP_CONTEXT_LMB] = "Вставить мензурку"
			context[SCREENTIP_CONTEXT_RMB] = "Передать реагенты мензурки"
		else if(istype(held_item, /obj/item/food/icecream))
			context[SCREENTIP_CONTEXT_LMB] = "Взять шарик [selected_flavour] мороженного"
		else if(istype(held_item, /obj/item/kitchen/spoon) || istype(held_item, /obj/item/kitchen/spoon/soup_ladle))
			context[SCREENTIP_CONTEXT_RMB] = "Разлить реагент"
		return CONTEXTUAL_SCREENTIP_SET

	switch(vat_mode)
		if(VAT_MODE_ICECREAM)
			context[SCREENTIP_CONTEXT_LMB] = "Выбрать вкус"
			context[SCREENTIP_CONTEXT_RMB] = "Переключить режим на рожки"
		if(VAT_MODE_CONES)
			context[SCREENTIP_CONTEXT_LMB] = "Сделать рожок"
			context[SCREENTIP_CONTEXT_RMB] = "Переключить режим на вкусы"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/icecream_vat/examine(mob/user)
	. = ..()
	. += "Вы можете использовать [EXAMINE_HINT("ложку")] или [EXAMINE_HINT("половник")] для разлива содержимого."

/obj/machinery/icecream_vat/attackby(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(.)
		return

	if(istype(weapon, /obj/item/kitchen/spoon) || istype(weapon, /obj/item/kitchen/spoon/soup_ladle))
		spill_reagents(user)
		return TRUE

	var/obj/item/reagent_containers/beaker = weapon
	if(!istype(beaker) || !beaker.reagents || (beaker.item_flags & ABSTRACT) || !beaker.is_open_container())
		return

	if(custom_ice_cream_beaker)
		if(user.transferItemToLoc(beaker, src))
			try_put_in_hand(custom_ice_cream_beaker, user)
			balloon_alert(user, "мензурки заменены")
			custom_ice_cream_beaker = beaker
		else
			balloon_alert(user, "уже имеется мензурка!")
		return
	if(!user.transferItemToLoc(beaker, src))
		return
	balloon_alert(user, "мензурка вставлена")
	custom_ice_cream_beaker = beaker

/obj/machinery/icecream_vat/attackby_secondary(obj/item/reagent_containers/beaker, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!istype(beaker) || !beaker.reagents || (beaker.item_flags & ABSTRACT) || !beaker.is_open_container())
		return SECONDARY_ATTACK_CONTINUE_CHAIN
	var/added_reagents = FALSE
	for(var/datum/reagent/beaker_reagents in beaker.reagents.reagent_list)
		if(beaker_reagents.type in icecream_vat_reagents)
			added_reagents = TRUE
			beaker.reagents.trans_to(src, beaker_reagents.volume, target_id = beaker_reagents.type)

	if(added_reagents)
		balloon_alert(user, "перезарядка реагентов")
		playsound(src, 'sound/items/drink.ogg', 25, TRUE)
	else
		balloon_alert(user, "нет реагентов для передачи!")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/icecream_vat/attack_hand_secondary(mob/user, list/modifiers)
	if(swap_modes(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/machinery/icecream_vat/attack_robot_secondary(mob/living/silicon/robot/user)
	if(swap_modes(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/machinery/icecream_vat/click_alt(mob/user)
	if(!custom_ice_cream_beaker)
		return CLICK_ACTION_BLOCKING
	balloon_alert(user, "мензурка убрана")
	try_put_in_hand(custom_ice_cream_beaker, user)
	return CLICK_ACTION_SUCCESS

/obj/machinery/icecream_vat/interact(mob/living/user)
	. = ..()
	if (.)
		return

	var/list/choices = list()

	switch(vat_mode)
		if(VAT_MODE_ICECREAM)
			for(var/flavor_key in ice_cream_icons)
				var/datum/ice_cream_flavour/flavor_datum = GLOB.ice_cream_flavours[flavor_key]
				var/datum/radial_menu_choice/option = new
				option.image = ice_cream_icons[flavor_key]
				option.info = span_boldnotice("[flavor_datum.ingredients_text]")
				choices[flavor_key] = option
		if(VAT_MODE_CONES)
			for(var/cone_key in cone_prototypes)
				var/obj/item/food/icecream/cone_item = cone_prototypes[cone_key]
				var/datum/radial_menu_choice/option = new
				option.image = cone_prototypes[cone_key]
				option.info = span_boldnotice("[cone_item.ingredients_text]")
				choices[cone_key] = option

	var/choice = show_radial_menu(
		user,
		src,
		choices,
		require_near = TRUE,
		tooltips = TRUE,
		autopick_single_option = FALSE,
	)

	if(!choice)
		return
	var/datum/ice_cream_flavour/flavor = GLOB.ice_cream_flavours[choice]
	if(flavor)
		selected_flavour = flavor.name
		balloon_alert(user, "делается [selected_flavour]")
	var/obj/item/food/icecream/cone = cone_prototypes[choice]
	if(cone)
		make_cone(user, choice, cone.ingredients)

///Lets the user select a reagent in the vat to spill out.
/obj/machinery/icecream_vat/proc/spill_reagents(mob/living/user)
	var/datum/reagent/reagent_to_remove = tgui_input_list(user, "Select a reagent to purge from the vat.", "Remove reagent", reagents.reagent_list, ui_state = GLOB.conscious_state)
	if(isnull(reagent_to_remove) || !user.can_perform_action(src, action_bitflags = ALLOW_RESTING))
		return
	balloon_alert(user, "[reagent_to_remove.name] разливается")
	reagents.remove_reagent(reagent_to_remove.type, reagent_to_remove.volume)

/obj/machinery/icecream_vat/proc/make_ice_cream_color(datum/ice_cream_flavour/flavor)
	if(!flavor.color)
		return
	var/image/ice_cream_icon = image('icons/obj/service/kitchen.dmi', "icecream_custom")
	ice_cream_icon.color = flavor.color
	return ice_cream_icon

/obj/machinery/icecream_vat/on_deconstruction(disassembled = TRUE)
	var/atom/drop_location = drop_location()

	new /obj/item/stack/sheet/iron(drop_location, 4)
	custom_ice_cream_beaker?.forceMove(drop_location)

///Makes an ice cream cone of the make_type, using ingredients list as reagents used to make it. Puts in user's hand if possible.
/obj/machinery/icecream_vat/proc/make_cone(mob/user, make_type, list/ingredients)
	for(var/reagents_needed in ingredients)
		if(!reagents.has_reagent(reagents_needed, CONE_REAGENT_NEEDED))
			balloon_alert(user, "не хватает ингредиентов!")
			return
	var/cone_type = cone_prototypes[make_type].type
	if(!cone_type)
		return
	var/obj/item/food/icecream/cone = new cone_type(src)

	for(var/reagents_used in ingredients)
		reagents.remove_reagent(reagents_used, CONE_REAGENT_NEEDED)
	balloon_alert_to_viewers("делается [cone.declent_ru(NOMINATIVE)]", "делается [cone.declent_ru(NOMINATIVE)]")
	try_put_in_hand(cone, user)

///Makes ice cream if it can, then puts it in the ice cream cone we're being attacked with.
/obj/machinery/icecream_vat/proc/add_flavor_to_cone(datum/component/ice_cream_holder/source, mob/user, obj/item/food/icecream/cone)
	var/datum/ice_cream_flavour/flavor = GLOB.ice_cream_flavours[selected_flavour]
	if(!flavor)
		CRASH("[user] was making ice cream of [selected_flavour] but had no flavor datum for it!")

	for(var/reagents_needed in flavor.ingredients)
		if(!reagents.has_reagent(reagents_needed, CONE_REAGENT_NEEDED))
			balloon_alert(user, "не хватает ингредиентов!")
			return

	var/should_use_custom_ingredients = (flavor.takes_custom_ingredients && custom_ice_cream_beaker && custom_ice_cream_beaker.reagents.total_volume)
	if(flavor.add_flavour(source, should_use_custom_ingredients ? custom_ice_cream_beaker.reagents : null))
		for(var/reagents_used in flavor.ingredients)
			reagents.remove_reagent(reagents_used, CONE_REAGENT_NEEDED)
		balloon_alert_to_viewers("набирает шарик с [selected_flavour]", "набирает шарик с [selected_flavour]")

	if(istype(cone))
		if(isnull(cone.crafted_food_buff))
			cone.crafted_food_buff = /datum/status_effect/food/chilling
		if(user.mind)
			ADD_TRAIT(cone, TRAIT_FOOD_CHEF_MADE, REF(user.mind))

///Swaps the mode to the next one meant to be selected, then tells the user who changed it.
/obj/machinery/icecream_vat/proc/swap_modes(mob/user)
	if(!user.can_perform_action(src))
		return FALSE
	switch(vat_mode)
		if(VAT_MODE_ICECREAM)
			vat_mode = VAT_MODE_CONES
		if(VAT_MODE_CONES)
			vat_mode = VAT_MODE_ICECREAM
	balloon_alert(user, "выдается [vat_mode]")
	return TRUE

///Allows any user to see what reagents are in the ice cream vat regardless of special gear.
/obj/machinery/icecream_vat/proc/allow_reagent_scan(datum/source, mob/user, list/examine_list, can_see_insides = FALSE)
	SIGNAL_HANDLER
	return ALLOW_GENERIC_REAGENT_EXAMINE

#undef VAT_MODE_ICECREAM
#undef VAT_MODE_CONES
#undef CONE_REAGENT_NEEDED
