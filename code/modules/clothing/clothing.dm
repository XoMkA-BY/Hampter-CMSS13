/obj/item/clothing
	name = "clothing"
	pickupvol = 40
	dropvol = 40
	var/eye_protection = EYE_PROTECTION_NONE //used for headgear, masks, and glasses, to see how much they protect eyes from bright lights.
	var/armor_melee = 0
	var/armor_bullet = 0
	var/armor_laser = 0
	var/armor_energy = 0
	var/armor_bomb = 0
	var/armor_bio = 0
	var/armor_rad = 0
	var/armor_internaldamage = 0
	var/movement_compensation = 0
	var/drag_unequip = FALSE
	var/blood_overlay_type = "" //which type of blood overlay to use on the mob when bloodied
	var/list/clothing_traits // Trait modification, lazylist of traits to add/take away, on equipment/drop in the correct slot
	var/clothing_traits_active = TRUE //are the clothing traits that are applied to the item active (acting on the mob) or not?

	// accessory stuff
	var/list/accessories
	var/list/valid_accessory_slots = list()
	/// Whether this item can be converted into an accessory when used
	var/can_become_accessory = FALSE
	/// default slot for accessories, pathed here for use for non-accessories
	var/worn_accessory_slot = ACCESSORY_SLOT_DEFAULT
	/// for pathing to different accessory subtypes with unique mechanics
	var/accessory_path = /obj/item/clothing/accessory
	/// default limit for attaching accessories, should only be 1 for most accessories, you don't want multiple storage accessories after all
	var/worn_accessory_limit = 1

/obj/item/clothing/proc/convert_to_accessory(mob/user)
	if(!can_become_accessory)
		to_chat(user, SPAN_NOTICE("[src] cannot be turned into an accessory."))
		return

	// copies the properties of the clothing item to the accessory, in the future, take literally almost every var from ties.dm parent object and place it in clothing parent
	var/obj/item/clothing/accessory/new_accessory = new accessory_path(loc)
	new_accessory.name = name
	new_accessory.icon = icon
	new_accessory.icon_state = icon_state
	new_accessory.desc = desc
	var/list/accessory_icons = item_icons ? item_icons.Copy() : list()
	if(accessory_icons[WEAR_FACE]) // this is really hacky, will probably need to change it in the future for dynamic implementations
		accessory_icons[WEAR_JACKET] = accessory_icons[WEAR_FACE]
		accessory_icons[WEAR_BODY] = accessory_icons[WEAR_FACE]
	new_accessory.accessory_icons = accessory_icons
	new_accessory.high_visibility = TRUE
	new_accessory.removable = TRUE
	new_accessory.worn_accessory_slot = worn_accessory_slot
	new_accessory.worn_accessory_limit = worn_accessory_limit
	new_accessory.can_become_accessory = can_become_accessory

	new_accessory.inv_overlay = image("icon" = accessory_icons[WEAR_FACE], "icon_state" = "[item_state? "[item_state]" : "[icon_state]"]") // will need a dynamic implementation in the future, or path directly to accessory\inventory_overlays to its own dmi file  - nihi

	new_accessory.original_item_path = src.type

	if(ismob(loc) && loc == user)
		user.put_in_hands(new_accessory)

	to_chat(user, SPAN_NOTICE("You will start wearing [src] as an accessory."))
	// we dont want duplicates man
	qdel(src)

/obj/item/clothing/proc/revert_from_accessory(mob/user)
	var/obj/item/clothing/accessory/access = src
	if(!access.original_item_path)
		to_chat(user, SPAN_NOTICE("[src] cannot be reverted because the original item path is missing."))
		return

	var/obj/item/clothing/original_item = new access.original_item_path(loc)
	if(!original_item)
		to_chat(user, SPAN_NOTICE("Failed to revert [src] to its original item."))
		return

	if(ismob(loc) && loc == user)
		user.put_in_hands(original_item)

	to_chat(user, SPAN_NOTICE("You will start wearing [src] as normal."))
	// ditto
	qdel(src)

