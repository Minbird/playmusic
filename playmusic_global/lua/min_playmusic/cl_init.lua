local API_KEY = "AIzaSyBek-uYZyjZfn2uyHwsSQD7fyKIRCeXifU"

local Ver = "Workshop Edition 0.30 Beta"

include("shared.lua")
include("host/player_host.lua")

local MsModules = {}
local MPlayM = {}
local PlayM = {}
local MPlayerHost = {}

MPlayM.Music = ""
MPlayM.Times = 0
MPlayM.Length = 0
MPlayM.playing = false
MPlayM.Do_fade = false
MPlayM.URI = ""
MPlayM.HUDalpha = 0
MPlayM.StopUser = "nil"
MPlayM.StartTime = 0
MPlayM.PlayTime = 0
MPlayM.titleText = ""
MPlayM.Vol_Music = ""
MPlayM.New_Connect = nil
MPlayM.Do_reload = 0
MPlayM.Do_setPlayer = false
MPlayM.Re_loading = false
MPlayM.Loading_Finished = false
MPlayM.PopupNotify = 0
MPlayM.LeadData_List = 0

local volume_DataFile = file.Find( "Min_Playmusic_volume.txt", "DATA" )
local hudShow_DataFile = file.Find( "Min_Playmusic_hudShow.txt", "DATA" )
local videoShow_DataFile = file.Find( "Min_Playmusic_videoShow.txt", "DATA" )
local noPlay_DataFile = file.Find( "Min_Playmusic_noplay.txt", "DATA" )
local noNoty_DataFile = file.Find( "Min_Playmusic_nonoty.txt", "DATA" )
local Min_Playmusic_MusicList = file.Find( "Min_Playmusic_MusicList_new.txt", "DATA" )

local volume_Default_Data = [[80]]
local hudShow_Default_Data = [[true]]
local videoShow_Default_Data = [[false]]
local noplay_Default_Data = [[false]]
local nonoty_Default_Data = [[false]]
local Music_List_Default_Data = [[{"Saved_List":"0"}]]


if Min_Playmusic_MusicList[1] == nil then
	print("[Playmusic] No data found: Min_Playmusic_MusicList")
	file.Append("Min_Playmusic_MusicList_new.txt")
	file.Write( "Min_Playmusic_MusicList_new.txt", Music_List_Default_Data )
	print("[Playmusic] Created default: Min_Playmusic_MusicList")
end

if volume_DataFile[1] == nil then
	print("[Playmusic] No data found: Min_Playmusic_volume")
	file.Append("Min_Playmusic_volume.txt")
	file.Write( "Min_Playmusic_volume.txt", volume_Default_Data )
	print("[Playmusic] Created default: Min_Playmusic_volume")
end

if hudShow_DataFile[1] == nil then
	print("[Playmusic] No data found: Min_Playmusic_hudShow")
	file.Append("Min_Playmusic_hudShow.txt")
	file.Write( "Min_Playmusic_hudShow.txt", hudShow_Default_Data )
	print("[Playmusic] Created default: Min_Playmusic_hudShow")
end

if videoShow_DataFile[1] == nil then
	print("[Playmusic] No data found: Min_Playmusic_videoShow")
	file.Append("Min_Playmusic_videoShow.txt")
	file.Write( "Min_Playmusic_videoShow.txt", videoShow_Default_Data )
	print("[Playmusic] Created default: Min_Playmusic_videoShow")
end

if noPlay_DataFile[1] == nil then
	print("[Playmusic] No data found: Min_Playmusic_noplay")
	file.Append("Min_Playmusic_noplay.txt")
	file.Write( "Min_Playmusic_noplay.txt", noplay_Default_Data )
	print("[Playmusic] Created default: Min_Playmusic_noplay")
end

if noNoty_DataFile[1] == nil then
	print("[Playmusic] No data found: Min_Playmusic_nonoty")
	file.Append("Min_Playmusic_nonoty.txt")
	file.Write( "Min_Playmusic_nonoty.txt", nonoty_Default_Data )
	print("[Playmusic] Created default: Min_Playmusic_nonoty.txt")
end

MPlayM.vol = file.Read( "Min_Playmusic_volume.txt", "DATA" )
MPlayM.HUD_Show = file.Read( "Min_Playmusic_hudShow.txt", "DATA" )
MPlayM.Tog_VideoShow = file.Read( "Min_Playmusic_videoShow.txt", "DATA" )
MPlayM.noPlay = file.Read( "Min_Playmusic_noplay.txt", "DATA" )
MPlayM.noNOTY_tog = file.Read( "Min_Playmusic_nonoty.txt", "DATA" )
MPlayM.Music_List = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )

MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
MPlayM.Saved_List = MPlayM.musicList["Saved_List"]

print("[Playmusic] User Data Import Successful!")
MPlayM.HUD_Show = util.StringToType(MPlayM.HUD_Show, "bool")
MPlayM.Tog_VideoShow = util.StringToType(MPlayM.Tog_VideoShow, "bool")
MPlayM.noPlay = util.StringToType(MPlayM.noPlay, "bool")
MPlayM.noNOTY_tog = util.StringToType(MPlayM.noNOTY_tog, "bool")

timer.Simple( 1, function()
html = vgui.Create("DHTML")
html:SetPos(ScrW() / 3 - 106 ,0)
html:SetSize(106,60)
if MPlayM.Tog_VideoShow then
	html:SetPaintedManually(false)
else
	html:SetPaintedManually(true)
end
html:SetMouseInputEnabled(false)
html:SetEnabled(true)
html:SetHTML("")

end)

surface.CreateFont("MinPlaymusic_Title",{
font    = "UiBold",
size    = ScreenScale(6),
weight  = 600,
antialias = true,
shadow = true})

surface.CreateFont("MinPlaymusic_Sec",{
font    = "UiBold",
size    = ScreenScale(5),
weight  = 300,
antialias = true,
shadow = true})

surface.CreateFont("MinPlaymusic_MenuTitle",{
font    = "UiBold",
size    = ScreenScale(10),
weight  = 800,
antialias = true,
shadow = true})

function MPlayM.LoadLanguageFile()
	
	MPlayM.Language = GetConVarString("gmod_language")
	if MPlayM.Language == "ko" then
		print("[Playmusic] Korean language file loaded." )
		include("min_playmusic/language/ko_kr.lua")
	else
		print("[Playmusic] English language file loaded." )
		include("min_playmusic/language/en_en.lua")
	end

	if PlayMLanguage.Language == nil then
		print("[Playmusic Error] Language file not loaded successfully. ")
		MPlayM.LoadLanguageFile()
	end
end

MPlayM.LoadLanguageFile()

function MPlayM.checkPlayerState()
	hook.Remove("Think", "checkPlayerState")
	
	html:SetHTML( "<p>Loading...</p>" )
	
	timer.Simple( 0.5, function()
		html:SetHTML(MPlayerHost_Player_Host .. MPlayM.URI .. MPlayerHost_Player_Host2) -- https://minbird.github.io/?url=https://youtube.com/watch?v=
	end)
	
	html:AddFunction("MinPlaymusic", "PlayerState", function(state)
	local PlayerState = tostring(state)
		
		if PlayerState == "5" then -- solved?
		
			html:QueueJavascript([[player.seekTo(]] .. MPlayM.Times + 0 .. [[, true)]])
			MPlayM.Music = "Host connection successful"
			MPlayM.PlayerDoPlay = true
			
		elseif PlayerState == "3" then
		
			MPlayM.Music = PlayMLanguage.buffering
			
			if MPlayM.pause then
				html:QueueJavascript([[player.setVolume(0)]])
			else
				html:QueueJavascript([[player.setVolume(]] .. MPlayM.vol .. [[)]])
			end
			
		elseif PlayerState == "1" then
		
			if not MPlayM.PlayerDoPlay then return end
		
			hook.Remove("Think", "checkPlayerState")
			html:QueueJavascript([[player.seekTo(]] .. MPlayM.Times + 0 .. [[, true)]])
			if MPlayM.pause then
				html:QueueJavascript([[player.pauseVideo()]])
				html:QueueJavascript([[player.setVolume(]] .. MPlayM.vol .. [[)]])
			else
				html:QueueJavascript([[player.setVolume(]] .. MPlayM.vol .. [[)]])
			end
			
			MPlayM.Music = MPlayM.Vol_Music
			
			MPlayM.PlayerDoPlay = false
		
		else
		
			MPlayM.Music = "unknown state (Is Flash Player installed?)"
			
			if MPlayM.pause then
				html:QueueJavascript([[player.setVolume(0)]])
			else
				html:QueueJavascript([[player.setVolume(]] .. MPlayM.vol .. [[)]])
			end
			
		end
	end)

	timer.Simple( 0.3, function()
		hook.Add("Think", "checkPlayerState", function()
			html:RunJavascript([[MinPlaymusic.PlayerState(player.getPlayerState());]])
		end)
	end)
	
	html.ConsoleMessage = function(pself, msg, ...)
		if msg then
			if string.find(msg, "XMLHttpRequest") then return end
			if string.find(msg, "Unsafe JavaScript attempt to access") then return end
			if string.find(msg, "seekTo") then return end
			if string.find(msg, "setVolume") then return end
			if string.find(msg, "getPlayerState") then return end
			if string.find(msg, "MinPlaymusic") then return end
		end
	end
	

end


