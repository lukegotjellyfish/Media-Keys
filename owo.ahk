;//SECTION Options
#NoEnv
#SingleInstance, Force
#Persistent
#InstallKeybdHook
#InstallMouseHook
#KeyHistory, 0
#MaxThreadsPerHotkey, 1
Process, Priority,, High
SetBatchLines, -1
SendMode Input
SetWorkingDir %A_ScriptDir%
SetKeyDelay,5, 1
SetControlDelay, -1
SetMouseDelay, -1
SetWinDelay,-1
ListLines, Off
CoordMode, Mouse, Client
OnExit DoBeforeExit
;//!SECTION options


if (A_IsAdmin = 0)
{
	try
	{
		if (A_IsCompiled)
		{
			Run *RunAs "%A_ScriptFullPath%" /restart
		}
		else
		{
			Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
		}
	}
	ExitApp
}


;//SECTION Hotkey list
;"/(!)<name>" are bookmarks (from a VS Code extension) in the code to be navigated with via:
;  https://marketplace.visualstudio.com/items?itemName=ExodiusStudios.comment-anchors
;
;
;  SETUP:
;	Foobar2000
;	\ Preferences
;	  \ Components
;		\ Display
;		  \ Default User Interface
;			\ Playback state display formatting
;
;  Set the following three boxes to:
;	%title%
;	%codec% | %bitrate% kbps | %samplerate% Hz | %channels% | %playback_time%[ / %length%] | [%rating_stars_fixed%]
;	[%artist% - ]%title%
;  or alter the value of time_loc to the index of the time in the statusbar
;
;
;  Playback Statistics can be found here: (Rating stars)
;   - foobar2000.org/components/view/foo_playcount
;
;
;  Definitions: ^ = CTRL
;			   + = SHIFT
;
;
;	#========================================#
;	|				 Hotkeys				|
;	#========================================#
;	|										|
;	| [Gui Movement]						 |
;	| ^<Gui key> - Fast smooth move		  |
;	| +<Gui key> - Move					  |
;	| ^PgUp - Move GUI Up screen			 |
;	| ^PgDn - Move GUI Down screen		   |
;	| ^Del  - Move GUI to left of screen	 |
;	| ^End  - Move GUI to right of screen	|
;	| ^Home - Reset GUI to starting pos	  |
;	|										|
;	| [Media Functions]					  |
;	| Numpad4 - Previous song				|
;	| Numpad5 - Pause/Play				   |
;	| Numpad6 - Next song					|
;	| Numpad8 - Foobar volume up			 |
;	| Numpad2 - Foobar volume down		   |
;	|										|
;	| [Misc Keys]							|
;	| F3 - Reload							|
;	| ^F3 - Exit							 |
;	|										|
;	#========================================#
;
;  ^ = Left Control
;  + = Shift
;
;//!SECTION Hotkey list


;//SECTION Vars
global appname   := "foobar2000"
exename		  := "foobar2000.exe"
idlename		 := "foobar2000 v1.4.3"
classname		:= "{97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}"
stripsongnameend := "[foobar2000]"  ;Remove textstamp from what will be displayed
global time_loc  := 5
global rat_loc   := 6

global gui_x		 = 0
global gui_y		 = 600
colour_change_delay  = 100
control_send_sleep   = 200
song_check_timer	 = 200

gui_transparency	 = 220  ;/255
font_colour_one	 := "FFFFFF"  ;white
font_colour_two	 := "FF89f1"  ;pastel pink
global playingstring	:= "||"
global pausedstring		:= "||"
prev				:= "<"
next				:= ">"
nircmd_dir		  := A_ScriptDir . "\nircmd\nircmd.exe"  ;Get: http://www.nirsoft.net/utils/nircmd.html
;//!SECTION Vars


;//SECTION Get Foobar and nircmd
;##################################################################################
;					   Initial process for CheckSongName
;##################################################################################
SetTimer, CheckSongName, %song_check_timer%  ;Find if a song is already playing
SetTimer, CheckPlayingStatus, -0
SetTimer, UpdateRating, 500