/obj/item/clothing/attack_self(mob/user)
	if(can_become_accessory)
		convert_to_accessory(user)

/obj/item/clothing/get_examine_line(mob/user)
	. = ..()
	var/list/ties = list()
	for(var/obj/item/clothing/accessory/accessory in accessories)
		if(accessory.high_visibility)
			ties += "\a [accessory.get_examine_line(user)]"
	if(length(ties))
		.+= " with [english_list(ties)] attached"
	if(LAZYLEN(accessories) > length(ties))
		.+= ". <a href='byond://?src=\ref[src];list_acc=1'>\[See accessories\]</a>"

/obj/item/clothing/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["list_acc"])
		if(LAZYLEN(accessories))
			var/list/ties = list()
			for(var/accessory in accessories)
				ties += "[icon2html(accessory)] \a [accessory]"
			to_chat(usr, "Attached to \the [src] are [english_list(ties)].")
		return

/obj/item/clothing/attack_hand(mob/user as mob)
	//only forward to the attached accessory if the clothing is equipped (not in a storage)
	if(LAZYLEN(accessories) && loc == user)
		var/delegated //So that accessories don't block attack_hands unless they actually did something. Specifically meant for armor vests with medals, but can't hurt in general.
		for(var/obj/item/clothing/accessory/A in accessories)
			if(A.attack_hand(user))
				delegated = TRUE
		if(delegated)
			return

	if(drag_unequip && ishuman(usr) && loc == user) //make it harder to accidentally undress yourself
		return

	..()

/obj/item/clothing/hear_talk(mob/living/sourcemob, message, verb, datum/language/language, italics, tts_heard_list)
	for(var/obj/item/clothing/accessory/attached in accessories)
		attached.hear_talk(sourcemob, message, tts_heard_list = tts_heard_list)
	..()

/obj/item/clothing/proc/get_armor(armortype)
	var/armor_total = 0
	var/armor_count = 0
	if(!isnum(armortype))
		log_debug("Armortype parsed as non-number! ([armortype], mob: [src.loc]) @ clothing.dm line 56.")
		return 0
	if(armortype & ARMOR_MELEE)
		armor_total += armor_melee
		armor_count++
	if(armortype & ARMOR_BULLET)
		armor_total += armor_bullet
		armor_count++
	if(armortype & ARMOR_LASER)
		armor_total += armor_laser
		armor_count++
	if(armortype & ARMOR_ENERGY)
		armor_total += armor_energy
		armor_count++
	if(armortype & ARMOR_BOMB)
		armor_total += armor_bomb
		armor_count++
	if(armortype & ARMOR_BIO)
		armor_total += armor_bio
		armor_count++
	if(armortype & ARMOR_RAD)
		armor_total += armor_rad
		armor_count++
	if(armortype & ARMOR_INTERNALDAMAGE)
		armor_total += armor_internaldamage
		armor_count++
	if(armor_count == 0)
		return 0
	return armor_total/armor_count

//Updates the icons of the mob wearing the clothing item, if any.
/obj/item/clothing/proc/update_clothing_icon()
	return

/obj/item/clothing/get_mob_overlay(mob/user_mob, slot, default_bodytype = "Default")
	var/image/ret = ..()

	if(slot == WEAR_L_HAND || slot == WEAR_R_HAND)
		return ret

	if(blood_color && blood_overlay_type)
		var/blood_icon = 'icons/effects/blood.dmi'
		if(ishuman(user_mob))
			var/mob/living/carbon/human/H = user_mob
			blood_icon = H.species.blood_mask
		var/image/bloodsies = overlay_image(blood_icon, "[blood_overlay_type]_blood", blood_color, RESET_COLOR|NO_CLIENT_COLOR)
		ret.overlays += bloodsies

	if(LAZYLEN(accessories))
		for(var/obj/item/clothing/accessory/A in accessories)
			ret.overlays |= A.get_mob_overlay(user_mob, slot)
	return ret