MsModules.Playmusic = function(ply, text, teamchat, isdead, station, c, args)

	if MsModules.CallPlaymusic(text) and ply == LocalPlayer() then
		local command, args = MsModules.ExtractCommandArgs(text)
		
		args = args
		
		if command == nil then
			return
		end
		
		if string.len(command) == 0 then
			chat.AddText(Color(100, 255, 255), PlayMLanguage.howToUse)
			chat.AddText(PlayMLanguage.howToShowConsoleCommand)
		
		
		elseif command == "play" then
			if string.len(args) == 0 then
				MPlayM.n(PlayMLanguage.pleaseEnterYoutubeUrl)
			else
			
				MPlayM.Fileaddress = args
				
				if string.Left(MPlayM.Fileaddress, 32) == "https://www.youtube.com/watch?v=" or string.Left(MPlayM.Fileaddress, 17) == "https://youtu.be/" then
			
					MPlayM.n(PlayMLanguage.preparePlay .. MPlayM.Fileaddress)
					MPlayM.NotifyCenter(PlayMLanguage.preparePlay .. MPlayM.Fileaddress)
					MPlayM.address = MPlayM.Fileaddress
				
					if MPlayM.Fileaddress == "Error" then
						MPlayM.err(PlayMLanguage.error_processingURL)
						MPlayM.NotifyCenter(PlayMLanguage.error_processingURL)
						MPlayM.Do_fade = false
						MPlayM.playing = false
						MPlayM.Music = ""
					else
						net.Start("PlayM_netPlay")
							net.WriteString(MPlayM.address)
							net.WriteEntity(ply)
						net.SendToServer()
						
					end
					
				else
					MPlayM.n(MPlayM.Fileaddress .. PlayMLanguage.isNotAValidAddress)
					MPlayM.NotifyCenter(MPlayM.Fileaddress .. PlayMLanguage.isNotAValidAddress)
				end
				
			end
		
		
		elseif command == "stop" then
		
			if MPlayM.PlayingUser == nil then
				MPlayM.PlayingUser = "nil"
			end
			
			if ply:IsAdmin() or ply:SteamID() == MPlayM.PlayingUserID then
				net.Start("PlayM_netStop")
				net.SendToServer()
			else
				MPlayM.PlayM_Stop()
			end

		
		elseif command == "showvideo" then
			if not MPlayM.Tog_VideoShow then
				html:SetPos(ScrW() / 3 - 106,0)
				html:SetSize(106,60)
				html:SetPaintedManually(false)
				MPlayM.n(PlayMLanguage.Nowdisplaythevideo)
				MPlayM.NotifyCenter(PlayMLanguage.Nowdisplaythevideo)
				MPlayM.Tog_VideoShow = true
				MPlayM.Write_LocalUserData()
			else
				html:SetPos(ScrW() / 3 - 106,0)
				html:SetSize(106,60)
				html:SetPaintedManually(true)
				MPlayM.n(PlayMLanguage.Nownodisplaythevideo)
				MPlayM.NotifyCenter(PlayMLanguage.Nownodisplaythevideo)
				MPlayM.Tog_VideoShow = false
				MPlayM.Write_LocalUserData()
			end
	
		elseif command == "vol" then
			if string.len(args) == 0 then
				MPlayM.n(PlayMLanguage.howToSetVolume)
				MPlayM.n(PlayMLanguage.showVolumeState1 .. MPlayM.vol .. PlayMLanguage.showVolumeState2)
				MPlayM.Music = PlayMLanguage.showVolumeState1 .. MPlayM.vol .. PlayMLanguage.showVolumeState2
				MPlayM.NotifyCenter(PlayMLanguage.showVolumeState1 .. MPlayM.vol .. PlayMLanguage.showVolumeState2)
				timer.Simple( 5, function() MPlayM.Music = MPlayM.Vol_Music end )
			else
				MPlayM.vol = args
				if not tonumber(MPlayM.vol) then
					MPlayM.n(MPlayM.vol .. PlayMLanguage.PleaseEnterAnInteger)
					return
				end
				MPlayM.vol = math.Clamp( MPlayM.vol + 0, 0, 100 )
			
				MPlayM.n(PlayMLanguage.volumeChangeTo .. MPlayM.vol .. "%.")
				MPlayM.Music = PlayMLanguage.volumeChangeTo .. MPlayM.vol .. "%."
				MPlayM.NotifyCenter(PlayMLanguage.volumeChangeTo .. MPlayM.vol .. "%.")
				html:QueueJavascript([[player.setVolume(]] .. MPlayM.vol .. [[)]])
				timer.Simple( 5, function() MPlayM.Music = MPlayM.Vol_Music end )
				
				MPlayM.Write_LocalUserData()
			
			end
		
		elseif command == "hud" then --
			if MPlayM.HUD_Show then
				MPlayM.n(PlayMLanguage.hideHUD)
				MPlayM.NotifyCenter(PlayMLanguage.hideHUD)
				timer.Simple( 2, function() MPlayM.HUD_Show = false MPlayM.Write_LocalUserData() end)
				MPlayM.Do_fade = false
			else
				MPlayM.n(PlayMLanguage.showHUD)
				MPlayM.NotifyCenter(PlayMLanguage.showHUD)
				MPlayM.HUD_Show = true
				MPlayM.Do_fade = true
				MPlayM.Write_LocalUserData()
			end
		
		elseif command == "reload" or command == "r" then
			if MPlayM.playing then
				MPlayM.Re_loading = true
				MPlayM.Loading_Finished = false
				html:SetHTML("") 
				
				MPlayM.checkPlayerState()

				MPlayM.n(PlayMLanguage.playerRef)
				MPlayM.Music = PlayMLanguage.playerRef
				MPlayM.NotifyCenter(PlayMLanguage.playerRef)
				timer.Simple( 5, function() MPlayM.Music = MPlayM.Vol_Music end )
				
			else
				MPlayM.n(PlayMLanguage.youcantdoit)
			end
			
		elseif command == "noplay" then
		
			if MPlayM.noPlay_tog then
			
				MPlayM.noPlay_tog = false
				
				MPlayM.n(PlayMLanguage.NoplayIsFalse)
				MPlayM.NotifyCenter(PlayMLanguage.NoplayIsFalse)
				MPlayM.Write_LocalUserData()
			else
			
				MPlayM.noPlay_tog = true
				
				MPlayM.n(PlayMLanguage.NoplayIsTure)
				MPlayM.NotifyCenter(PlayMLanguage.NoplayIsTure)
				MPlayM.Write_LocalUserData()
			end
			
		elseif command == "addlist" or command == "alist" then
			if string.len(args) == 0 then
				MPlayM.n(PlayMLanguage.SavetheYouTubeURLtoMyPlaylist)
			else
				MPlayM.Save_Music_List(args, false)
			end
		
		elseif command == "listplay" or command == "lplay" then
			if string.len(args) == 0 then
				MPlayM.n(PlayMLanguage.Canbeplayusingtheuniquenumber)
			else
				MPlayM.Play_MusicList(args, false)
			end
			
		elseif command == "showlist" or command == "slist" then
			if string.len(args) == 0 then
				MPlayM.n(PlayMLanguage.Printoutthemusictitles)
			else
				local lplay = args
				MPlayM.Music_List = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
				MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
				MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
				MPlayM.musicUri = MPlayM.musicList[args .. "_uri"]
				
				if MPlayM.Saved_List == "0" then
					MPlayM.n(PlayMLanguage.Unabletofindsavedlist)
					MPlayM.NotifyCenter(PlayMLanguage.Unabletofindsavedlist)
				elseif MPlayM.musicUri == nil then
					MPlayM.n(lplay .. PlayMLanguage.Thereisnodataonlist)
					MPlayM.NotifyCenter(lplay .. PlayMLanguage.Thereisnodataonlist)
				
				else
				
				
				http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=snippet&id=" .. MPlayM.musicUri .. "&key=" .. API_KEY, function(data,code,headers)
				
					local strJson = data
					json = util.JSONToTable(strJson)
				
					if json["items"][1] == nil then
						No_Data = true
						return
					end
			
					local snippet = json["items"][1]["snippet"]
				
					MPlayM.Musicname = snippet["title"]
					ChannelTitle = snippet["channelTitle"]
					IsliveBroadcast = snippet["liveBroadcastContent"]
				
				end,nil)
				
				timer.Simple( 1, function()
					MPlayM.n(PlayMLanguage.InformationaboutList .. lplay .. "\nURI: " .. MPlayM.musicUri .. "\n" .. PlayMLanguage.ListInformationTitle .. MPlayM.Musicname .. "\n" .. PlayMLanguage.ListInformationChannel .. ChannelTitle )
					MPlayM.NotifyCenter(lplay .. PlayMLanguage.hasbeenprintedinachat)
				end)
				
				end

				
			end
		
		elseif command == "dellist" or command == "rlist" then
			if string.len(args) == 0 then
				MPlayM.n(PlayMLanguage.Removealistbyenteringtheuniquenumber)
			elseif args == "*" then
				file.Write( "Min_Playmusic_MusicList_new.txt", Music_List_Default_Data )
				MPlayM.n(PlayMLanguage.Alllistshavebeenremoved)
				MPlayM.NotifyCenter(PlayMLanguage.Alllistshavebeenremoved)
			else
				MPlayM.Music_List = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
				MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
				MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
				MPlayM.musicUri = MPlayM.musicList[args .. "_uri"]
		
				if MPlayM.Saved_List == "0" then
					MPlayM.n(PlayMLanguage.Unabletofindsavedlist)
					MPlayM.NotifyCenter(PlayMLanguage.Unabletofindsavedlist)
				elseif MPlayM.musicUri == nil then
					MPlayM.n(args .. PlayMLanguage.Thereisnodataonlist)
					MPlayM.NotifyCenter(args .. PlayMLanguage.Thereisnodataonlist)
				else
					
					Remove_List_First = string.match(MPlayM.Music_List, "([^<]+),\"" .. args .. "_uri\":\"")
					Remove_List_Last = string.match(MPlayM.Music_List, "\"" .. args .. "_uri\":\"" .. MPlayM.musicUri .. "\"([^<]+)")
				
					if Remove_List_Last == nil then
						Remove_List_Last = "}"
					end
					
					file.Write( "Min_Playmusic_MusicList_new.txt", Remove_List_First .. Remove_List_Last)
					MPlayM.n(args .. PlayMLanguage.Listhasbeenremoved)
					MPlayM.NotifyCenter(args .. PlayMLanguage.Listhasbeenremoved)
					MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
					MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
				end
				
			end
		
		else
			
			MPlayM.n(PlayMLanguage.Unknowncommand)
			MPlayM.NotifyCenter(PlayMLanguage.Unknowncommand)
	
		end
	end
