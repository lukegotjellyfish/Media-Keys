﻿;//SECTION Options
#NoEnv
#SingleInstance, Force
#Persistent
#MaxThreadsPerHotkey, 1
Process, Priority,, High
SetBatchLines, -1
SendMode Input
SetWorkingDir %A_ScriptDir%
SetKeyDelay,-1, 1
SetControlDelay, -1
SetMouseDelay, -1
SetWinDelay,-1
ListLines, Off
CoordMode, Mouse, Client
OnExit(ObjBindMethod(exitclass,"DoBeforeExit"))
;//!SECTION options


;//SECTION Hotkey list
;"/(!)<name>" are bookmarks (from a VS Code extension) in the code to be navigated with via:
;  https://marketplace.visualstudio.com/items?itemName=ExodiusStudios.comment-anchors
;
;    #========================================#
;    |                 Hotkeys                |
;    #========================================#
;    |                                        |
;    | [Gui Movement]                         |
;    | ^PgUp - Move GUI Up screen             |
;    | ^PgDn - Move GUI Down screen           |
;    | ^Del  - Move GUI to left of screen     |
;    | ^End  - Move GUI to right of screen    |
;    | ^Home - Reset GUI to starting pos      |
;    |                                        |
;    | [Media Functions]                      |
;    | Numpad4 - Previous song                |
;    | Numpad5 - Pause/Play                   |
;    | Numpad6 - Next song                    |
;    | Numpad8 - Foobar| volume up            |
;    | Numpad2 - Foobar| volume down          |
;    |                                        |
;    | [Misc Keys]                            |
;    | F3 - Reload                            |
;    |                                        |
;    #========================================#
;
;//!SECTION Hotkey list


;//SECTION Vars
appname          := "foobar2000"
exename          := "foobar2000.exe"
idlename         := "foobar2000 v1.4.3"
stripsongnameend := "[foobar2000]"  ;Remove textstamp from what will be displayed

colour_change_delay  = 100
control_send_sleep   = 200
song_check_timer     = 200

song_time            = 0
song_time_m          = 0
song_time_s          = 0

gui_transparency     = 220  ;/255
font_colour_one     := "White"
font_colour_two     := "FF89F1"  ;pnk
playingstring       := "||"
pausedstring        := "▶️"
prev                := "<"
next                := ">"

nircmd_dir          := A_ScriptDir . "\nircmd\nircmd.exe"  ;Get: http://www.nirsoft.net/utils/nircmd.html
;//!SECTION Vars


;//SECTION Get Foobar and nircmd
;##################################################################################
;                       Initial process for CheckSongName
;##################################################################################
WinGet, win, List
Loop, %win%
{
    WinGetTitle, title, % "ahk_id" . win%A_Index%
    WinGet, spot_name, ProcessName, %title%
    if (spot_name = exename)  ;find foobar window
    {
        WinGet, foobar, ID, %title%
        break
    }
}

SetTimer, CheckSongName, %song_check_timer%  ;Find if a song is already playing

