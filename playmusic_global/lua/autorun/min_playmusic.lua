print("[PlayMusic] Loading...")

if SERVER then
	print("[PlayMusic] Server Loading...")
	include ("min_playmusic/init.lua")
	AddCSLuaFile ("min_playmusic/cl_init.lua")
	AddCSLuaFile ("min_playmusic/shared.lua")
end

if CLIENT then
	print("[PlayMusic] Client Loading...")
	include ("min_playmusic/cl_init.lua")
end