///////////////////////////////////////////////////////////////////////
// Ears: headsets, earmuffs and tiny objects
/obj/item/clothing/ears
	name = "ears"
	w_class = SIZE_TINY
	throwforce = 2
	flags_equip_slot = SLOT_EAR

/obj/item/clothing/ears/update_clothing_icon()
	if (ismob(src.loc))
		var/mob/M = src.loc
		M.update_inv_ears()

/obj/item/clothing/ears/earmuffs
	name = "earmuffs"
	desc = "Protects your hearing from loud noises, and quiet ones as well."
	icon_state = "earmuffs"
	item_state = "earmuffs"
	icon = 'icons/obj/items/radio.dmi'
	item_icons = list(
		WEAR_L_EAR = 'icons/mob/humans/onmob/clothing/ears.dmi',
		WEAR_R_EAR = 'icons/mob/humans/onmob/clothing/ears.dmi',
		WEAR_L_HAND = 'icons/mob/humans/onmob/inhands/clothing/hats_lefthand.dmi',
		WEAR_R_HAND = 'icons/mob/humans/onmob/inhands/clothing/hats_righthand.dmi',
	)
	flags_equip_slot = SLOT_EAR
	clothing_traits = list(TRAIT_EAR_PROTECTION)
	black_market_value = 20

/obj/item/clothing/ears/earmuffs/New()
	. = ..()

	LAZYADD(GLOB.objects_of_interest, src)

/obj/item/clothing/ears/earmuffs/Destroy()
	. = ..()

	LAZYREMOVE(GLOB.objects_of_interest, src)


///////////////////////////////////////////////////////////////////////
//Suit
/obj/item/clothing/suit
	name = "suit"
	icon = 'icons/obj/items/clothing/suits/misc_ert.dmi'
	var/fire_resist = T0C+100
	flags_armor_protection = BODY_FLAG_CHEST|BODY_FLAG_GROIN|BODY_FLAG_ARMS|BODY_FLAG_LEGS
	allowed = list(
		/obj/item/device/flashlight,
		/obj/item/device/healthanalyzer,
		/obj/item/device/radio,
		/obj/item/tank/emergency_oxygen,
		/obj/item/tool/crowbar,
		/obj/item/tool/pen,
	)
	armor_melee = 0
	armor_bullet = 0
	armor_laser = 0
	armor_energy = 0
	armor_bomb = 0
	armor_bio = 0
	armor_rad = 0
	flags_equip_slot = SLOT_OCLOTHING
	blood_overlay_type = "suit"
	siemens_coefficient = 0.9
	w_class = SIZE_MEDIUM
	sprite_sheets = list(SPECIES_MONKEY = 'icons/mob/humans/species/monkeys/onmob/suit_monkey_0.dmi')
	item_icons = list(
		WEAR_L_HAND = 'icons/mob/humans/onmob/inhands/clothing/suits_lefthand.dmi',
		WEAR_R_HAND = 'icons/mob/humans/onmob/inhands/clothing/suits_righthand.dmi'
	)
	valid_accessory_slots = list(ACCESSORY_SLOT_MEDAL, ACCESSORY_SLOT_RANK, ACCESSORY_SLOT_DECOR, ACCESSORY_SLOT_PONCHO, ACCESSORY_SLOT_MASK, ACCESSORY_SLOT_ARMBAND, ACCESSORY_SLOT_ARMOR_A, ACCESSORY_SLOT_ARMOR_L, ACCESSORY_SLOT_ARMOR_S, ACCESSORY_SLOT_ARMOR_M, ACCESSORY_SLOT_UTILITY, ACCESSORY_SLOT_PATCH)

/obj/item/clothing/suit/update_clothing_icon()
	if (ismob(src.loc))
		var/mob/M = src.loc
		M.update_inv_wear_suit()