global volume
if (FileExist(appname . "_volume.txt"))
{
    FileRead, readfile, % appname . "_volume.txt"
    readfile := StrSplit(readfile, ",")
    volume := readfile[1]
    volume_increment = readfile[2]

    if (readfile[3] and readfile[4])
    {
        global gui_x := readfile[3]
        global gui_y := readfile[4]
    }
    else
    {
        global gui_x = 0
        global gui_y = 600
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
    else if (volume_increment > 100) || (ErrorLevel)
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
; -Caption     - Don't include window title
; +E0x20       - Don't register clicks on window
Gui, Margin, 0, 0
Gui, Color, Black

;//ANCHOR Prev-PAUSE-Next
Gui, Font, c%font_colour_one% s60 q4 bold, Arial
Gui, Add, Text, x05 y00 w54 h80 vprev BackgroundTrans, %prev%
Gui, Add, Text, x69 y-05 w66 h100 vpauseplay BackgroundTrans, %pausedstring%
Gui, Add, Text, x141 y00 w54 h80 vnext BackgroundTrans, %next%

;//ANCHOR Volume
Gui, Font, c%font_colour_one% s14 q4 bold, Arial
Gui, Add, Text, x236 y32 vvol_up, + %volume_increment%
Gui, Add, Text, x236 y54 vvol_down, -  %volume_increment%
Gui, Font, c%font_colour_two% s12 q4 bold, Arial
Gui, Add, Text, x252 y10 w46 vvolume, %volume%`%

;//ANCHOR Timer
Gui, Font, c%font_colour_two% s14 q4, Consolas
Gui, Add, Text, x226 y80 w70 vtimer BackgroundTrans +border, 0:00

;//ANCHOR Nowplaying status
Gui, Font, c%font_colour_one% s10 q4 bold, Arial
Gui, Add, Text, x005 y105 BackgroundTrans, Now Playing:
Gui, Font, c%font_colour_two%
Gui, Add, Text, x005 y121 w288 h50 vsongtitle BackgroundTrans, `

;//ANCHOR Gui Show
WinSet, Transparent, %gui_transparency%
Gui, Show, x%gui_x% y%gui_y% h170 w300 NoActivate

div_vol := (volume / 100)
Run, %nircmd_dir% setappvolume %exename% %div_vol%  ;Match with script's volume seting (0.5) to perform on
return
;//!SECTION


;//SECTION Hotkeys
^Home::
{
    gui_y := 600
    gui_x := 0
    Gui, Show, x%gui_x% y%gui_y% NoActivate
}
return

^PgUp::  ;//ANCHOR PgUp
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

^PgDn::  ;//ANCHOR PgDn
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

^End::  ;//ANCHOR End
{
    while (GetKeyState("End", "P"))
    {
        if (gui_X < 1620)
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

*NumpadLeft::
*Numpad4::  ;//ANCHOR Numpad4
{
    Send, {Media_Prev}
    song_time := 0
    song_time_m = 0
    song_time_s = 0
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


*NumpadClear::
*Numpad5::  ;//ANCHOR Numpad5
{
    Send, {Media_Play_Pause}

    if (playing_status = 1)
    {
        playing_status = 0
        playpausestring := pausedstring
        SetTimer, Record_Time, OFF
    }
    else
    {
        playing_status = 1
        playpausestring := playingstring
    }

    GuiControl,, pauseplay, %playpausestring%
    ItemActivated(font_colour_two, "60", "pauseplay", font_colour_one)
    Sleep, 10  ;prevents the wrong symbol being displayed
}
return


*NumpadRight::
*Numpad6::  ;//ANCHOR Numpad6
{
    Send, {Media_Next}
    song_time := 0
    song_time_m = 0
    song_time_s = 0
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


F3::  ;//ANCHOR F3
{
    reload
    Sleep, 100  ;avoids multiple GUIs being created....yeah
}
return


;//!SECTION


;//SECTION Labels/Subs, Functions
CheckSongName:  ;//ANCHOR CheckSongName
{
    WinGetTitle, SongName, ahk_id %foobar%
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
        last_song := prev_SongName
        prev_SongName     := SongName
        SetTimer, Record_Time, OFF
    }
    else if (SongName != prev_SongName) and (SongName != idlename)  ;new song found
    {
        GuiControl,, songtitle, %SongName%
        GuiControl,, pauseplay, %playingstring%
        if (was_paused = 1)
        {
            was_paused = 0
        }
        ChangeAdded(0)
        prev_SongName     := SongName
        playing_status     = 1

        if (SongName != last_song)
        {
            song_time          = 0
            song_time_s        = 0
            song_time_m        = 0
            timed = 0
            SetTimer, Record_Time, 1000
            GuiControl,, timer, %song_time_m%:0%song_time_s%
        }
        else
        {
            SetTimer, Record_Time, ON
        }
    }
}
return

Record_Time:  ;//ANCHOR Timer procedure
{
    song_time += 1
    song_time_s += 1
    song_time_m := song_time // 60
    if (song_time_s = 60)
    {
        song_time_s = 0
    }
    if (song_time_s < 10)
    {
        song_time_s := 0 . song_time_s
    }
    GuiControl,, timer, %song_time_m%:%song_time_s%
}
return

ItemActivated(font_colour_two, font_size, control_name, font_colour_one)  ;/ANCHOR ItemActivated procedure
{
    Gui, Font, c%font_colour_two% s%font_size% q4 bold
    GuiControl, Font, %control_name%
    Sleep, 100
    Gui, Font, c%font_colour_one% s%font_size% q4 bold
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


savevol:  ;//ANCHOR SaveVol label
{
    FileDelete, %appname%_volume.txt
    FileAppend, %volume%, %appname%_volume.txt
    FileAppend, `,%volume_increment%, %appname%_volume.txt
    FileAppend, `,%gui_x%, %appname%_volume.txt
    FileAppend, `,%gui_y%, %appname%_volume.txt
}
return

class exitclass
{
    DoBeforeExit()
    {
        GoSub, savevol
    }
}

;//!SECTION
/*  //NOTE Notices
╔════════════════════════════════════════════════════════════════════════════════╗
║╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳║
╠════════════════════════════════════════════════════════════════════════════════╣
║    My Discord: Lukegotjellyfish#0473                                           ║
║    GitHub rep: https://github.com/lukegotjellyfish/Media-Keys                  ║
║    Copyright (C) 2019  Luke Roper                                              ║
╚════════════════════════════════════════════════════════════════════════════════╝
*/