global volume
if (FileExist(appname . "_volume.txt"))
{
	FileRead, readfile, % appname . "_volume.txt"
	readfile := StrSplit(readfile, ",")
	if (readfile.MaxIndex() = 4)
	{
		volume		   := readfile[1]
		volume_increment := readfile[2]
		gui_x			:= readfile[3]
		gui_y			:= readfile[4]
	}

	if (volume < 0)
	{
		volume = 0
	}
	else if (volume > 100)
	{
		volume = 100
	}
	else if (ErrorLevel) ;corrupted file, set volume to half
	{
		volume = 50
	}

	if (volume_increment < 0)
	{
		volume_increment = 5
	}
	else if ((volume_increment > 100) or (ErrorLevel))
	{
		volume_increment = 5
	}
}
;//!SECTION Get foobar and nircmd


;//SECTION GUI
;//ANCHOR GUI settings
Gui, +AlwaysOnTop +ToolWindow +LastFound -Caption +E0x20 ;+hwndGUI_Overlay_hwnd
; +AlwaysOnTop - Keep above windows
; +ToolWindow  - Don't show in taskbar
; +LastFound   - For transparency to work
; -Caption	 - Don't include window title
; +E0x20	   - Don't register clicks on window
Gui, Margin, 0, 0
Gui, Color, Black

;//ANCHOR Prev-PAUSE-Next
Gui, Font, c%font_colour_one% s60 q4 bold, Arial
Gui, Add, Text, x05 y00 w54 h80 vprev BackgroundTrans, %prev%
Gui, Add, Text, x69 y-05 w66 h100 vpauseplay, %pausedstring%
Gui, Add, Text, x141 y00 w54 h80 vnext BackgroundTrans, %next%

;//ANCHOR Volume
Gui, Font, c%font_colour_one% s24 q4 bold, Arial
Gui, Add, Text, x210 y20 w80 vvolume, %volume%`%

;//ANCHOR Timer
Gui, Font, c%font_colour_two% s14 q4, Consolas
Gui, Add, Text, x212 y60 w73 vtimer, 0:00

;//ANCHOR Nowplaying status
Gui, Font, c%font_colour_one% s10 q4 bold, Arial
Gui, Add, Text, x005 y95 BackgroundTrans, Now Playing:
Gui, Font, c%font_colour_two%
Gui, Add, Text, x005 y111 w288 h50 vsongtitle, `

;//ANCHOR Rating Status
Gui, Font, c%font_colour_two% s14 q4, Consolas
Gui, Add, Text, x197 y80 w70 vrating, uwu
Gui, Font, c%font_colour_one% s10 q4 bold, Arial

;//ANCHOR Gui Show
WinSet, Transparent, %gui_transparency%
Gui, Show, x%gui_x% y%gui_y% h170 w300 NoActivate

div_vol := (volume / 100)
Run, %nircmd_dir% setappvolume %exename% %div_vol%  ;Match with script's volume seting (0.5) to perform on
return
;//!SECTION


;//SECTION Hotkeys
;//SECTION GUI Hotkeys
^Home::  ;//ANCHOR Ctrl+Home
{
	gui_y := 600
	gui_x := 0
	Gui, Show, x%gui_x% y%gui_y% NoActivate
}
return


;//SECTION PgUp
^PgUp::  ;//ANCHOR Ctrl+PgUp
{
	while (GetKeyState("PgUp", "P"))
	{
		if (gui_y > 0)
		{
			gui_y -= 10
			Gui, Show, y%gui_y% NoActivate
			Sleep, 10
		}
		else
		{
			return
		}
	}
}
return


+PgUp::  ;//ANCHOR Shift+PgUp
{
	if (gui_y > 0)
	{
		gui_y -= 10
		Gui, Show, y%gui_y% NoActivate
		Sleep, 100
	}
	else
	{
		return
	}
}
return
;//!SECTION PgUp


;//SECTION PgDn
^PgDn::  ;//ANCHOR Ctrl+PgDn
{
	while (GetKeyState("PgDn", "P"))
	{
		if (gui_y < 910)
		{
			gui_y += 10
			Gui, Show, y%gui_y% NoActivate
			Sleep, 10
		}
		else
		{
			return
		}
	}
}
return


+PgDn::  ;//ANCHOR Shift+PgDn
{
	if (gui_y < 910)
	{
		gui_y += 10
		Gui, Show, y%gui_y% NoActivate
		Sleep, 10
	}
	else
	{
		return
	}
}
return
;//!SECTION PgDn


;//SECTION Del
^Del::  ;//ANCHOR Del
{
	while (GetKeyState("Del", "P"))
	{
		if (gui_x > 0)
		{
			gui_x -= 10
			Gui, Show, x%gui_x% NoActivate
			Sleep, 10
		}
		else
		{
			return
		}
	}
}
return


