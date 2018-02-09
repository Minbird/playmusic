local API_KEY = "AIzaSyBek-uYZyjZfn2uyHwsSQD7fyKIRCeXifU"

local MPlayM = {}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("min_playmusic/language/ko_kr.lua")
AddCSLuaFile("min_playmusic/language/en_en.lua")
AddCSLuaFile("min_playmusic/host/player_host.lua")
include("shared.lua")

util.AddNetworkString("PlayM_netPlay")
util.AddNetworkString("PlayM_netStop")
util.AddNetworkString("PlayM_netVoice_Chat")
util.AddNetworkString("PlayM_End")
util.AddNetworkString("PlayM_New_Connect")

MPlayM.playing = nil
MPlayM.Length = 0
MPlayM.ChannelTitle = nil
MPlayM.titleText = nil
MPlayM.Queue = {}
MPlayM.QueuePlayerList = {}

MPlayM.Language = GetConVarString("gmod_language")
if MPlayM.Language == "ko" then
	print("[Playmusic] server - Korean language file loaded." )
	include("min_playmusic/language/ko_kr.lua")
else
	print("[Playmusic] server - English language file loaded." )
	include("min_playmusic/language/en_en.lua")
end

CreateConVar( "Playmusic_Length_Limit", 10, "FCVAR_ARCHIVE", "Sets the video length limit." )
Video_Length_Limit = GetConVarNumber( "Playmusic_Length_Limit" )

CreateConVar( "Playmusic_Queue_Limit", 3, "FCVAR_ARCHIVE", "Sets the Queue limit." )
MPlayM.QueueLimit = GetConVarNumber( "Playmusic_Queue_Limit" )

cvars.AddChangeCallback( "Playmusic_Length_Limit", function( convar_name, value_old, value_new )
	print( "[Playmusic] " .. convar_name .. " was changed from " .. value_old .. " to ".. value_new )
	Video_Length_Limit = tonumber(value_new)
end )

cvars.AddChangeCallback( "Playmusic_Queue_Limit", function( convar_name, value_old, value_new )
	print( "[Playmusic] " .. convar_name .. " was changed from " .. value_old .. " to ".. value_new )
	MPlayM.QueueLimit = tonumber(value_new)
end )

function VLength_Limit(Length)

	MPlayM.Length = Length

	local Video_Length_Limit = Video_Length_Limit * 60
	
	if MPlayM.Length > Video_Length_Limit then
		return false
	else
		return true
	end
end

function MPlayM.AddQueue(QueueUrl, QueuePlayer)

	if table.Count( MPlayM.Queue ) >= MPlayM.QueueLimit then
		MPlayM.n(PlayMLanguage.Toomanyqueue)
		return
	end

	table.insert( MPlayM.Queue, QueueUrl )
	table.insert( MPlayM.QueuePlayerList, QueuePlayer:SteamID() )
	MPlayM.n( QueuePlayer:Nick() .. PlayMLanguage.QueueAdded1 .. QueueUrl .. PlayMLanguage.QueueAdded2 .. table.Count( MPlayM.Queue ) .. PlayMLanguage.QueueAdded3)
	
	if table.Count( MPlayM.Queue ) == 1 then
		PlayOnQueue(QueuePlayer:SteamID())
	end
	
end

function MPlayM.RemoveQueue()
	if table.Count( MPlayM.Queue ) == 0 then return end
	table.remove( MPlayM.Queue, 1 )
	table.remove( MPlayM.QueuePlayerList, 1 )
	
	if table.Count( MPlayM.Queue ) > 0 then
		timer.Simple( 1, function() 
		
		table.foreach( MPlayM.Queue, function( key, value )
			MPlayM.URI = value
			if key == 1 then return true end
		end )

		table.foreach( MPlayM.QueuePlayerList, function( key, value )
			PlayingUserID = value
			if key == 1 then return true end
		end )
		
		PlayOnQueue(PlayingUserID)
		
		end)
		MPlayM.n(PlayMLanguage.PrepareTheQueue)
	elseif table.Count( MPlayM.Queue ) == 0 then
		MPlayM.n(PlayMLanguage.Thequeueisempty)
	end
	