/obj/item/clothing/suit/mob_can_equip(mob/M, slot, disable_warning = 0)
	//if we can't equip the item anyway, don't bother with other checks.
	if (!..())
		return 0

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/clothing/under/U = H.w_uniform
		//some uniforms prevent you from wearing any suits but certain types
		if(U && U.suit_restricted && !is_type_in_list(src, U.suit_restricted))
			to_chat(H, SPAN_WARNING("[src] can't be worn with [U]."))
			return 0
	return 1

/////////////////////////////////////////////////////////
//Gloves
/obj/item/clothing/gloves
	name = "gloves"
	gender = PLURAL //Carn: for grammarically correct text-parsing
	w_class = SIZE_SMALL
	icon = 'icons/obj/items/clothing/gloves.dmi'
	item_icons = list(
		WEAR_L_HAND = 'icons/mob/humans/onmob/inhands/clothing/gloves_lefthand.dmi',
		WEAR_R_HAND = 'icons/mob/humans/onmob/inhands/clothing/gloves_righthand.dmi',
	)
	siemens_coefficient = 0.50
	var/wired = 0
	var/obj/item/cell/cell = 0
	flags_armor_protection = BODY_FLAG_HANDS
	flags_equip_slot = SLOT_HANDS
	attack_verb = list("challenged")
	valid_accessory_slots = list(ACCESSORY_SLOT_WRIST_L, ACCESSORY_SLOT_WRIST_R)
	sprite_sheets = list(SPECIES_MONKEY = 'icons/mob/humans/species/monkeys/onmob/hands_monkey.dmi')
	blood_overlay_type = "hands"
	var/gloves_blood_amt = 0 //taken from blood.dm
	var/hide_prints = FALSE

/obj/item/clothing/gloves/update_clothing_icon()
	if (ismob(src.loc))
		var/mob/M = src.loc
		M.update_inv_gloves()

/obj/item/clothing/gloves/emp_act(severity)
	. = ..()
	if(cell)
		//why is this not part of the powercell code?
		cell.charge -= 1000 / severity
		if (cell.charge < 0)
			cell.charge = 0
		if(cell.reliability != 100 && prob(50/severity))
			cell.reliability -= 10 / severity

// Called just before an attack_hand(), in mob/UnarmedAttack()
/obj/item/clothing/gloves/proc/Touch(atom/A, proximity)
	return 0 // return 1 to cancel attack_hand()


//////////////////////////////////////////////////////////////////
//Mask
/obj/item/clothing/mask
	name = "mask"
	icon = 'icons/obj/items/clothing/masks/masks.dmi'
	flags_equip_slot = SLOT_FACE
	flags_armor_protection = BODY_FLAG_HEAD|BODY_FLAG_FACE|BODY_FLAG_EYES
	blood_overlay_type = "mask"
	item_icons = list(
		WEAR_L_HAND = 'icons/mob/humans/onmob/inhands/clothing/masks_lefthand.dmi',
		WEAR_R_HAND = 'icons/mob/humans/onmob/inhands/clothing/masks_righthand.dmi',
	)
	var/anti_hug = 0

/obj/item/clothing/mask/update_clothing_icon()
	if (ismob(src.loc))
		var/mob/M = src.loc
		M.update_inv_wear_mask()

