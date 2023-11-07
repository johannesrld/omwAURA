local I = require "openmw.interfaces"
local types = require "openmw.types"
local core = require "openmw.core"

I.ItemUsage.addHandlerForType(types.Ingredient, function(_, actor: core.GameObject)
	if actor.type == types.Player then
		core.sendGlobalEvent("__AURA__useIngredient")
	end
end)