end

function PlayOnQueue(PlayingUserID)

table.foreach( MPlayM.Queue, function( key, value )
	MPlayM.URI = value
	if key == 1 then return true end
end )
	
	MPlayM.URI = ParseUrl(MPlayM.URI)
	
		http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=" .. MPlayM.URI .. "&key=" .. API_KEY, function(data,code,headers)
			
			local strJson = data
			json = util.JSONToTable(strJson)
			
			if json["items"][1] == nil then
				No_Data = true
				return
			end

			local contentDetails = json["items"][1]["contentDetails"]
			
			local strVideoDuration = contentDetails["duration"]
			

			MPlayM.Sec = string.match(strVideoDuration, "M([^<]+)S")
			if MPlayM.Sec == nil then
				MPlayM.Sec = string.match(strVideoDuration, "H([^<]+)S")
				if MPlayM.Sec == nil then
					MPlayM.Sec = string.match(strVideoDuration, "PT([^<]+)S")
					if MPlayM.Sec == nil then
						MPlayM.Sec = 0
					end
				end
			end
		
			MPlayM.Min = string.match(strVideoDuration, "H([^<]+)M")
			if MPlayM.Min == nil then
				MPlayM.Min = string.match(strVideoDuration, "PT([^<]+)M")
				if MPlayM.Min == nil then
					MPlayM.Min = 0
				end
			end
			
			MPlayM.Hour = string.match(strVideoDuration, "PT([^<]+)H")
			if MPlayM.Hour == nil then
				MPlayM.Hour = 0
			end
			
			MPlayM.Length = MPlayM.Sec + MPlayM.Min * 60 + MPlayM.Hour * 3600 + 1

		end,nil)
		
			http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=snippet&id=" .. MPlayM.URI .. "&key=" .. API_KEY, function(data,code,headers)
				
				local strJson = data
				json = util.JSONToTable(strJson)
				
				if json["items"][1] == nil then
					No_Data = true
					return
				end
				
				local snippet = json["items"][1]["snippet"]
				
				MPlayM.titleText = snippet["title"]
				MPlayM.ChannelTitle = snippet["channelTitle"]
				IsliveBroadcast = snippet["liveBroadcastContent"]
				
				local Imagedefault = snippet["thumbnails"]
				ImageUrl = Imagedefault["maxres"]
				
				if ImageUrl == nil then
					ImageUrl = Imagedefault["medium"]
				end
				
				ImageUrl = ImageUrl["url"]
		end,nil)
		
		timer.Simple( 2, function() 
		
		
		if MPlayM.titleText == nil or MPlayM.Length == 0 or No_Data then
			MPlayM.err("서버에서 올바른 응답을 받지 못했습니다. " .. "(대상:" .. MPlayM.URI .. ") (영상 데이터를 받아오지 못했거나 처리 도중 문제가 발생했습니다.)")
			MPlayM.RemoveQueue()
			net.Start("PlayM_End")
			net.Broadcast()
			No_Data = false
			return
		elseif IsliveBroadcast == "live" then
			MPlayM.n(PlayMLanguage.LiveStreamingcontentcannotbeplay)
			MPlayM.RemoveQueue()
			net.Start("PlayM_End")
			net.Broadcast()
			No_Data = false
			return
		elseif not VLength_Limit(MPlayM.Length) then
			MPlayM.n(PlayMLanguage.Thisvideoistoolong1 .. Video_Length_Limit .. PlayMLanguage.Thisvideoistoolong2)
			MPlayM.RemoveQueue()
			net.Start("PlayM_End")
			net.Broadcast()
			No_Data = false
			return
		else
			MPlayM.n(PlayMLanguage.Playing .. MPlayM.titleText .." [Channel: " .. MPlayM.ChannelTitle .. " ] [" .. MPlayM.Length .. " sec]")
			
		end
		
		Now_URI = MPlayM.URI
		Now_ChannelTitle = MPlayM.ChannelTitle
		Now_titleText = MPlayM.titleText
		Now_Length = MPlayM.Length
	
		net.Start("PlayM_netPlay")
			net.WriteString(MPlayM.URI)
			net.WriteString(MPlayM.ChannelTitle)
			net.WriteString(MPlayM.titleText)
			net.WriteString(MPlayM.Length)
			net.WriteString(PlayingUserID)
			net.WriteString(ImageUrl)
		net.Broadcast()
		
		print(PlayMLanguage.Playing .. MPlayM.URI)
		StartTime = CurTime() + 3
		
		timer.Simple( 3, function() 
			MPlayM.playing = true 
		end)
		
		MPlayM.URI = nil
		MPlayM.ChannelTitle = nil
		MPlayM.titleText = nil
		MPlayM.Length = nil 
		
		end)