/obj/item/clothing/mask/verb/toggle_internals()
	set category = "Object"
	set name = "Toggle Internals"
	set src in usr

	if(!(flags_inventory & ALLOWINTERNALS))
		to_chat(usr, SPAN_NOTICE("This mask doesnt support internals."))
		return

	if(!iscarbon(usr))
		return

	var/mob/living/carbon/C = usr
	if(C.is_mob_incapacitated())
		return

	if(C.internal)
		C.internal = null
		to_chat(C, SPAN_NOTICE("No longer running on internals."))
	else
		var/list/nicename = null
		var/list/tankcheck = null
		var/breathes = "oxygen" //default, we'll check later
		if(ishuman(C))
			var/mob/living/carbon/human/H = C
			breathes = H.species.breath_type
			nicename = list ("suit", "back", "belt", "right hand", "left hand", "left pocket", "right pocket")
			tankcheck = list (H.s_store, C.back, H.belt, C.r_hand, C.l_hand, H.l_store, H.r_store)
		else
			nicename = list("Right Hand", "Left Hand", "Back")
			tankcheck = list(C.r_hand, C.l_hand, C.back)
		var/best = 0
		var/bestpressure = 0
		for(var/i=1, i<length(tankcheck)+1, ++i)
			if(istype(tankcheck[i], /obj/item/tank))
				var/obj/item/tank/t = tankcheck[i]
				var/goodtank
				if(t.gas_type == GAS_TYPE_N2O) //anesthetic
					goodtank = TRUE
				else
					switch(breathes)
						if("nitrogen")
							if(t.gas_type == GAS_TYPE_NITROGEN)
								goodtank = TRUE
						if ("oxygen")
							if(t.gas_type == GAS_TYPE_OXYGEN || t.gas_type == GAS_TYPE_AIR)
								goodtank = TRUE
						if ("carbon dioxide")
							if(t.gas_type == GAS_TYPE_CO2)
								goodtank = TRUE
				if(goodtank)
					if(t.pressure >= 20 && t.pressure > bestpressure)
						best = i
						bestpressure = t.pressure
		//We've determined the best container now we set it as our internals
		if(best)
			to_chat(C, SPAN_NOTICE("You are now running on internals from [tankcheck[best]] on your [nicename[best]]."))
			C.internal = tankcheck[best]
		if(!C.internal)
			to_chat(C, SPAN_NOTICE("You don't have a[breathes=="oxygen" ? "n oxygen" : addtext(" ",breathes)] tank."))
	return TRUE


//some gas masks modify the air that you breathe in.
/obj/item/clothing/mask/proc/filter_air(list/air_info)
	if(flags_inventory & ALLOWREBREATH)
		air_info[2] = T20C //heats/cools air to be breathable

	return air_info



////////////////////////////////////////////////////////////////////////
//Shoes
/obj/item/clothing/shoes
	name = "shoes"
	icon = 'icons/obj/items/clothing/shoes.dmi'
	desc = "Comfortable-looking shoes."
	gender = PLURAL //Carn: for grammarically correct text-parsing
	siemens_coefficient = 0.9
	flags_armor_protection = BODY_FLAG_FEET
	flags_equip_slot = SLOT_FEET

	slowdown = SHOES_SLOWDOWN
	blood_overlay_type = "feet"
	item_icons = list(
		WEAR_L_HAND = 'icons/mob/humans/onmob/inhands/clothing/boots_lefthand.dmi',
		WEAR_R_HAND = 'icons/mob/humans/onmob/inhands/clothing/boots_righthand.dmi'
	)
	/// The currently inserted item.
	var/obj/item/stored_item
	/// List of item types that can be inserted.
	var/list/allowed_items_typecache
	/// An item which should be inserted when the shoes are spawned.
	var/obj/item/spawn_item_type
	var/shoes_blood_amt = 0

/obj/item/clothing/shoes/Initialize(mapload, ...)
	. = ..()
	if(allowed_items_typecache)
		allowed_items_typecache = typecacheof(allowed_items_typecache)
	if(spawn_item_type)
		_insert_item(new spawn_item_type(src))

/// Returns a boolean indicating if `item_to_insert` can be inserted into the shoes.
/obj/item/clothing/shoes/proc/can_be_inserted(obj/item/item_to_insert)
	// If the shoes can't actually hold an item.
	if(allowed_items_typecache == null)
		return FALSE
	// If there's already an item inside.
	if(stored_item)
		return FALSE
	// If `item_to_insert` isn't in the whitelist.
	if(!is_type_in_typecache(item_to_insert, allowed_items_typecache))
		return FALSE
	// If all of those passed, `item_to_insert` can be inserted.
	return TRUE

/**
 * Try to insert `item_to_insert` into the shoes.
 *
 * Returns `TRUE` if it succeeded, or `FALSE` if [/obj/item/clothing/shoes/proc/can_be_inserted] failed, or `user` couldn't drop the item.
 */
