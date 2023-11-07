local ambient = require "openmw.ambient"


return {
	eventHandlers = {
		__AURA__useIngredient = function ()
			if ambient.isSoundPlaying("Swallow") then
				ambient.stopSound("Swallow")
			end
			ambient.playSoundFile("sound/fx/eating.wav", {volume = 0.8})
		end
	}
}