+Del::  ;//ANCHOR Shift+Del
{
	if (gui_x > 0)
	{
		gui_x -= 10
		Gui, Show, x%gui_x% NoActivate
		Sleep, 10
	}
	else
	{
		return
	}
}
return
;//!SECTION Del


;//SECTION End
^End::  ;//ANCHOR End
{
	while (GetKeyState("End", "P"))
	{
		if (gui_x < 1620)
		{
			gui_x += 10
			Gui, Show, x%gui_x% NoActivate
			Sleep, 10
		}
		else
		{
			return
		}
	}
}
return


+End::
{
	if (gui_x < 1620)
	{
		gui_x += 10
		Gui, Show, x%gui_x% NoActivate
		Sleep, 10
	}
	else
	{
		return
	}
}
return
;//!SECTION End
;//!SECTION GUI Hotkeys


;//SECTION Media Functions
$Media_Prev::
*NumpadLeft::
*Numpad4::  ;//ANCHOR Numpad4
{
	global playingstatuschanged := 1
	Send, {Media_Prev}
	GuiControl,, timer, 0:00
	if (playing_status = 0)
	{
		playing_status = 1
		GuiControl,, pauseplay, %playingstring%
	}
	SetTimer, CheckSongName, %song_check_timer%
	ItemActivated(font_colour_two, "60", "prev", font_colour_one)
}
return


$Media_Play_Pause::
*NumpadClear::
*Numpad5::  ;//ANCHOR Numpad5
{
	global playingstatuschanged := 1
	Send, {Media_Play_Pause}
	if (playing_status = 1)
	{
		playing_status = 0
		playpausestring := pausedstring
	}
	else
	{
		playing_status = 1
		playpausestring := playingstring
	}
	GuiControl,, pauseplay, %playpausestring%
	ItemActivated(font_colour_two, "60", "pauseplay", font_colour_one)
	Sleep, 10  ;prevents the wrong symbol being displayed
	SetTimer, CheckPlayingStatus, -0
}
return

$Media_Next::
*NumpadRight::
*Numpad6::  ;//ANCHOR Numpad6
{
	global playingstatuschanged := 1
	Send, {Media_Next}
	GuiControl,, timer, 0:00
	if (playing_status = 0)
	{
		playing_status = 1
		GuiControl,, pauseplay, %playingstring%
	}
	SetTimer, CheckSongName, %song_check_timer%
	ItemActivated(font_colour_two, "60", "next", font_colour_one)
}
return


*NumpadUp::
*Numpad8::  ;//ANCHOR Numpad8
{
	if (volume + volume_increment > 100)
	{
		volume = 100
		GuiControl,, volume, %volume%`%
	}
	else
	{
		volume += %volume_increment%
		GuiControl,, volume, %volume%`%
	}
	div_vol := (volume / 100)
	Run, %nircmd_dir% setappvolume %exename% %div_vol%
}
return


*NumpadDown::
*Numpad2::  ;//ANCHOR Numpad2
{
	if (volume - volume_increment < 0)
	{
		volume = 0
	}
	else
	{
		volume -= %volume_increment%
	}
	div_vol := (volume / 100)
	GuiControl,, volume, %volume%`%
	Run, %nircmd_dir% setappvolume %exename% %div_vol%
}
return


~Media_Stop::  ;//ANCHOR Media_Stop
{
	controltext := "0:00"
	GuiControl,, SongTitle, `
	GuiControl,, Timer, %controltext%
}
return
;//!SECTION Media Functions


;//SECTION Misc
F3::  ;//ANCHOR F3
{
	reload
	Sleep, 100  ;avoids multiple GUIs being created....yeah
}
return


^F3::ExitApp  ;//ANCHOR ^F3
;//!SECTION Misc
;//!SECTION Hotkeys


;//SECTION Labels/Subs, Functions
CheckSongName:  ;//ANCHOR CheckSongName
{
	WinGetTitle, SongName, ahk_class %classname%
	if InStr(SongName, "&")
	{
		SongName := RegExReplace(SongName, "&", "and")
	}

	SongName := StrSplit(SongName, stripsongnameend)
	SongName := SongName[1]

	if (SongName != prev_SongName) and (SongName = idlename)  ;no song playing
	{
		playing_status = 0
		GuiControl,, pauseplay, %pausedstring%
		last_song	 := prev_SongName
		prev_SongName := SongName
		SetTimer, Record_Time, 1000
	}
	else if (SongName != prev_SongName) and (SongName != idlename)  ;new song found
	{
		global playingstatuschanged := 1
		GuiControl,, songtitle, %SongName%
		GuiControl,, pauseplay, %playingstring%

		if (was_paused = 1)
		{
			was_paused = 0
		}

		ChangeAdded(0)
		prev_SongName := SongName
		playing_status = 1

		if (SongName != last_song)
		{
			SetTimer, Record_Time, 1000
		}
	}
}
return

