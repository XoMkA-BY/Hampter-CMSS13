/obj/item/weapon/twohanded/breacher_hammer
	name = "N45 battle hammer"
	desc = "RIP AND TEAR."
	icon = 'core_ru/icons/obj/items/weapons/weapons.dmi'
	icon_state = "breacher_hammer"
	item_state = "breacher_hammer"
	item_icons = list(
		WEAR_J_STORE = 'core_ru/icons/mob/humans/onmob/suit_slot.dmi',
		WEAR_WAIST = 'core_ru/icons/mob/humans/onmob/belt.dmi',
		WEAR_L_HAND = 'core_ru/icons/mob/humans/onmob/items_lefthand_0.dmi',
		WEAR_R_HAND = 'core_ru/icons/mob/humans/onmob/items_righthand_0.dmi'
	)
	pickup_sound = "gunequip"
	hitsound = "core_ru/sound/weapons/hammer_swing.ogg"
	force = MELEE_FORCE_STRONG
	flags_item = TWOHANDED
	force_wielded = MELEE_FORCE_TIER_8
	throwforce = MELEE_FORCE_NORMAL
	w_class = SIZE_LARGE
	sharp = IS_SHARP_ITEM_BIG
	flags_equip_slot = SLOT_SUIT_STORE|SLOT_WAIST
	unacidable = TRUE
	explo_proof = TRUE

	throw_range = 3
	attack_speed = 12

	var/speed_penalty = 0.85 // 15%
	var/retrieval_slot = WEAR_J_STORE

/obj/item/weapon/twohanded/breacher_hammer/attack(mob/target, mob/user)
	if(!skillcheck(user, SKILL_SPEC_WEAPONS, SKILL_SPEC_ALL) && user.skills.get_skill_level(SKILL_SPEC_WEAPONS) != SKILL_SPEC_BREACHER)
		to_chat(user, SPAN_HIGHDANGER("[src] is too heavy for you to use!"))
		return

	. = ..()

	if(!isxeno(target))
		return

	if(flags_item & WIELDED)
		var/datum/effects/hammer_stacks/hammer_effect = locate() in target.effects_list
		if(!hammer_effect)
			hammer_effect = new /datum/effects/hammer_stacks(target)

		hammer_effect.increment_stack_count(1, user)
		if(target.stat != CONSCIOUS) // haha xeno-cricket
			hammer_effect.increment_stack_count(4, user)

/obj/item/weapon/twohanded/breacher_hammer/pickup(mob/user)
	RegisterSignal(user, COMSIG_HUMAN_POST_MOVE_DELAY, PROC_REF(handle_movedelay))
	. = ..()

/obj/item/weapon/twohanded/breacher_hammer/proc/handle_movedelay(mob/user, list/movedata)
	SIGNAL_HANDLER
	movedata["move_delay"] += speed_penalty

/obj/item/weapon/twohanded/breacher_hammer/dropped(mob/user, silent)
	. = ..()

	UnregisterSignal(user, COMSIG_HUMAN_POST_MOVE_DELAY)
	if(!ishuman(user))
		return

	if(!retrieval_check(user, retrieval_slot))
		return

	addtimer(CALLBACK(src, PROC_REF(retrieve_to_slot), user, retrieval_slot), 0.3 SECONDS, TIMER_UNIQUE|TIMER_NO_HASH_WAIT)

/obj/item/weapon/twohanded/breacher_hammer/retrieve_to_slot(mob/living/carbon/human/user, retrieval_slot)
	if(!isturf(loc) || !user)
		return FALSE

	if(!retrieval_check(user, retrieval_slot))
		return FALSE

	if(!user.equip_to_slot_if_possible(src, retrieval_slot, disable_warning = TRUE))
		return FALSE

	var/message
	switch(retrieval_slot)
		if(WEAR_J_STORE)
			message = "[src] snaps into place on [user.wear_suit]."
	to_chat(user, SPAN_NOTICE(message))
	return TRUE

/obj/item/weapon/shield/montage
	name = "N30 montage shield"
	desc = "A shield adept at blocking blunt objects from connecting with the torso of the shield wielder."
	icon = 'core_ru/icons/obj/items/breacher_spec.dmi'
	icon_state = "metal_st"
	item_icons = list(
		WEAR_L_HAND = 'core_ru/icons/mob/humans/onmob/items_lefthand_1.dmi',
		WEAR_R_HAND = 'core_ru/icons/mob/humans/onmob/items_righthand_1.dmi',
		WEAR_BACK = 'core_ru/icons/mob/humans/onmob/back.dmi'
		)
	attack_verb = list("shoved", "bashed")
	pickup_sound = "gunequip"
	passive_block = 70
	readied_block = 100
	throw_range = 4
	flags_equip_slot = SLOT_BACK
	force = MELEE_FORCE_TIER_1
	throwforce = MELEE_FORCE_TIER_1
	w_class = SIZE_LARGE
	unacidable = TRUE
	explo_proof = TRUE
	var/blocks_on_back = TRUE
	var/retrieval_slot = WEAR_BACK
	var/cooldown = 0	//shield bash cooldown. based on world.time

/obj/item/weapon/shield/montage/IsShield()
	return TRUE

/obj/item/weapon/shield/montage/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon))
		if(cooldown < world.time - 25)
			user.visible_message("<span class='warning'>[user] bashes [src] with [W]!</span>")
			playsound(user.loc, 'core_ru/sound/effects/bang-bang.ogg', 25, FALSE)
			cooldown = world.time
		return

	. = ..()

/obj/item/weapon/shield/montage/dropped(mob/living/carbon/human/user, silent)
	. = ..()

	if(!istype(user))
		return

	if(!user.back && istype(user.wear_suit, /obj/item/clothing/suit/storage/marine/m40))
		addtimer(CALLBACK(src, PROC_REF(retrieve_to_slot), user, retrieval_slot), 0.3 SECONDS, TIMER_UNIQUE|TIMER_NO_HASH_WAIT)

/obj/item/weapon/shield/montage/retrieve_to_slot(mob/living/carbon/human/user, retrieval_slot)
	if(!loc || !user)
		return FALSE

	if(get_dist(src, user) > 1)
		return FALSE

	. = ..()


/obj/item/weapon/shield/montage/marine
	name = "N30-2 standard defensive shield"
	desc = "A heavy shield adept at blocking blunt or sharp objects from connecting with the shield wielder."
	icon_state = "marine_shield"
	passive_block = 45
	readied_block = 80
