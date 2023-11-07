local types = require "openmw.types"
local vfs = require "openmw.vfs"
local self = require "openmw.self"
local nearby = require "openmw.nearby"
local I = require "openmw.interfaces"
-- local data = require "src.Ambient.Interior.InteriorData"

local waitOneFrame: boolean = false

local enum racePrefix
	"dar"
	"imp"
	"nor"
end
local currentPlaylist: string = ""


local function getPopulatedCell(maxCount: number): boolean
  local count = 0
  for _, actor in ipairs(nearby.actors) do
	if actor.type ~= types.NPC then goto cont end
    count = count + 1
    if count >= maxCount then return true end
	::cont::
  end
  if count < maxCount then return false end
end

local function isValidInterior(): racePrefix | boolean
	if getPopulatedCell(3) == false then return false end
	for _, actor  in ipairs(nearby.actors) do
		if actor.type ~= types.NPC then goto cont end
		local npcRecord = types.NPC.record(actor)
		if (npcRecord.class:find "^%a*[_]?[pP]ublican" ~= nil) then
			local baseRace = npcRecord.race
			if baseRace ~= "imperial" and baseRace ~= "nord" and baseRace ~= "dark elf" then
				baseRace = "dar"
			end
			local race = baseRace:sub(1, 3) as racePrefix
			return race
		end
		::cont::
	end
	return false
end

local function onCellChange()
	if (self.object.cell == nil)
	or (self.object.cell.isExterior)
	or (self.object.cell.isQuasiExterior)
	or not (self.object.cell.name) then
		if currentPlaylist ~= "" then
			I.Music.setPlaylistActive(currentPlaylist, false)
		end
		currentPlaylist = ""
		return
	end
	local cellData = isValidInterior()
	if cellData == false then return end
	if currentPlaylist == "" then return end
	if currentPlaylist == "aura_InteriorMain_" .. cellData as racePrefix then return end

	currentPlaylist = "aura_InteriorMain_" .. cellData as racePrefix
	I.Music.setPlaylistActive(currentPlaylist, true)
end

local lastKnownCell = self.object.cell
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
I.Music.registerPlaylist {
	id = "aura_InteriorMain_dar",
	priority = 10000,
	randomize = true,
	fadeOut = 3.5,
	tracks = publicansPlaylist.dar
}
I.Music.registerPlaylist {
	id = "aura_InteriorMain_imp",
	priority = 10000,
	randomize = true,
	fadeOut = 3.5,
	tracks = publicansPlaylist.imp
}
I.Music.registerPlaylist {
	id = "aura_InteriorMain_nor",
	priority = 10000,
	randomize = true,
	fadeOut = 3.5,
	tracks = publicansPlaylist.nor
}
return {
	engineHandlers = {
		onFrame = function(_)
			if waitOneFrame == false then
				waitOneFrame = true
				return
			end
			if self.object.cell ~= lastKnownCell then
				lastKnownCell = self.object.cell
				onCellChange()
			end
		end
	}
}
