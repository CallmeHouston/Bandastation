/obj/item/clothing/mask/breath
	desc = "A close-fitting mask that can be connected to an air supply."
	name = "breath mask"
	icon_state = "breath"
	inhand_icon_state = "m_mask"
	body_parts_covered = 0
	clothing_flags = MASKINTERNALS
	visor_flags = MASKINTERNALS
	w_class = WEIGHT_CLASS_SMALL
	armor_type = /datum/armor/mask_breath
	actions_types = list(/datum/action/item_action/adjust)
	flags_cover = MASKCOVERSMOUTH
	visor_flags_cover = MASKCOVERSMOUTH
	resistance_flags = NONE
	interaction_flags_click = NEED_DEXTERITY|ALLOW_RESTING

/datum/armor/mask_breath
	bio = 50

/obj/item/clothing/mask/breath/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is wrapping \the [src]'s tube around [user.p_their()] neck! Кажется, [user.ru_p_they()] пытается совершить самоубийство!"))
	return OXYLOSS

/obj/item/clothing/mask/breath/attack_self(mob/user)
	adjust_visor(user)

/obj/item/clothing/mask/breath/click_alt(mob/user)
	adjust_visor(user)
	return CLICK_ACTION_SUCCESS

/obj/item/clothing/mask/breath/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click [src] to adjust it.")

/obj/item/clothing/mask/breath/medical
	desc = "A close-fitting sterile mask that can be connected to an air supply."
	name = "medical mask"
	icon_state = "medical"
	inhand_icon_state = "m_mask"
	armor_type = /datum/armor/breath_medical
	equip_delay_other = 10

/datum/armor/breath_medical
	bio = 90
