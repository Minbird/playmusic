cmHelp = {}

if CLIENT then

	Languages = GetConVarString("gmod_language")
		
	if Languages == nil then
		RunConsoleCommand("gmod_language en")
		Languages = "en"
	end

end
--[[
if Languages == "ko" then
		Language = "ko"
	else
		Language = "en"
end

function GetLanguages()
	return Language
end

AddCSLuaFile("lua/min_playmusic/lang/" .. Language .. ".lua")
include("lua/min_playmusic/lang/" .. Language .. ".lua")]]