end

function ParseUrl(str)

		if string.find(str,"youtube")!=nil then
			str=string.match(str,"[?&]v=([^&]*)")
		elseif string.find(str,"youtu.be")!=nil then
			str=string.match(str,"https://youtu.be/([^&]*)")
		else
			MPlayM.URI = str
		end

	
	if str == nil or str == "" then
		return "Error"
	else
		MPlayM.URI = str
		return str
	end
end

function PlayM_TimesThink()

	if MPlayM.playing then
	
		MPlayM.Times = CurTime() - StartTime
	
	if (math.floor(MPlayM.Times) / math.floor(Now_Length)) == 1 then
		MPlayM.Times = 0
		net.Start("PlayM_End")
		net.Broadcast()
		MPlayM.playing = false
		MPlayM.stopped = true
		MPlayM.stoppedTime = CurTime()
		MPlayM.RemoveQueue()
		timer.Simple( 5, function() MPlayM.stopped = false end)
	end

	end
	
end

hook.Add("Think", "PlayM_TimesThink", PlayM_TimesThink)


net.Receive("PlayM_netPlay",function(len,ply)

	Queue_Url = net.ReadString()

	MPlayM.AddQueue(Queue_Url, ply)
	
end)

function PlayerInitialSpawn(ply)
	if MPlayM.playing then
	
		net.Start("PlayM_New_Connect")
			net.WriteString(Now_URI)
			net.WriteString(Now_ChannelTitle)
			net.WriteString(Now_titleText)
			net.WriteString(Now_Length)
			net.WriteString(MPlayM.Times)
			net.WriteString(StartTime)
			net.WriteString(ImageUrl)
		net.Send(ply)
	end
end

hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn", PlayerInitialSpawn)

net.Receive("PlayM_netStop",function(len,ply)

		net.Start("PlayM_netStop")
			net.WriteEntity(ply)
		net.Broadcast()
		
		MPlayM.playing = false
		MPlayM.stopped = true
		MPlayM.stoppedTime = CurTime()
		MPlayM.RemoveQueue()
		timer.Simple( 5, function() MPlayM.stopped = false end)
		
end)

net.Receive("PlayM_End",function(len,ply)

	if MPlayM.playing then
		net.Start("PlayM_End")
		net.Broadcast()
		MPlayM.playing = false
		MPlayM.RemoveQueue()
	else
		return
	end
end)

MPlayM.n = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MPlayM.LastMessage = text
	text = "[PlayMusic] " .. text
	PrintMessage(HUD_PRINTTALK, text)
end

MPlayM.err = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MPlayM.LastMessage = text
	text = "[PlayMusic Error] " .. text
	PrintMessage(HUD_PRINTTALK, text)
end

print("[Playmusic] Server - complete!")