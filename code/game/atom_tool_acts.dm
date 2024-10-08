/**
 * ## Item interaction
 *
 * Handles non-combat iteractions of a tool on this atom,
 * such as using a tool on a wall to deconstruct it,
 * or scanning someone with a health analyzer
 */
/atom/proc/base_item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)

	var/is_right_clicking = LAZYACCESS(modifiers, RIGHT_CLICK)
	var/is_left_clicking = !is_right_clicking
	var/early_sig_return = NONE
	if(is_left_clicking)
		early_sig_return = SEND_SIGNAL(src, COMSIG_ATOM_ITEM_INTERACTION, user, tool, modifiers) \
			| SEND_SIGNAL(tool, COMSIG_ITEM_INTERACTING_WITH_ATOM, user, src, modifiers)
	else
		early_sig_return = SEND_SIGNAL(src, COMSIG_ATOM_ITEM_INTERACTION_SECONDARY, user, tool, modifiers) \
			| SEND_SIGNAL(tool, COMSIG_ITEM_INTERACTING_WITH_ATOM_SECONDARY, user, src, modifiers)
	if(early_sig_return)
		return early_sig_return

	var/self_interaction = is_left_clicking \
		? item_interaction(user, tool, modifiers) \
		: item_interaction_secondary(user, tool, modifiers)
	if(self_interaction)
		return self_interaction

	var/interact_return = is_left_clicking \
		? tool.interact_with_atom(src, user, modifiers) \
		: tool.interact_with_atom_secondary(src, user, modifiers)
	if(interact_return)
		return interact_return

	var/tool_type = tool.tool_behaviour
	if(!tool_type) // here on only deals with ... tools
		return NONE

	var/list/processing_recipes = list()
	var/signal_result = is_left_clicking \
		? SEND_SIGNAL(src, COMSIG_ATOM_TOOL_ACT(tool_type), user, tool, processing_recipes) \
		: SEND_SIGNAL(src, COMSIG_ATOM_SECONDARY_TOOL_ACT(tool_type), user, tool)
	if(signal_result)
		return signal_result
	if(length(processing_recipes))
		process_recipes(user, tool, processing_recipes)
	if(QDELETED(tool))
		return TOOL_ACT_TOOLTYPE_SUCCESS // Safe-ish to assume that if we deleted our item something succeeded

	var/act_result = NONE // or FALSE, or null, as some things may return



/**
 * Called when this atom has an item used on it.
 * IE, a mob is clicking on this atom with an item.
 *
 * Return an ITEM_INTERACT_ flag in the event the interaction was handled, to cancel further interaction code.
 * Return NONE to allow default interaction / tool handling.
 */
/atom/proc/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	return NONE

/**
 * Called when this atom has an item used on it WITH RIGHT CLICK,
 * IE, a mob is right clicking on this atom with an item.
 * Default behavior has it run the same code as left click.
 *
 * Return an ITEM_INTERACT_ flag in the event the interaction was handled, to cancel further interaction code.
 * Return NONE to allow default interaction / tool handling.
 */
/atom/proc/item_interaction_secondary(mob/living/user, obj/item/tool, list/modifiers)
	return item_interaction(user, tool, modifiers)

/**
 * Called when this item is being used to interact with an atom,
 * IE, a mob is clicking on an atom with this item.
 *
 * Return an ITEM_INTERACT_ flag in the event the interaction was handled, to cancel further interaction code.
 * Return NONE to allow default interaction / tool handling.
 */
/obj/item/proc/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return NONE

/**
 * Called when this item is being used to interact with an atom WITH RIGHT CLICK,
 * IE, a mob is right clicking on an atom with this item.
 *
 * Default behavior has it run the same code as left click.
 *
 * Return an ITEM_INTERACT_ flag in the event the interaction was handled, to cancel further interaction code.
 * Return NONE to allow default interaction / tool handling.
 */
/obj/item/proc/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	return interact_with_atom(interacting_with, user, modifiers)

/*
 * Tool-specific behavior procs.
 *
 * Return an ITEM_INTERACT_ flag to handle the event, or NONE to allow the mob to attack the atom.
 * Returning TRUE will also cancel attacks. It is equivalent to an ITEM_INTERACT_ flag. (This is legacy behavior, and is not to be relied on)
 * Returning FALSE or null will also allow the mob to attack the atom. (This is also legacy behavior)
 */
