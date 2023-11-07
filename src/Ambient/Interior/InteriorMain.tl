local types = require "openmw.types"
local vfs = require "openmw.vfs"
local self = require "openmw.self"
local I = require "openmw.interfaces"
-- local data = require "src.Ambient.Interior.InteriorData"

local enum racePrefix
	"dar"
	"imp"
	"nor"
end
local currentPlaylist: string

local function getPopulatedCell(maxCount: number): boolean
  local count = 0
  for _, npc in ipairs(self.object.cell:getAll(types.Actor)) do
	-- and not (types.Actor.isDead(npc))
    if npc:isValid() and types.Actor.canMove(npc)  then
      count = count + 1
    end
    if count >= maxCount then return true end
  end
  if count < maxCount then return false end
end

local function isValidInterior(): {racePrefix, boolean }
	if getPopulatedCell(3) == false then return {nil, false} end
	for _, actor  in ipairs(self.object.cell:getAll(types.NPC)) do
		local npcRecord = types.NPC.record(actor)
		print("NPC | name: " .. npcRecord.name .. "class: " .. npcRecord.class)
		-- not types.Actor.isDead(actor)
		if (npcRecord.class:find "^%a*[_]?[pP]ublican" ~= nil) then
			local baseRace = npcRecord.race
			if baseRace ~= "Imperial" or baseRace ~= "Nord" or baseRace ~= "Dark Elf" then
				baseRace = "Dark Elf"
			end
			local race = baseRace:sub(1, 3):lower() as racePrefix
			return {race, true}
		end
	end
	return {nil, false}
end

local function onCellChange()
	if (self.object.cell == nil)
	or (self.object.cell.isExterior)
	or (self.object.cell.isQuasiExterior)
	or not (self.object.cell.name) then
		I.Music.setPlaylistActive(currentPlaylist, false)
		return
	end
	local cellData = isValidInterior()
	if currentPlaylist == "aura_InteriorMain_" .. cellData[1] then return end

	I.Music.setPlaylistActive(currentPlaylist, false)
	currentPlaylist = "aura_InteriorMain_" .. cellData[1]
	print(currentPlaylist)
	I.Music.setPlaylistActive(currentPlaylist, cellData[2])
end

local lastKnownCell = self.object.cell
return {
	engineHandlers = {
		onInit = function()
			local publicansPlaylist: {racePrefix:{string}} = {["dar"] = {}, ["imp"] = {}, ["nor"] = {}}
			for fileString in (vfs.pathsWithPrefix("music/tew/aura") as function(): string) do
				local filePath: {string} = {}
				for str in fileString:gmatch("([^/]+)") do
					table.insert(filePath, str)
				end
				if filePath[#filePath - 1] == "dar"
				 or filePath[#filePath - 1] == "imp"
				 or filePath[#filePath - 1] == "nor" then
					table.insert(publicansPlaylist[filePath[#filePath - 1] as racePrefix], fileString)
				end
			end
			for rp, strarr in pairs(publicansPlaylist) do
				for _, str in ipairs(strarr) do
					print(rp .. ": " .. str)
				end
			end
			I.Music.registerPlaylist {
				id = "aura_InteriorMain_dar",
				priority = 10000,
				randomize = true,
				fadeOut = 3.5,
				tracks = publicansPlaylist.dar
			}
			I.Music.registerPlaylist {
				id = "aura_InteriorMain_imp",
				priority = 10001,
				randomize = true,
				fadeOut = 3.5,
				tracks = publicansPlaylist.imp
			}
			I.Music.registerPlaylist {
				id = "aura_InteriorMain_nor",
				priority = 10002,
				randomize = true,
				fadeOut = 3.5,
				tracks = publicansPlaylist.nor
			}
			currentPlaylist = "aura_InteriorMain_" .. isValidInterior()[1]
			print(currentPlaylist)
		end,
		onFrame = function(_)
			if self.object.cell ~= lastKnownCell then
				lastKnownCell = self.object.cell
				onCellChange()
			end
		end
	}
}
