/datum/surgery/vocal_cords
	name = "Операция на голосовых связках"
	possible_locs = list(BODY_ZONE_PRECISE_MOUTH)
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/tune_vocal_cords,
		/datum/surgery_step/close,
	)

/datum/surgery_step/tune_vocal_cords
	name = "настройка голосовых связок (гемостат)"
	implements = list(
		TOOL_HEMOSTAT = 100,
		TOOL_WIRECUTTER = 50,
		/obj/item/kitchen/fork = 35
	)
	preop_sound = 'sound/items/handling/surgery/hemostat1.ogg'
	time = 6.4 SECONDS

/datum/surgery_step/tune_vocal_cords/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(
		user,
		target,
		span_notice("Вы начинаете настраивать голосовые связки [target.declent_ru(GENITIVE)]..."),
		span_notice("[capitalize(user.declent_ru(NOMINATIVE))] начинает настраивать голосовые связки [target.declent_ru(GENITIVE)]."),
		span_notice("[capitalize(user.declent_ru(NOMINATIVE))] начинает выполнять операцию на голосовых связках [target.declent_ru(GENITIVE)].")
	)

/datum/surgery_step/tune_vocal_cords/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	display_results(
		user,
		target,
		span_notice("Вам удалось настроить голосовые связки [target.declent_ru(GENITIVE)]."),
		span_notice("[capitalize(user.declent_ru(NOMINATIVE))] успешно настраивает голосовые связки [target.declent_ru(GENITIVE)]!"),
		span_notice("[capitalize(user.declent_ru(NOMINATIVE))] завершает операцию на голосовых связках [target.declent_ru(GENITIVE)]."),
	)
	target.change_tts_seed(user, TTS_OVERRIDE_GENDER)
	return ..()

/datum/surgery_step/tune_vocal_cords/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(
		user,
		target,
		span_warning("Вы случайно вонзаете [tool.declent_ru(ACCUSATIVE)] в горло [target.declent_ru(GENITIVE)]!"),
		span_warning("[capitalize(user.declent_ru(NOMINATIVE))] случайно вонзает [tool.declent_ru(ACCUSATIVE)] в горло [target.declent_ru(GENITIVE)]!"),
		span_warning("[capitalize(user.declent_ru(NOMINATIVE))] случайно вонзает [tool.declent_ru(ACCUSATIVE)] в горло [target.declent_ru(GENITIVE)]!"),
	)
	display_pain(target, "Вы чувствуете острую колющую боль в горле!")
	target.apply_damage(20, BRUTE, BODY_ZONE_HEAD, sharpness=TRUE)
	return FALSE