/obj/item/clothing/shoes/proc/attempt_insert_item(mob/user, obj/item/item_to_insert)
	if(!can_be_inserted(item_to_insert))
		return FALSE
	// Try to drop the item and place it inside `src`.
	if(!user.drop_inv_item_to_loc(item_to_insert, src))
		return FALSE
	_insert_item(item_to_insert)
	item_to_insert.last_equipped_slot = WEAR_IN_SHOES
	to_chat(user, SPAN_NOTICE("You slide [item_to_insert] into [src]."))
	playsound(user, 'sound/weapons/gun_shotgun_shell_insert.ogg', 15, TRUE)
	return TRUE

/// Insert `item_to_insert` directly into the shoes without bothering with any checks.
/// (In the majority of cases [/obj/item/clothing/shoes/proc/attempt_insert_item()] should be used instead of this.)
/obj/item/clothing/shoes/proc/_insert_item(obj/item/item_to_insert)
	PROTECTED_PROC(TRUE)
	stored_item = item_to_insert
	update_icon()

/// Remove `stored_item` from the shoes, and place it into the `user`'s active hand.
/obj/item/clothing/shoes/proc/remove_item(mob/user)
	if(!stored_item || !user.put_in_active_hand(stored_item))
		return
	to_chat(user, SPAN_NOTICE("You slide [stored_item] out of [src]."))
	playsound(user, 'sound/weapons/gun_shotgun_shell_insert.ogg', 15, TRUE)
	stored_item = null
	update_icon()

/obj/item/clothing/shoes/update_clothing_icon()
	if(ismob(loc))
		var/mob/user = loc
		user.update_inv_shoes()

/obj/item/clothing/shoes/Destroy()
	QDEL_NULL(stored_item)
	return ..()

/obj/item/clothing/shoes/get_examine_text(mob/user)
	. = ..()
	if(stored_item)
		. += "\nIt is storing \a [stored_item]."

/obj/item/clothing/shoes/attack_hand(mob/living/user)
	// Only allow someone to take out the `stored_item` if it's being worn or held, so that you can pick them up off the floor.
	if(!stored_item || loc != user || user.is_mob_incapacitated())
		return ..()
	remove_item(user)

/obj/item/clothing/shoes/attackby(obj/item/attacking_item, mob/living/user)
	. = ..()
	attempt_insert_item(user, attacking_item)

/obj/item/clothing/equipped(mob/user, slot, silent)
	if(is_valid_slot(slot, TRUE)) //is it going to a matching clothing slot?
		if(!silent && LAZYLEN(equip_sounds))
			playsound_client(user.client, pick(equip_sounds), null, ITEM_EQUIP_VOLUME)
		if(clothing_traits_active)
			for(var/trait in clothing_traits)
				ADD_TRAIT(user, trait, TRAIT_SOURCE_EQUIPMENT(slot))
	..()

/obj/item/clothing/unequipped(mob/user, slot)
	if(is_valid_slot(slot, TRUE))
		for(var/trait in clothing_traits)
			REMOVE_TRAIT(user, trait, TRAIT_SOURCE_EQUIPMENT(slot))
	. = ..()

/obj/item/clothing/proc/get_pockets()
	var/obj/item/clothing/accessory/storage/S = locate() in accessories
	if(S)
		return S.hold
	return null

/obj/item/clothing/clicked(mob/user, list/mods)
	if(mods[ALT_CLICK] && loc == user && !user.get_active_hand()) //To pass quick-draw attempts to storage. See storage.dm for explanation.
		for(var/V in verbs)
			if(V == /obj/item/clothing/suit/storage/verb/toggle_draw_mode) //So that alt-clicks are only intercepted for clothing items with internal storage and toggleable draw modes.
				return

	var/obj/item/storage/internal/pockets = get_pockets()
	if(pockets && !mods[SHIFT_CLICK] && mods[MIDDLE_CLICK] && CAN_PICKUP(user, src))
		pockets.open(user)
		return TRUE

	return ..()