end

hook.Add("OnPlayerChat", "MsModules.Playmusic", MsModules.Playmusic)

function MPlayM.Write_LocalUserData()

	MPlayM.hudShow = util.StringToType(MPlayM.HUD_Show, "string")
	MPlayM.videoShow = util.StringToType(MPlayM.Tog_VideoShow, "string")
	MPlayM.noPlay_Write = util.StringToType(MPlayM.noPlay_tog, "string")
	MPlayM.noNOTY_Write = util.StringToType(MPlayM.noNOTY_tog, "string")

	file.Write( "Min_Playmusic_volume.txt", MPlayM.vol )
	file.Write( "Min_Playmusic_hudShow.txt", MPlayM.hudShow )
	file.Write( "Min_Playmusic_videoShow.txt", MPlayM.videoShow )
	file.Write( "Min_Playmusic_noplay.txt", MPlayM.noPlay_Write )
	file.Write( "Min_Playmusic_nonoty.txt", MPlayM.noNOTY_Write )
	
	print("[Playmusic] New Data Created: \n vol:" .. MPlayM.vol .. "\n hudShow:" .. MPlayM.hudShow .. "\n videoShow:" .. MPlayM.videoShow .. "\n MPlayM.noPlay: " .. MPlayM.noPlay_Write .. "\n noNoty: " .. MPlayM.noNOTY_Write )
	
end

function MPlayM.Play_MusicList(args, WindowUI_Noty)
	local lplay = args
		MPlayM.Music_List = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
		MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
		MPlayM.List_URI = MPlayM.musicList[args .. "_uri"]
		MPlayM.Musicname = MPlayM.musicList[args .. "_name"]
				
	if MPlayM.List_URI == nil then
	
		if WindowUI_Noty then
			openWindowUI_Noty(PlayMLanguage.Failedtoplaymusic, lplay .. PlayMLanguage.Thereisnodataonlist)
		else
			MPlayM.n(lplay .. PlayMLanguage.Thereisnodataonlist)
			MPlayM.NotifyCenter(lplay .. PlayMLanguage.Thereisnodataonlist)
		end
		return
	end
				
	net.Start("PlayM_netPlay")
		net.WriteString(MPlayM.List_URI)
		net.WriteEntity(ply)
	net.SendToServer()
end