CheckPlayingStatus:  ;ANCHOR CheckPlayingStatus
{
	Loop
	{
		timearray := []
		Loop, 3
		{
			ControlGetText, controltext, ATL:msctls_statusbar321, ahk_class %classname%
			controltext := StrSplit(controltext, " | ")
			controltext := StrSplit(controltext[time_loc], "/")[1]
			timearray.Push(controltext)
			Sleep, 1000
		}
		;for item in timearray
		;{
		;	MsgBox % item
		;}
		;MsgBox % playingstatuschanged
		if playingstatuschanged = 1
		{
			global playingstatuschanged = 0
			continue
		}
		if ((timearray[1] = timearray[2]) AND (timearray[2] = timearray[3])) ;paused
		{
			playing_status = 0
			GuiControl,, pauseplay, %pausedstring%
			last_song	 := prev_SongName
			prev_SongName := SongName
			SetTimer, Record_Time, 1000
			;MsgBox, paused
		}
		else
		{
			WinGetTitle, SongName, ahk_class %classname%
			if InStr(SongName, "&")
			{
				SongName := RegExReplace(SongName, "&", "and")
			}

			SongName := StrSplit(SongName, stripsongnameend)
			SongName := SongName[1]

			GuiControl,, songtitle, %SongName%
			GuiControl,, pauseplay, %playingstring%
			if (was_paused = 1)
			{
				was_paused = 0
			}

			ChangeAdded(0)
			prev_SongName := SongName
			playing_status = 1
			;MsgBox, playing
		}
	}
}


Record_Time:  ;//ANCHOR Timer
{
	ControlGetText, controltext, ATL:msctls_statusbar321, ahk_class %classname%
	controltext := StrSplit(controltext, " | ")
	controltext := StrSplit(controltext[time_loc], "/")[1]
	if (controltext > 0)
	{
		GuiControl,, timer, %controltext%
	}
}
return


ItemActivated(font_colour_two, font_size, control_name, font_colour_one)  ;/ANCHOR ItemActivated procedure
{
	Gui, Font, c%font_colour_two% s%font_size%
	GuiControl, Font, %control_name%
	Sleep, 100
	Gui, Font, c%font_colour_one% s%font_size%
	GuiControl, Font, %control_name%
}
return


ChangeAdded(added)  ;//ANCHOR ChangeAdded status
{
	if (added = 1)
	{
		Gui, Font, cFF69B4 s10 q4 bold
		GuiControl, Move, added, x248
		GuiControl,, added, [Added]
		GuiControl, Font, added
	}
	else
	{
		Gui, Font, cWhite s10 q4 bold
		GuiControl, Move, added, x223
		GuiControl,, added, [Not Added]
		GuiControl, Font, added
	}
}
return


UpdateRating:
{
	ControlGetText, controltext, ATL:msctls_statusbar321, ahk_class %classname%
	controltext := StrSplit(controltext, " | ")
	rating_stars := controltext[6]
	GuiControl,, rating, %rating_stars%
}
return

DoBeforeExit:
{
	Sleep, 100 ;seems to stop a file "_volume.txt" from being created :thonk:
	FileDelete, %appname%_volume.txt
	FileAppend, %volume%, %appname%_volume.txt
	FileAppend, `,%volume_increment%, %appname%_volume.txt
	FileAppend, `,%gui_x%, %appname%_volume.txt
	FileAppend, `,%gui_y%, %appname%_volume.txt
	FileSetAttrib, +H, %appname%_volume.txt
	;+H = hide file to try and prevent editing and take up less visual space
	ExitApp
}
return
;//!SECTION


/*  //NOTE Notices
╔════════════════════════════════════════════════════════════════════════════════╗
║╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳║
╠════════════════════════════════════════════════════════════════════════════════╣
║	My Discord: Lukegotjellyfish#0473										   ║
║	GitHub rep: https://github.com/lukegotjellyfish/Media-Keys				  ║
║	Copyright (C) 2019  Luke Roper											  ║
╚════════════════════════════════════════════════════════════════════════════════╝
*/