function MPlayM.Save_Music_List(args, Noty)

	MPlayM.n(PlayMLanguage.Pleasewait)

	if string.find(args,"youtube")!=nil then
		args = string.match(args,"[?&]v=([^&]*)")
	elseif string.find(args,"youtu.be")!=nil then
		args=string.match(args,"https://youtu.be/([^&]*)")
	else

		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.InvalidURL)
		else
			MPlayM.n(PlayMLanguage.InvalidURL)
			MPlayM.NotifyCenter(PlayMLanguage.InvalidURL)
		end
		return
	end
	
	if args == nil then
		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.URIwasnotrecognized)
		else
			MPlayM.n(PlayMLanguage.URIwasnotrecognized)
			MPlayM.NotifyCenter(PlayMLanguage.URIwasnotrecognized)
		end
		return
	end

	http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=snippet&id=" .. args .. "&key=" .. API_KEY, function(data,code,headers)
				
		local strJson = data
		json = util.JSONToTable(strJson)
				
		if json["items"][1] == nil then
			return
		end
				
		local snippet = json["items"][1]["snippet"]
				
		MPlayM.Musicname_apl = snippet["title"]
		ChannelTitle_apl = snippet["channelTitle"]
		IsliveBroadcast_apl = snippet["liveBroadcastContent"]
				
	end,nil)
	
	timer.Simple( 1, function() 

	if MPlayM.Musicname_apl == nil or ChannelTitle_apl == nil then
		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.Failedtoreceivevideoinformation .. args)
		else
			MPlayM.n(PlayMLanguage.Failedtoreceivevideoinformation .. args)
			MPlayM.NotifyCenter(PlayMLanguage.Failedtoreceivevideoinformation .. args )
		end
		return
	end
	
	if IsliveBroadcast_apl == "live" then
		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.LiveStreamingcontentcannotbesaved)
		else
			MPlayM.n(PlayMLanguage.LiveStreamingcontentcannotbesaved)
			MPlayM.NotifyCenter(PlayMLanguage.LiveStreamingcontentcannotbesaved)
		end
		return
	end

	MPlayM.Music_List = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
	MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
	MPlayM.Saved_List = MPlayM.musicList["Saved_List"]

	if MPlayM.Saved_List == "0" then
		local Add_Music = args
		file.Write( "Min_Playmusic_MusicList_new.txt", [[{"Saved_List":"1","1_uri":"]] .. Add_Music .. [["}]] )
		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
		else
			MPlayM.n(PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
			MPlayM.NotifyCenter(PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
		end
		MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
		MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
	elseif MPlayM.Saved_List == "200" then
		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.Toomanylistssaved)
		else
			MPlayM.n(PlayMLanguage.Toomanylistssaved)
			MPlayM.NotifyCenter(PlayMLanguage.Toomanylistssaved)
		end
	else
		local Add_Music = args
		MPlayM.Saved_Music_List = string.match(MPlayM.Music_List, "{\"Saved_List\":\"" .. MPlayM.Saved_List .. "\",([^&]*)}")
		if MPlayM.Saved_Music_List == nil then
			local Add_Music = args
			file.Write( "Min_Playmusic_MusicList_new.txt", [[{"Saved_List":"1","1_uri":"]] .. Add_Music .. [["}]] )
			if Noty then
				openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
			else
				MPlayM.n(PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
				MPlayM.NotifyCenter(PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
			end
			MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
			MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
		else

		file.Write( "Min_Playmusic_MusicList_new.txt", [[{"Saved_List":"]] .. MPlayM.Saved_List + 1 .. [[",]] .. MPlayM.Saved_Music_List .. [[,"]] .. MPlayM.Saved_List + 1 .. [[_uri":"]] .. Add_Music .. [["}]])
		if Noty then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
		else
			MPlayM.n(PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
			MPlayM.NotifyCenter(PlayMLanguage.Listregistrationsucceeded .. "\n Channel: " .. ChannelTitle_apl .. " \nTitle: " .. MPlayM.Musicname_apl .. " \n Unique Number: " .. MPlayM.Saved_List + 1)
		end
		MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
		MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
		end
	end
	
	MPlayM.Musicname_apl = nil
	ChannelTitle_apl = nil
	IsliveBroadcast_apl = nil
	MPlayM.Do_ReloadList = true
	
	end)

end

function MPlayM.PlaymusicHUD()

	local nextThink = 0
	local curTime = CurTime()
	
		
	if not MPlayM.HUD_Show then
		MPlayM.alpha = 0
	else
		MPlayM.alpha = 1
	
		if (nextThink < curTime) then
			if MPlayM.Do_fade then
				if MPlayM.HUDalpha == 200 then
				else
				MPlayM.HUDalpha = MPlayM.HUDalpha + 1
				end
			else
				if MPlayM.HUDalpha == 0 then 
				else
				MPlayM.HUDalpha = MPlayM.HUDalpha - 1
				end
			end
			nextThink = curTime + 0.01
		end
	end
	
	if MPlayM.Times == nil then
		MPlayM.Times = 0
	end

	MPlayM.PlayTime = string.ToMinutesSeconds(MPlayM.Times)
	MPlayM.MusicTime = string.ToMinutesSeconds(MPlayM.Length)
	
	if (MPlayM.Times / MPlayM.Length) >= 1 then
		MPlayM.HUD_Time = 1
	else
		MPlayM.HUD_Time = (MPlayM.Times / MPlayM.Length)
	end

	draw.RoundedBox( 6, ScrW() / 3 + 40, 10, ScrW() / 3 - 80, 40, Color( 50, 50, 50, MPlayM.HUDalpha * MPlayM.alpha ) )
	draw.RoundedBox( 4, ScrW() / 3 + 90, 36, ScrW() / 3 - 180, 10, Color( 150, 150, 150, MPlayM.HUDalpha * MPlayM.alpha ))
	draw.RoundedBox( 4, ScrW() / 3 + 90, 36, (ScrW() / 3 - 180) * MPlayM.HUD_Time, 10, Color( 255, 0, 0, MPlayM.HUDalpha * MPlayM.alpha ))
	draw.DrawText( MPlayM.Music, "MinPlaymusic_Title", ScrW() * 0.5, 13, Color( 255, 255, 255, MPlayM.HUDalpha * MPlayM.alpha ), TEXT_ALIGN_CENTER )
	draw.DrawText( MPlayM.PlayTime, "MinPlaymusic_Sec", ScrW() / 3 + 65, 33, Color( 255, 255, 255, MPlayM.HUDalpha * MPlayM.alpha ), TEXT_ALIGN_CENTER )
	draw.DrawText( MPlayM.MusicTime, "MinPlaymusic_Sec", (ScrW() / 3) + (ScrW() / 3 - 65), 33, Color( 255, 255, 255, MPlayM.HUDalpha * MPlayM.alpha ), TEXT_ALIGN_CENTER )
end

local nextThink = 0

hook.Add("HUDPaint", "MPlayM.PlaymusicHUD", MPlayM.PlaymusicHUD)

concommand.Add( "playmusic_openmenu", function()
	MPlayM.openMenu()
end)

function MPlayM.openMenu(self)

	local MenuPanel = vgui.Create( "DFrame" )
	MenuPanel:SetSize( 640, 360 )
	MenuPanel:Center()
	MenuPanel:SetTitle( "" )
	MenuPanel:SetDraggable( false )
	MenuPanel:MakePopup()
	MenuPanel:SetBackgroundBlur(1)
	MenuPanel:SetSkin( "Default" )
	
	local Menubg = vgui.Create( "DPanel", MenuPanel )
		Menubg:Dock( FILL )
		Menubg:SetBackgroundColor( Color( 50, 50, 50, 255 ) )
	

	if MPlayM.ImageUrl == nil then
		MPlayM.ImageUrl = ""
	end
	local BackGroundImage = vgui.Create( "DHTML", Menubg )
	BackGroundImage:SetPos( -10, -10 )
	BackGroundImage:SetSize( 660, 380)
	BackGroundImage:SetHTML( "<img src=\"" .. MPlayM.ImageUrl .. "\" width=\"640\" height=\"360\">" )
	BackGroundImage:SetMouseInputEnabled(false)
	BackGroundImage:SetEnabled(true)
	
	local gradient = vgui.Create( "DImage", Menubg )
	gradient:SetPos( 0, 0 )
	gradient:SetSize( 1280, 1280 )
	gradient:SetImage( "html/img/gradient.png" )
	
	local Menulbl = vgui.Create( "DLabel", Menubg )
	Menulbl:SetPos(10,100)
	Menulbl:SetSize( MenuPanel:GetWide() - 200, 250 )
	Menulbl:SetTextColor( Color( 240, 240, 230 ) )
	Menulbl:SetFont( "MinPlaymusic_MenuTitle" )
	Menulbl:SetWrap( false )
	Menulbl:SetText( MPlayM.titleText )
	
	local MusicTime_Lable = vgui.Create( "DLabel", Menubg )
	MusicTime_Lable:SetPos(12,121)
	MusicTime_Lable:SetSize( MenuPanel:GetWide() - 200, 250 )
	MusicTime_Lable:SetTextColor( Color( 240, 240, 230 ) )
	MusicTime_Lable:SetWrap( false )
	MusicTime_Lable:SetText( MPlayM.PlayTime .. " / " .. MPlayM.MusicTime )
	
	DProgress = vgui.Create( "DProgress", Menubg  )
	DProgress:SetPos( 10, MenuPanel:GetTall() - 105 )
	DProgress:SetSize( MenuPanel:GetWide() - 30, 8 )
	
	local PlayButton = vgui.Create( "DImageButton", Menubg ) -- 재생
	PlayButton:SetImage( "html/img/arrow_right.png" )
	PlayButton:SetColor( Color( 0, 0, 0, 150 ) )
	PlayButton:SizeToContents() 
	PlayButton:SetPos( PlayButton:GetWide() - 18, MenuPanel:GetTall() - PlayButton:GetTall() - 48 )
	
	local PlayButton = vgui.Create( "DImageButton", Menubg ) 
	PlayButton:SetImage( "html/img/arrow_right.png" )	
	PlayButton:SizeToContents() 
	PlayButton:SetColor( Color( 255, 255, 255, 255 ) )
	PlayButton:SetPos( PlayButton:GetWide() - 20, MenuPanel:GetTall() - PlayButton:GetTall() - 50 )
	PlayButton.DoClick = function()
		openUrlInputWindow()
	end
	
	local pauseButton = vgui.Create( "DImageButton", Menubg ) -- 일시 정지
	pauseButton:SetImage( "icon16/control_pause.png" )
	pauseButton:SetColor( Color( 0, 0, 0, 150 ) )
	pauseButton:SizeToContents() 
	pauseButton:SetPos( pauseButton:GetWide() + 32, MenuPanel:GetTall() - pauseButton:GetTall() - 56 )
	
	local pauseButton = vgui.Create( "DImageButton", Menubg ) 
	pauseButton:SetImage( "icon16/control_pause.png" )	
	pauseButton:SizeToContents() 
	pauseButton:SetPos( pauseButton:GetWide() + 32, MenuPanel:GetTall() - pauseButton:GetTall() - 58 )
	pauseButton.DoClick = function()
		if MPlayM.pause then
			MPlayM.pause = false
			html:QueueJavascript([[player.seekTo(]] .. MPlayM.Times + 0 .. [[, true)]])
			html:QueueJavascript([[player.playVideo()]])
		else
			MPlayM.pause = true
			html:QueueJavascript([[player.pauseVideo()]])
		end
	end
	
	local StopButton = vgui.Create( "DImageButton", Menubg ) -- 종료
	StopButton:SetImage( "icon16/control_stop.png" )
	StopButton:SetColor( Color( 0, 0, 0, 150 ) )
	StopButton:SizeToContents() 
	StopButton:SetPos( StopButton:GetWide() + PlayButton:GetWide() + pauseButton:GetWide() + 5, MenuPanel:GetTall() - StopButton:GetTall() - 56 )
	
	local StopButton = vgui.Create( "DImageButton", Menubg ) 
	StopButton:SetImage( "icon16/control_stop.png" )	
	StopButton:SizeToContents() 
	StopButton:SetColor( Color( 255, 255, 255, 255 ) )
	StopButton:SetPos( StopButton:GetWide() + PlayButton:GetWide() + pauseButton:GetWide() + 5, MenuPanel:GetTall() - StopButton:GetTall() - 58 )
	StopButton.DoClick = function()
		if MPlayM.PlayingUser == nil then
			MPlayM.PlayingUser = "nil"
		end
			
		if LocalPlayer():IsAdmin() or LocalPlayer():SteamID() == MPlayM.PlayingUserID then
				net.Start("PlayM_netStop")
				net.SendToServer()
		else
				MPlayM.PlayM_Stop()
		end
	end
	
	local ReloadButton = vgui.Create( "DImageButton", Menubg ) -- 리로드
	ReloadButton:SetImage( "icon16/control_repeat.png" )
	ReloadButton:SetColor( Color( 0, 0, 0, 150 ) )
	ReloadButton:SizeToContents() 
	ReloadButton:SetPos( ReloadButton:GetWide() + PlayButton:GetWide() + pauseButton:GetWide() + StopButton:GetWide() + 10, MenuPanel:GetTall() - ReloadButton:GetTall() - 56 )
	
	local ReloadButton = vgui.Create( "DImageButton", Menubg ) 
	ReloadButton:SetImage( "icon16/control_repeat.png" )	
	ReloadButton:SizeToContents() 
	ReloadButton:SetColor( Color( 255, 255, 255, 255 ) )
	ReloadButton:SetPos( ReloadButton:GetWide() + PlayButton:GetWide() + pauseButton:GetWide() + StopButton:GetWide() + 10, MenuPanel:GetTall() - ReloadButton:GetTall() - 58 )
	ReloadButton.DoClick = function()
		RunConsoleCommand("playmusic_reload")
	end
	
	local VolumePanel = vgui.Create( "DPanel", Menubg )
	VolumePanel:SetPos( MenuPanel:GetWide() - 310, MenuPanel:GetTall() - 80 )	
	VolumePanel:SetSize( 290, 30 )
	VolumePanel:SetBackgroundColor( Color( 255, 255, 255, 80 ) )
	
	local VolumeSlider = vgui.Create( "DNumSlider", Menubg ) -- 볼륨
	VolumeSlider:SetPos( MenuPanel:GetWide() - 300, MenuPanel:GetTall() - 70 )		
	VolumeSlider:SetSize( 300, 10 )		
	VolumeSlider:SetText( "Volume" )
	VolumeSlider:SetMin( 0 )				
	VolumeSlider:SetMax( 100 )		
	VolumeSlider:SetValue( MPlayM.vol )	
	VolumeSlider:SetDecimals( 0 )
	VolumeSlider:SetDark(true)
	
	local MusicList = vgui.Create( "DImageButton", Menubg ) -- 음악 상세 정보
	MusicList:SetImage( "icon16/music.png" )
	MusicList:SizeToContents() 
	MusicList:SetPos( MusicList:GetWide() - 10, MusicList:GetTall() - 10 )
	MusicList:SetTooltip( PlayMLanguage.MyPlayList )
	MusicList.DoClick = function()
		MPlayM.openPlayList()
	end
	
	local MusicInfo = vgui.Create( "DImageButton", Menubg ) -- 음악 상세 정보
	MusicInfo:SetImage( "html/img/viewonline.png" )
	MusicInfo:SizeToContents() 
	MusicInfo:SetPos( MenuPanel:GetWide() - MusicInfo:GetWide() - 15, MusicInfo:GetTall() - 10 )
	MusicInfo:SetTooltip( PlayMLanguage.Thedetailsofthesongthatisplaying )
	MusicInfo.DoClick = function()
	
		if PlayingUserName then
			openWindowUI_Noty( PlayMLanguage.Thedetailsofthesong, PlayMLanguage.Thedetailsofthesong_title .. MPlayM.titleText .. PlayMLanguage.Thedetailsofthesong_Musiclength .. MPlayM.MusicTime .. PlayMLanguage.Thedetailsofthesong_Channel .. ChannelTitle .. "\nURL: https://www.youtube.com/watch?v=" .. MPlayM.URI )
		else
			openWindowUI_Noty( PlayMLanguage.Thedetailsofthesong, PlayMLanguage.Thedetailsofthesong_title .. MPlayM.titleText .. PlayMLanguage.Thedetailsofthesong_Musiclength .. MPlayM.MusicTime .. PlayMLanguage.Thedetailsofthesong_Channel .. ChannelTitle .. "\nURL: https://www.youtube.com/watch?v=" .. MPlayM.URI )
		end
		
	end
	
	local SystemOption = vgui.Create( "DImageButton", Menubg ) -- 설정
	SystemOption:SetImage( "icon16/wrench.png" )
	SystemOption:SizeToContents() 
	SystemOption:SetPos( MenuPanel:GetWide() - SystemOption:GetWide() - 35, SystemOption:GetTall() - 10 )
	SystemOption:SetTooltip( PlayMLanguage.Opentheoptions )
	SystemOption.DoClick = function()
		MPlayM.openSystemOptions()
	end
	
	local SystemInfo = vgui.Create( "DImageButton", Menubg ) -- 시스템 정보
	SystemInfo:SetImage( "icon16/cog.png" )
	SystemInfo:SizeToContents() 
	SystemInfo:SetPos( MenuPanel:GetWide() - SystemInfo:GetWide() - 55, SystemInfo:GetTall() - 10 )
	SystemInfo.DoClick = function()
		openWindowUI_Noty(PlayMLanguage.Systeminformation, "System Version: " .. Ver )
	end
	
	hook.Add("Think", "MenuThink", function()
		
		if MenuPanel:IsValid() then
			
		if MPlayM.pause then
			pauseButton:SetImage( "icon16/control_play.png" )	
			pauseButton:SizeToContents() 
		else
			pauseButton:SetImage( "icon16/control_pause.png" )	
			pauseButton:SizeToContents()
		end
		
		if VolumeSlider:IsEditing() then
			MPlayM.vol = VolumeSlider:GetValue()
			if MPlayM.playing then
				html:QueueJavascript([[player.setVolume(]] .. MPlayM.vol .. [[)]])
			end
			NoWrite_Vol = false
		else
			if NoWrite_Vol == false then
				MPlayM.Write_LocalUserData()
				NoWrite_Vol = true
			end
		end
		
			if MPlayM.playing then
				Menulbl:SetText( MPlayM.titleText )
				pauseButton:SetDisabled()
				MusicInfo:SetDisabled()
				StopButton:SetDisabled()
				ReloadButton:SetDisabled()
				if MPlayM.LoadImage then
					BackGroundImage:SetHTML( "<img src=\"" .. MPlayM.ImageUrl .. "\" width=\"640\" height=\"360\">" )
					MPlayM.LoadImage = false
				end
				MusicTime_Lable:SetText( MPlayM.PlayTime .. " / " .. MPlayM.MusicTime )
				
			else
				Menulbl:SetText( PlayMLanguage.Nosongisplaying )
				pauseButton:SetEnabled()
				MusicInfo:SetEnabled()
				StopButton:SetEnabled()
				ReloadButton:SetEnabled()
				MPlayM.LoadImage = true
			end
			
			DProgress:SetFraction( MPlayM.HUD_Time )
			
		end
	end)
	

end

function MPlayM.openPlayList()

	local PlayListWindow = vgui.Create( "DFrame" )
	PlayListWindow:SetSize( 600, ScrH() * 0.8)
	PlayListWindow:Center()
	PlayListWindow:SetTitle( PlayMLanguage.MyPlayList )
	PlayListWindow:SetIcon( "icon16/page.png" )
	PlayListWindow:SetDraggable( true )
	PlayListWindow:MakePopup()
	PlayListWindow:SetSkin( "Default" )

	local PlayListWindowbg = vgui.Create( "DPanel", PlayListWindow )
	PlayListWindowbg:Dock( FILL )
	PlayListWindowbg:SetBackgroundColor( Color( 255, 255, 255, 255 ) )
	
	local PlayList_Listbg = vgui.Create( "DPanel", PlayListWindowbg )
	PlayList_Listbg:Dock( FILL )
	PlayList_Listbg:SetBackgroundColor( Color( 100, 100, 100, 255 ) )
	
	local MusicList_App = vgui.Create( "DListView", PlayList_Listbg )
	MusicList_App:Dock( FILL )
	MusicList_App:SetMultiSelect( false )
	MusicList_App:AddColumn( PlayMLanguage.UniqueNumber )
	MusicList_App:AddColumn( "URI" )
	
	local PlayListMusicNamebg = vgui.Create( "DPanel", PlayListWindowbg )
	PlayListMusicNamebg:Dock( TOP )
	PlayListMusicNamebg:SetSize( PlayListWindowbg:GetWide(), 50)
	PlayListMusicNamebg:SetBackgroundColor( Color( 100, 100, 100, 255 ) )
	
	local MusicInfo_TOP = vgui.Create( "DLabel", PlayListMusicNamebg )
	MusicInfo_TOP:Dock(FILL)
	MusicInfo_TOP:SetText( PlayMLanguage.Nolistselected )
	
	MPlayM.MusicList_Data = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
	MPlayM.musicList = util.JSONToTable(MPlayM.MusicList_Data)
	MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
	
	MPlayM.Do_ReloadList = true
	MPlayM.List_DoClear = false
	
	hook.Add( "Think", "LeadData", function()
	
	if PlayListWindow:IsVisible() then
		if MPlayM.Do_ReloadList then
			MPlayM.musicList = util.JSONToTable(MPlayM.MusicList_Data)
			if MPlayM.LeadData_List .. "_" == MPlayM.Saved_List .. "_" then
				PlayListWindow:SetTitle( PlayMLanguage.MyPlayList )
				MPlayM.LeadData_List = 0
				MPlayM.musicUri = nil
				MPlayM.Do_ReloadList = false
				MPlayM.List_DoClear = true
				return
			else
				if MPlayM.List_DoClear then
					MPlayM.MusicList_Data = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
					MPlayM.musicList = util.JSONToTable(MPlayM.MusicList_Data)
					MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
					MusicList_App:Clear()
				end
				MPlayM.List_DoClear = false
				MPlayM.musicUri = MPlayM.musicList[MPlayM.LeadData_List + 1 .. "_uri"]
				
				if MPlayM.musicUri == nil or MPlayM.musicUri == "" then
					MPlayM.LeadData_List = MPlayM.LeadData_List + 1
					return
				end
				
				PlayListWindow:SetTitle( PlayMLanguage.MyPlayList .. " : Loading:" .. MPlayM.LeadData_List + 1 .. "..." )
				MPlayM.musicList = util.JSONToTable(MPlayM.MusicList_Data)[MPlayM.LeadData_List + 1]
				MusicList_App:AddLine(MPlayM.LeadData_List + 1, MPlayM.musicUri)
				MPlayM.LeadData_List = MPlayM.LeadData_List + 1
			end
		end
	
	else
		MPlayM.MusicList_Data = nil
		MPlayM.musicList = nil
		MPlayM.Saved_List = nil
		MPlayM.LeadData_List = 0
		MPlayM.musicUri = nil
		hook.Remove("Think", "LeadData")
	end
	
	
	end)
	
	MusicList_App.OnRowSelected = function( lst, index, pnl )
		MPlayM.MusicList_Numbers = pnl:GetColumnText( 1 )
		MPlayM.MusicList_URI = pnl:GetColumnText( 2 )
		
		http.Fetch("https://www.googleapis.com/youtube/v3/videos?part=snippet&id=" .. MPlayM.MusicList_URI .. "&key=" .. API_KEY, function(data,code,headers)
				
			local strJson = data
			json = util.JSONToTable(strJson)
				
			if json["items"][1] == nil then
				No_Data = true
				return
			end
			
			local snippet = json["items"][1]["snippet"]
				
			MPlayM.PLAYLIST_Musicname = snippet["title"]
			MPlayM.PLAYLIST_ChannelTitle = snippet["channelTitle"]
			
			MusicInfo_TOP:SetText( PlayMLanguage.Thedetailsofthesong_title .. MPlayM.PLAYLIST_Musicname .. PlayMLanguage.Thedetailsofthesong_Channel .. MPlayM.PLAYLIST_ChannelTitle )
				
		end,nil)
		
	end


	local DermaButton = vgui.Create( "DButton", PlayListWindowbg ) 
	DermaButton:SetText( PlayMLanguage.Remove )		
	DermaButton:SetIcon( "icon16/bin.png" )	
	DermaButton:Dock( BOTTOM )	
	DermaButton.DoClick = function()
		if MPlayM.MusicList_Numbers == nil then
			openWindowUI_Noty(PlayMLanguage.information, PlayMLanguage.Pleaseselectalistandtryagain)
			MPlayM.MusicList_Numbers = nil
			MPlayM.MusicList_URI = nil
			return
		end

		MPlayM.Music_List = file.Read( "Min_Playmusic_MusicList_new.txt", "DATA" )
		MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
		MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
		MPlayM.musicUri = MPlayM.musicList[MPlayM.MusicList_Numbers .. "_uri"]
		
		if MPlayM.Saved_List == "0" then
			MPlayM.n(PlayMLanguage.Unabletofindsavedlist)
			MPlayM.NotifyCenter(PlayMLanguage.Unabletofindsavedlist)
		elseif MPlayM.musicUri == nil then
			MPlayM.n(MPlayM.MusicList_Numbers .. PlayMLanguage.Thereisnodataonlist)
			MPlayM.NotifyCenter(MPlayM.MusicList_Numbers .. PlayMLanguage.Thereisnodataonlist)
		else
			Remove_List_First = string.match(MPlayM.Music_List, "([^<]+),\"" .. MPlayM.MusicList_Numbers .. "_uri\":\"")
			Remove_List_Last = string.match(MPlayM.Music_List, "\"" .. MPlayM.MusicList_Numbers .. "_uri\":\"" .. MPlayM.musicUri .. "\"([^<]+)")
			
			if Remove_List_Last == nil then
				Remove_List_Last = "}"
			end
					
			file.Write( "Min_Playmusic_MusicList_new.txt", Remove_List_First .. Remove_List_Last)
			MPlayM.n(MPlayM.MusicList_Numbers .. PlayMLanguage.Listhasbeenremoved)
			MPlayM.NotifyCenter(MPlayM.MusicList_Numbers .. PlayMLanguage.Listhasbeenremoved)
			MPlayM.musicList = util.JSONToTable(MPlayM.Music_List)
			MPlayM.Saved_List = MPlayM.musicList["Saved_List"]
		end
		
		MPlayM.Do_ReloadList = true
	end
	
	local DermaButton = vgui.Create( "DButton", PlayListWindowbg ) 
	DermaButton:SetText( PlayMLanguage.Addalist )			
	DermaButton:SetIcon( "icon16/add.png" )
	DermaButton:Dock( BOTTOM )	
	DermaButton.DoClick = function()
		openUI_AddMusicList()
	end
	
	local DermaButton = vgui.Create( "DButton", PlayListWindowbg ) 
	DermaButton:SetText( PlayMLanguage.play )	
	DermaButton:SetIcon( "icon16/resultset_next.png" )		
	DermaButton:Dock( BOTTOM )	
	DermaButton.DoClick = function()
		if MPlayM.MusicList_Numbers == nil then
			openWindowUI_Noty(PlayMLanguage.play, PlayMLanguage.Pleaseselectalistandtryagain)
			MPlayM.MusicList_Numbers = nil
			MPlayM.MusicList_URI = nil
			return
		end
		MPlayM.Play_MusicList( MPlayM.MusicList_Numbers, true)
		PlayListWindow:Close()
	end
	
	MPlayM.MusicList_Numbers = nil
	MPlayM.MusicList_URI = nil
end

function openUI_AddMusicList()
	local MenuPanel = vgui.Create( "DFrame" )
	MenuPanel:SetSize( 640, 190 )
	MenuPanel:Center()
	MenuPanel:SetTitle( PlayMLanguage.Addalist )
	MenuPanel:SetDraggable( false )
	MenuPanel:MakePopup()
	MenuPanel:SetSkin( "Default" )
	
	local Menubg = vgui.Create( "DPanel", MenuPanel )
	Menubg:Dock( FILL )
	Menubg:SetBackgroundColor( Color( 50, 50, 50, 255 ) )
	
	local UrlInput = vgui.Create( "DLabel", Menubg )
	UrlInput:SetPos(25,10)
	UrlInput:SetSize( 500, 30 )
	UrlInput:SetTextColor( Color( 240, 240, 230 ) )
	UrlInput:SetWrap( true )
	UrlInput:SetText( PlayMLanguage.EntertheYoutubeURLheretoaddinyourplaylist )
	
	local TextEntry = vgui.Create( "DTextEntry", Menubg ) -- create the form as a child of frame
	TextEntry:SetPos( 25, 50 )
	TextEntry:SetSize( 580, 25 )
	TextEntry:SetText( "" )
	TextEntry.OnEnter = function( self )
		local Value = self:GetValue()
		MPlayM.Save_Music_List(Value, true)
	end
		
	local OpenBrowser = vgui.Create( "DButton", Menubg )
	OpenBrowser:SetText( PlayMLanguage.Add )			
	OpenBrowser:SetSize( 60, 30 )
	OpenBrowser:SetPos( (MenuPanel:GetWide() - OpenBrowser:GetWide()) * 0.5, (MenuPanel:GetTall() - OpenBrowser:GetTall()) *0.7 )			
	OpenBrowser.DoClick = function()
		local Value = TextEntry:GetValue()
		MenuPanel:Close()
		MPlayM.Save_Music_List(Value, true)
	end
	
	
end

function MPlayM.openSystemOptions()
	local OptionWindow = vgui.Create( "DFrame" )
	OptionWindow:SetSize( 310, 150)
	OptionWindow:Center()
	OptionWindow:SetTitle( PlayMLanguage.playerOptions )
	OptionWindow:SetIcon( "icon16/wrench.png" )
	OptionWindow:SetDraggable( false )
	OptionWindow:MakePopup()
	OptionWindow:SetSkin( "Default" )
	
	local OptionWindowbg = vgui.Create( "DPanel", OptionWindow )
	OptionWindowbg:Dock( FILL )
	OptionWindowbg:SetBackgroundColor( Color( 50, 50, 50, 255 ) )
	
	local SHOWVIDEO = vgui.Create( "DCheckBoxLabel", OptionWindow ) 
	SHOWVIDEO:SetParent( OptionWindow )
	SHOWVIDEO:SetPos( 25, 50 )				
	SHOWVIDEO:SetText( PlayMLanguage.DisplaystheVideoonyourscreen )	
	SHOWVIDEO:SetValue( MPlayM.Tog_VideoShow )
	SHOWVIDEO:SizeToContents()
	
	function SHOWVIDEO:OnChange( val )
			if MPlayM.Tog_VideoShow == true then
				MPlayM.Tog_VideoShow = false
				html:SetPaintedManually(true)
			else
				MPlayM.Tog_VideoShow = true
				html:SetPaintedManually(false)
			end
			MPlayM.Write_LocalUserData()
	end
	
	local SHOWHUD = vgui.Create( "DCheckBoxLabel", OptionWindow ) 
	SHOWHUD:SetParent( OptionWindow )
	SHOWHUD:SetPos( 25, 70 )				
	SHOWHUD:SetText( PlayMLanguage.DisplayHUDonyourscreen )	
	SHOWHUD:SetValue( MPlayM.HUD_Show )
	SHOWHUD:SizeToContents()
	
	function SHOWHUD:OnChange( val )
		if MPlayM.HUD_Show then
			timer.Simple( 2, function() MPlayM.HUD_Show = false MPlayM.Write_LocalUserData() end)
			MPlayM.Do_fade = false
		else
			MPlayM.HUD_Show = true
			MPlayM.Do_fade = true
		end
		MPlayM.Write_LocalUserData()
	end
	
	local NOPLAY = vgui.Create( "DCheckBoxLabel", OptionWindow ) 
	NOPLAY:SetParent( OptionWindow )
	NOPLAY:SetPos( 25, 90 )				
	NOPLAY:SetText( PlayMLanguage.Noplaymusicalways )	
	NOPLAY:SetValue( MPlayM.noPlay_tog )
	NOPLAY:SizeToContents()
	
	function NOPLAY:OnChange( val )
		if MPlayM.noPlay_tog then
			MPlayM.noPlay_tog = false
		else
			MPlayM.noPlay_tog = true
		end
		MPlayM.Write_LocalUserData()
	end
	
	local NOTY = vgui.Create( "DCheckBoxLabel", OptionWindow ) 
	NOTY:SetParent( OptionWindow )
	NOTY:SetPos( 25, 110 )				
	NOTY:SetText( PlayMLanguage.DisplaytheinformationUIonthescreen )
	NOTY:SetValue( MPlayM.noNOTY_tog )
	NOTY:SizeToContents()
	
	function NOTY:OnChange( val )
		if MPlayM.noNOTY_tog then
			MPlayM.noNOTY_tog = false
		else
			MPlayM.noNOTY_tog = true
		end
		MPlayM.Write_LocalUserData()
	end

end

function openWindowUI_Noty(PanelTitle, PanelLable)
	local Window = vgui.Create( "DFrame" )
	Window:SetSize( 640, 270 )
	Window:Center()
	Window:SetTitle( PanelTitle )
	Window:SetIcon( "html/img/viewonline.png" )
	Window:SetDraggable( false )
	Window:MakePopup()
	Window:SetSkin( "Default" )
	
	local Windowbg = vgui.Create( "DPanel", Window )
	Windowbg:Dock( FILL )
	Windowbg:SetBackgroundColor( Color( 50, 50, 50, 255 ) )
	
	local Windowlb = vgui.Create( "DLabel", Windowbg )
	Windowlb:SetPos(10,10)
	Windowlb:SetSize( 610, 170 )
	Windowlb:SetTextColor( Color( 240, 240, 230 ) )
	Windowlb:SetWrap( true )
	Windowlb:SetText( PanelLable )
	
	local DermaButton = vgui.Create( "DButton", Windowbg ) 
	DermaButton:SetText( PlayMLanguage.OK )			
	DermaButton:SetSize( 60, 30 )
	DermaButton:SetPos( (Window:GetWide() - DermaButton:GetWide()) * 0.5, (Window:GetTall() - DermaButton:GetTall()) *0.8 )			
	DermaButton.DoClick = function()
		Window:Close()
	end
	
end

function openUrlInputWindow()

	local MenuPanel = vgui.Create( "DFrame" )
	MenuPanel:SetSize( 640, 190 )
	MenuPanel:Center()
	MenuPanel:SetTitle( PlayMLanguage.PlayToYouTubeURL )
	MenuPanel:SetDraggable( false )
	MenuPanel:MakePopup()
	MenuPanel:SetSkin( "Default" )
	
	local Menubg = vgui.Create( "DPanel", MenuPanel )
	Menubg:Dock( FILL )
	Menubg:SetBackgroundColor( Color( 50, 50, 50, 255 ) )
	
	local UrlInput = vgui.Create( "DLabel", Menubg )
	UrlInput:SetPos(25,10)
	UrlInput:SetSize( 500, 30 )
	UrlInput:SetTextColor( Color( 240, 240, 230 ) )
	UrlInput:SetWrap( true )
	UrlInput:SetText( PlayMLanguage.EntertheURLhereorsearch )
	
	local TextEntry = vgui.Create( "DTextEntry", Menubg ) -- create the form as a child of frame
	TextEntry:SetPos( 25, 50 )
	TextEntry:SetSize( 580, 25 )
	TextEntry:SetText( "" )
	TextEntry.OnEnter = function( self )
	
		local Value = self:GetValue()
		
		MenuPanel:Close()
		MPlayM.UrlProcessing(Value)
		end
		
		local OpenBrowser = vgui.Create( "DButton", Menubg )
		OpenBrowser:SetText( PlayMLanguage.Search )			
		OpenBrowser:SetSize( 60, 30 )
		OpenBrowser:SetPos( (MenuPanel:GetWide() - OpenBrowser:GetWide()) * 0.5 - 35, (MenuPanel:GetTall() - OpenBrowser:GetTall()) *0.7 )			
		OpenBrowser.DoClick = function()
			MPlayM.OpenYoutubeBrowser()
			MenuPanel:Close()
		end
		
		local OpenBrowser = vgui.Create( "DButton", Menubg )
		OpenBrowser:SetText( PlayMLanguage.play )			
		OpenBrowser:SetSize( 60, 30 )
		OpenBrowser:SetPos( (MenuPanel:GetWide() - OpenBrowser:GetWide()) * 0.5 + 35, (MenuPanel:GetTall() - OpenBrowser:GetTall()) *0.7 )			
		OpenBrowser.DoClick = function()
			local Value = TextEntry:GetValue()
			
			MPlayM.UrlProcessing(Value)
			MenuPanel:Close()
		end
end

function MPlayM.UrlProcessing(Value)

	if string.Left(Value, 32) == "https://www.youtube.com/watch?v=" or string.Left(Value, 17) == "https://youtu.be/" then
			
		MPlayM.n(PlayMLanguage.preparePlay .. Value)
		MPlayM.address = Value
					
		if MPlayM.address == "Error" then
			MPlayM.err(PlayMLanguage.error_processingURL)
			openWindowUI_Noty(PlayMLanguage.Failedtoplaymusic, PlayMLanguage.error_processingURL)
			MPlayM.Do_fade = false
			MPlayM.playing = false
			MPlayM.Music = ""
		else
			net.Start("PlayM_netPlay")
			net.WriteString(MPlayM.address)
			net.WriteString("Play")
			net.WriteEntity(ply)
			net.SendToServer()
						
		end
					
	else
		MPlayM.n(Value .. PlayMLanguage.isNotAValidAddress)
		openWindowUI_Noty(PlayMLanguage.Failedtoplaymusic, Value .. PlayMLanguage.isNotAValidAddress)
	end
end

function MPlayM.OpenYoutubeBrowser()
	local YoutubeBrowserWindow = vgui.Create( "DFrame" )
	YoutubeBrowserWindow:SetSize( ScrW() * 0.6, ScrH() * 0.6 )
	YoutubeBrowserWindow:Center()
	YoutubeBrowserWindow:SetTitle( PlayMLanguage.Browser )
	YoutubeBrowserWindow:SetDraggable( false )
	YoutubeBrowserWindow:MakePopup()
	YoutubeBrowserWindow:SetSkin( "Default" )
	
	local YoutubeBrowserPanel = vgui.Create( "DPanel", YoutubeBrowserWindow )
	YoutubeBrowserPanel:Dock( FILL )
	
	local YoutubeBrowser = vgui.Create( "DHTML", YoutubeBrowserPanel )
	YoutubeBrowser:OpenURL("https://www.youtube.com/")
	YoutubeBrowser:SetSize( YoutubeBrowserWindow:GetWide() - 10, YoutubeBrowserWindow:GetTall() - 70 )
	
	local ctrls = vgui.Create( "DHTMLControls", YoutubeBrowserPanel )
	ctrls:SetWide( YoutubeBrowserWindow:GetWide() - 210 )
	ctrls:SetPos( 0,0 )
	ctrls:SetHTML( YoutubeBrowser )
	ctrls.AddressBar:SetText( "https://www.youtube.com/" )
	
	local YoutubeBrowser_Play = vgui.Create( "DButton", YoutubeBrowserPanel ) 
	YoutubeBrowser_Play:SetText( PlayMLanguage.play )
	YoutubeBrowser_Play:SetPos( ctrls:GetWide(), 0 )
	YoutubeBrowser_Play:SetSize( 60, 36 )
	YoutubeBrowser_Play.DoClick = function()
		net.Start("PlayM_netPlay")
			net.WriteString(MPlayM.YoutubeBrowser_URL)
			net.WriteEntity(LocalPlayer())
		net.SendToServer()
		YoutubeBrowserWindow:Close()
	end
	
	local YoutubeBrowser_List = vgui.Create( "DButton", YoutubeBrowserPanel ) 
	YoutubeBrowser_List:SetText( PlayMLanguage.AddtoPlaylist )
	YoutubeBrowser_List:SetPos( ctrls:GetWide() + YoutubeBrowser_Play:GetWide(), 0 )
	YoutubeBrowser_List:SetSize( 140, 36 )
	YoutubeBrowser_List.DoClick = function()
		MPlayM.Save_Music_List(MPlayM.YoutubeBrowser_URL, true)
	end
	
	YoutubeBrowser:AddFunction("MinPlaymusic", "RequestURL", function(curl)
		ctrls.AddressBar:SetText(curl)
		print("url: " .. curl)
		
		if string.Left(curl, 32) == "https://www.youtube.com/watch?v=" then
			MPlayM.YoutubeBrowser_URL = curl
			YoutubeBrowser_Play:SetEnabled(true)
			YoutubeBrowser_List:SetEnabled(true)
		else
			YoutubeBrowser_Play:SetEnabled(false)
			YoutubeBrowser_List:SetEnabled(false)
		end
		
	end)
	
	YoutubeBrowser.OnChangeTitle = function() YoutubeBrowser:RunJavascript("MinPlaymusic.RequestURL(window.location.href);") end
	
	YoutubeBrowser:MoveBelow( ctrls )
	
end

function MPlayM.NotifyCenter(Message)

if not MPlayM.noNOTY_tog then return end

if MPlayM.PopupNotify < 0 then
	MPlayM.PopupNotify = 0
	MPlayM.NotifyCenter("Playmusic Noti Center Error! ['MPlayM.PopupNotify' is a negative quantity.]")
	return
elseif MPlayM.PopupNotify == 0 then
	timer.Simple( 8, function() MPlayM.PopupNotify = 0 end)
end

MPlayM.PopupNotify = MPlayM.PopupNotify + 1


NotifyPanel = vgui.Create( "DNotify" )
NotifyPanel:SetPos( ScrW() - 600, ScrH() - 180 - (MPlayM.PopupNotify * 40) )
NotifyPanel:SetSize( 550, 35 )
NotifyPanel:SetLife( 8 )
NotifyPanel:SetSkin( "Default" ) 

local bg = vgui.Create( "DPanel", NotifyPanel )
bg:Dock( FILL )
bg:SetBackgroundColor( Color( 50, 50, 50, 160 ) )

local lbl = vgui.Create( "DLabel", bg )
lbl:SetPos( 10, 7 )
lbl:SetSize( 540, 28 )
lbl:SetText( Message )
lbl:SetTextColor( Color( 240, 240, 230 ) )
lbl:SetFont( "MinPlaymusic_Title" )
lbl:SetWrap( false )

NotifyPanel:AddItem( bg )

end

function PlayM_TimesThink()

	if MPlayM.playing then
		
			if MPlayM.noPlay_tog then return end

			MPlayM.Times = CurTime() - MPlayM.StartTime
			
			MPlayM.Do_reload = CurTime() - StartTime_Reload

	
	if math.floor(MPlayM.Do_reload) == 60 then
		MPlayM.Re_loading = true
		StartTime_Reload = CurTime()
		MPlayM.Do_reload = 0
		MPlayM.Loading_Finished = false
		
		MPlayM.checkPlayerState()
		
		MPlayM.Music = PlayMLanguage.playerRef
		timer.Simple( 3, function() MPlayM.Music = MPlayM.Vol_Music end )
		
	end
end

end
hook.Add("Think", "PlayM_TimesThink", PlayM_TimesThink)


function MPlayM.PlayM_Play(URI)

	MPlayM.URI = URI

	MPlayM.pause = false

	timer.Simple( 0.5, function() if MPlayM.titleText == nil or MPlayM.Length == 0 then
			MPlayM.Music = PlayMLanguage.Theserverwasnotrespondingcorrectly .. "(Target:" .. MPlayM.URI .. ")"
			MPlayM.err(PlayMLanguage.Theserverwasnotrespondingcorrectly .. "(Target:" .. MPlayM.URI .. ")")
			return
		else
			if MPlayM.noPlay_tog then 
				MPlayM.n(PlayMLanguage.NoPlayisenabled) 
				MPlayM.NotifyCenter(PlayMLanguage.NoPlayisenabled) 
				MPlayM.New_Connect = false
			return end
			
			MPlayM.Do_setPlayer = true
		
			if string.len(MPlayM.titleText) > 60 then
				MPlayM.Music = string.Left(MPlayM.titleText, 60) .. "..."
			elseif (ScrW() <= 1360) and (ScrH() <= 768) and string.len(MPlayM.titleText) > 50 then
				MPlayM.Music = string.Left(MPlayM.titleText, 50) .. "..."
			else
				MPlayM.Music = MPlayM.titleText
			end
			
			MPlayM.Vol_Music = MPlayM.Music
			
			MPlayM.Do_fade = true
			timer.Simple( 2, function() MPlayM.playing = true end)
			
			if MPlayM.New_Connect then
				
				MPlayM.Loading_Finished = false
				
				MPlayM.checkPlayerState()
				

				StartTime_Reload = CurTime()
				MPlayM.n(PlayMLanguage.Thissongisplaying .. MPlayM.titleText)
				MPlayM.NotifyCenter(PlayMLanguage.Thissongisplaying .. MPlayM.titleText)
				MPlayM.New_Connect = false
				MPlayM.Do_setPlayer = true
				MPlayM.Re_loading = true
			
			else
			
				MPlayM.Loading_Finished = false
				
				MPlayM.checkPlayerState()
				
				MPlayM.StartTime = CurTime() + 2
				StartTime_Reload = CurTime() + 2
				
				MPlayM.NotifyCenter(PlayMLanguage.Playing .. MPlayM.titleText)
			end
			
	end end)
		
end

function MPlayM.PlayM_Stop()
	if not MPlayM.playing then
		MPlayM.n(PlayMLanguage.Nosongisplaying)
		MPlayM.NotifyCenter(PlayMLanguage.Nosongisplaying)
		MPlayM.Do_fade = false
		MPlayM.playing = false
		html:SetHTML("") 
		MPlayM.Do_setPlayer = false
	else
		MPlayM.n(PlayMLanguage.Stopmusic)
		MPlayM.NotifyCenter(PlayMLanguage.Stopmusic)
		MPlayM.playing = false
		MPlayM.Do_fade = false
		MPlayM.Length = 0
		MPlayM.Times = 0
		html:SetHTML("")
		MPlayM.PlayingUser = "nil"
		MPlayM.Do_setPlayer = false
	end
	
	PlayingUserName = nil
end

MPlayM.err = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MPlayM.LastMessage = text
	text = "[PlayMusic Error] " .. text
	chat.AddText(text)
end

MPlayM.n = function(text)
	text = (sender and (sender .. " @ ") or "") .. text
	MPlayM.LastMessage = text
	text = "[PlayMusic] " .. text
	chat.AddText(text)
end

MsModules.CallPlaymusic = function(text)

	if string.Left(text, 3) == "#pm" then
		return true
	elseif string.Left(text, 10) == "#playmusic" then
		return true
	end
end

MsModules.ExtractCommandArgs = function(text)
	
	if string.Left(text, 3) == "#pm" then
		if string.len(text) <= 3 then
			return "", ""
		end
	elseif string.Left(text, 10) == "#playmusic" then
		if string.len(text) <= 10 then
			return "", ""
		end
	end
	
	local exploded = string.Explode(" ", text)
	table.remove(exploded, 1)
	local command = exploded[1]
	table.remove(exploded, 1)
	local args = table.concat(exploded, " ")
	
	return command, args
end

net.Receive("PlayM_netPlay",function(len)

	MPlayM.URI = net.ReadString()
	ChannelTitle = net.ReadString()
	MPlayM.titleText = net.ReadString()
	MPlayM.Length = net.ReadString()
	MPlayM.PlayingUserID = net.ReadString()
	MPlayM.ImageUrl = net.ReadString()
	MPlayM.PlayM_Play(MPlayM.URI)
	
end)

net.Receive("PlayM_netStop",function(len)

	MPlayM.StopUser = net.ReadEntity()
	MPlayM.StopUserID = MPlayM.StopUser:SteamID()
	
	if MPlayM.PlayingUserID == MPlayM.StopUserID then
		MPlayM.n(PlayMLanguage.musicwasstoppedby .. MPlayM.StopUser:Nick())
		MPlayM.NotifyCenter(PlayMLanguage.musicwasstoppedby .. MPlayM.StopUser:Nick())
		MPlayM.PlayM_Stop()
	elseif MPlayM.StopUser:IsAdmin() then
		MPlayM.n(PlayMLanguage.musicwasstoppedby .. "[administrator]")
		MPlayM.NotifyCenter(PlayMLanguage.musicwasstoppedby .. "[administrator]")
		MPlayM.PlayM_Stop()
	else
		MPlayM.err("PlayM_netStop: 잘못된 요청입니다. 요청한 플레이어( ID: " .. MPlayM.StopUserID .. ")가 MPlayM.PlayingUser( ID: " .. MPlayM.PlayingUserID .. ") 이거나 관리자 권한이 있어야 합니다.")
		MPlayM.NotifyCenter("PlayM_netStop: 잘못된 요청입니다. 요청한 플레이어( ID: " .. MPlayM.StopUserID .. ")가 MPlayM.PlayingUser( ID: " .. MPlayM.PlayingUserID .. ") 이거나 관리자 권한이 있어야 합니다.")
		MPlayM.PlayM_Stop()
	end
end)

net.Receive("PlayM_End",function(len)
	MPlayM.n(PlayMLanguage.Stopmusic)
	MPlayM.NotifyCenter(PlayMLanguage.Stopmusic)
		MPlayM.playing = false
		MPlayM.Do_fade = false
		MPlayM.Length = 0
		MPlayM.Times = 0
		html:SetHTML("")
		MPlayM.PlayingUser = "nil"
		MPlayM.Do_setPlayer = false
end)

net.Receive("PlayM_New_Connect",function(len)

	if MPlayM.New_Connect == nil then
		MPlayM.New_Connect = true

		MPlayM.URI = net.ReadString()
		ChannelTitle = net.ReadString()
		MPlayM.titleText = net.ReadString()
		MPlayM.Length = net.ReadString()
		MPlayM.Play_Time = net.ReadString()
		MPlayM.StartTime = net.ReadString()
		MPlayM.ImageUrl = net.ReadString()
		
		MPlayM.Times = MPlayM.Play_Time
	
		MPlayM.PlayM_Play(MPlayM.URI)
	
	end
end)

concommand.Add( "playmusic_stop", function()
	MPlayM.PlayM_Stop()
end)

concommand.Add( "playmusic_showvideo", function()
	if not MPlayM.Tog_VideoShow then
		html:SetPos(ScrW() / 3 - 106,0)
		html:SetSize(106,60)
		html:SetPaintedManually(false)
		MPlayM.n(PlayMLanguage.Nowdisplaythevideo)
		MPlayM.NotifyCenter(PlayMLanguage.Nowdisplaythevideo)
		MPlayM.Tog_VideoShow = true
		MPlayM.Write_LocalUserData()
	else
		html:SetPos(ScrW() / 3 - 106,0)
		html:SetSize(106,60)
		html:SetPaintedManually(true)
		MPlayM.n(PlayMLanguage.Nownodisplaythevideo)
		MPlayM.NotifyCenter(PlayMLanguage.Nownodisplaythevideo)
		MPlayM.Tog_VideoShow = false
		MPlayM.Write_LocalUserData()
	end
end)

concommand.Add( "playmusic_reload", function()
	if MPlayM.playing then
		MPlayM.Re_loading = true
		html:SetHTML("") 
		MPlayM.Loading_Finished = false
		
		MPlayM.checkPlayerState()

		MPlayM.n(PlayMLanguage.playerRef)
		MPlayM.Music = PlayMLanguage.playerRef
		MPlayM.NotifyCenter(PlayMLanguage.playerRef)
		timer.Simple( 5, function() MPlayM.Music = MPlayM.Vol_Music end )

	else
		MPlayM.n(PlayMLanguage.youcantdoit)
		MPlayM.NotifyCenter(PlayMLanguage.youcantdoit)
	end
end)

concommand.Add( "playmusic_hud", function()
	if MPlayM.HUD_Show then
		MPlayM.n(PlayMLanguage.hideHUD)
		MPlayM.NotifyCenter(PlayMLanguage.hideHUD)
		timer.Simple( 2, function() MPlayM.HUD_Show = false MPlayM.Write_LocalUserData() end)
		MPlayM.Do_fade = false
	else
		MPlayM.n(PlayMLanguage.showHUD)
		MPlayM.NotifyCenter(PlayMLanguage.showHUD)
		MPlayM.HUD_Show = true
		MPlayM.Do_fade = true
		MPlayM.Write_LocalUserData()
	end
end)

concommand.Add( "playmusic_help", function()
	print(PlayMLanguage.PlaymusicConsoleCommandList)
	print("playmusic_stop : " .. PlayMLanguage.Stopmusic_Appliestoselfonly)
	print("playmusic_showvideo : " .. PlayMLanguage.Showsorhidesthevideo)
	print("playmusic_reload : " .. PlayMLanguage.RefreshthePlayer)
	print("playmusic_hud : " .. PlayMLanguage.HidesorshowstheHUD)
	print("playmusic_openmenu : " .. PlayMLanguage.OpenthePlayMusicControlCenter)
end)

print("[Playmusic] Client - complete!")