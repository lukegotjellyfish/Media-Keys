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

;//!SECTION options
;//SECTION Hotkey list
; Changing title for Foobar:
; File/Preferences/Display/Default User Interface (Change Window title's contents to %title%)
;"//(!)<name>" are bookmarks (from a VS Code extension):
;  https://marketplace.visualstudio.com/items?itemName=ExodiusStudios.comment-anchors
;
;
;
;    #===========================================#
;    |                 Hotkeys                   |
;    #===========================================#
;    |                                           |
;    | [Gui Movement]                            |
;    | ^PgUp - Move GUI Up screen                |
;    | ^PgDn - Move GUI Down screen              |
;    | ^Del  - Move GUI to left of screen        |
;    | ^End  - Move GUI to right of screen       |
;    |                                           |
;    | [Media Functions]                         |
;    | Numpad4 - Previous song                   |
;    | Numpad5 - Pause/Play                      |
;    | Numpad6 - Next song                       |
;    | Numpad8 - foobar2000| volume up           |
;    | Numpad2 - foobar2000| volume down         |
;    |                                           |
;    | [Misc Keys]                               |
;    | F3 - Reload                               |
;    |                                           |
;    #===========================================#
;//!SECTION Hotkey list
;//SECTION Vars
appname          := "foobar2000"
exename          := "foobar2000.exe"
idlename         := "foobar2000 v1.4.3"
stripsongnameend := "[foobar2000]"  ;Remove textstamp from what will be displayed

colour_change_delay  = 100
control_send_sleep   = 50
song_check_timer     = 400
counter              = 0

gui_x                = 0
gui_y                = 600
gui_transparency     = 220  ;/255
font_colour_one     := "White"
font_colour_two     := "FF69B4"  ;Hot Pink
playingstring       := "| |"
pausedstring        := "▶️"
prev                := "⏮"
next                := "⏭"

nircmd_dir          := A_ScriptDir . "\nircmd\nircmd.exe"  ;Get: http://www.nirsoft.net/utils/nircmd.html
;//!SECTION Vars
;//SECTION Get foobar2000 and nircmd
;##################################################################################
;                       Initial process for CheckSongName
;##################################################################################
WinGet, appid, ID, ahk_exe %exename%
SetTimer, CheckSongName, %song_check_timer%
if FileExist(nircmd_dir)
{
    nir_found = 1
    volume               = 0.5
    volume_increment     = 0.05
}
if !(nir_found)
{
    Hotkey, *Numpad8, OFF
    Hotkey, *Numpad2, OFF
}

;//!SECTION
;//SECTION GUI
Gui, +AlwaysOnTop +Owner +ToolWindow +LastFound -Caption +E0x20
Gui, Margin, 0, 0
Gui, Color, Black
Gui, Font, c%font_colour_one% s60 q4 bold, Arial
Gui, Add, Text, x05 y00 w54 h80 vprev, %prev%
Gui, Add, Text, x69 y00 w66 h100 vpauseplay, %pausedstring%

Gui, Add, Text, x141 y00 w54 h80 vnext, %next%
Gui, Font, s10 q4 bold, Arial

Gui, Font, c%font_colour_one% s14 q4 bold, Arial
Gui, Add, Text, x236 y29 vvol_up, + %volume_increment%
Gui, Add, Text, x236 y58 vvol_down, -  %volume_increment%

Gui, Font, c%font_colour_two% s12 q4 bold, Arial
Gui, Add, Text, x252 y10 w90 vvolume, 50`%


Gui, Font, c%font_colour_two% s12 q4, Consolas
Gui, Add, Text, x140 y90 w190 vtimer BackgroundTrans, `

Gui, Font, c%font_colour_one% s10 q4 bold, Arial
Gui, Add, Text, x005 y105 BackgroundTrans, Now Playing:

Gui, Font, c%font_colour_two%
Gui, Add, Text, x005 y121 w288 h50 vsongtitle BackgroundTrans, `


WinSet, Transparent, %gui_transparency%
Gui, Show, x%gui_x% y%gui_y% h170 w300 NoActivate

Run, %nircmd_dir% setappvolume %exename% %volume%  ;Match with script's volume seting (0.5) to perform on
return
;//!SECTION
;//SECTION Hotkeys
;//SECTION GUI
^PgUp::  ;//ANCHOR PgUp
{
    if (gui_y > 0)
    {
        gui_y -= 10
    }
    Gui, Show, y%gui_y% NoActivate
}
return

^PgDn::  ;//ANCHOR PgDn
{
    if (gui_y < 910)
    gui_y += 10
    Gui, Show, y%gui_y% NoActivate
}
return

^Del::  ;//ANCHOR Del
{
    if (gui_x > 0)
    {
        gui_x -= 10
    }
    Gui, Show, x%gui_x% NoActivate
}
return

^End::  ;//ANCHOR End
{
    if (gui_X < 1620)
    {
        gui_x += 10
    }
    Gui, Show, x%gui_x% NoActivate
}
return
;//!SECTION

*NumpadLeft::
*Numpad4::  ;//ANCHOR Numpad4
{
    Send, {Media_Prev}

    if (playing_status = 0)
    {
        playing_status = 1
        GuiControl,, pauseplay, %playingstring%
    }

    SetTimer, CheckSongName, -0
    SetTimer, CheckSongName, %song_check_timer%
    ItemActivated(font_colour_two, "60", "prev", font_colour_one, 0, 0)
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
    }
    else
    {
        playing_status = 1
        playpausestring := playingstring
    }

    GuiControl,, pauseplay, %playpausestring%
}
return


*NumpadRight::
*Numpad6::  ;//ANCHOR Numpad6
{
    Send, {Media_Next}

    if (playing_status = 0)
    {
        playing_status = 1
        GuiControl,, pauseplay, %playingstring%
    }

    ItemActivated(font_colour_two, "60", "next", font_colour_one, 0, 0)
    SetTimer, CheckSongName, -0
    SetTimer, CheckSongName, %song_check_timer%
}
return


*NumpadUp::
*Numpad8::  ;//ANCHOR Numpad8
{
    volume := Round(volume, 2)
    if (volume = 0.95)
    {
        volume = 1
        ItemActivated("808080", "14", "vol_up", "808080", 1, volume)
    }
    else if (volume != 1)
    {
        volume += %volume_increment%
        ItemActivated(font_colour_two, "14", "vol_up", font_colour_one, 1, volume)
    }
    Run, %nircmd_dir% setappvolume %exename% %volume%
}
return


*NumpadDown::
*Numpad2::  ;//ANCHOR Numpad2
{
    volume := Round(volume, 2)
    if (volume = 0.05)
    {
        volume = 0
        ItemActivated("808080", "14", "vol_down", "808080", 2, volume)
    }
    else if (volume != 0)
    {
        volume -= %volume_increment%
        ItemActivated(font_colour_two, "14", "vol_down", font_colour_one, 2 , volume)
    }
    Run, %nircmd_dir% setappvolume %exename% %volume%
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
    WinGetTitle, SongName, ahk_id %appid%
    SongName := StrSplit(SongName, stripsongnameend) ;foobar2000 only (appends to it's title)
    SongName := SongName[1]                        ;handing for ^this^

    if InStr(SongName, "&")
    {
        SongName := RegExReplace(SongName, "&", "and")
    }

    if (SongName != prev_SongName) and (SongName = idlename)  ;no song playing
    {
        Sleep, 100
        if (WinGetTitle, SongName, ahk_id %appid% = idlename)
        {
            playing_status = 0
            GuiControl,, pauseplay, %pausedstring%
            prev_SongName := SongName
        }
    }
    else if (SongName != prev_SongName) and (SongName != idlename)  ;new song found
    {
        GuiControl,, songtitle, %SongName%
        GuiControl,, pauseplay, %playingstring%
        if (was_paused = 1)
        {
            Sleep, 10
            was_paused = 0
        }
        prev_SongName     := SongName
        playing_status     = 1
    }
    if (playing_status = 1) and (SongName = prev_SongName) and (SongName != idlename)  ;time the current song
    {
        ControlGetText, controltext, ATL:msctls_statusbar321, ahk_exe foobar2000.exe
        controltext := StrSplit(controltext, " | ")
        tempp := controltext[5]
        GuiControl,, timer, %tempp%
    }
}
return


ItemActivated(font_colour_two, font_size, control_name, font_colour_one, mode, volume)  ;/ANCHOR ItemActivated
{
    if (mode = 0)
    {
        Gui, Font, c%font_colour_two% s%font_size% q4 bold
        GuiControl, Font, %control_name%

        Sleep, 100

        Gui, Font, c%font_colour_one% s%font_size% q4 bold
        GuiControl, Font, %control_name%
        return
    }
    else if (mode = 1)
    {

        if (volume = 0.05)
        {
            Gui, Font, cWhite s14 q4 bold
            GuiControl, Font, vol_down
        }

        Gui, Font, c%font_colour_one% s14 q4 bold
        GuiControl, Font, %control_name%
    }
    else  ;change vol down
    {
        if (volume = 0.95)
        {
            Gui, Font, cWhite s14 q4 bold
            GuiControl, Font, vol_up
        }

        Gui, Font, c%font_colour_one% s14 q4 bold
        GuiControl, Font, %control_name%
    }
    num := volume * 100
    num := Round(Num, 0)
    GuiControl,, volume, %num%`%
}
return


;//!SECTION
/* //NOTE Notices
╔════════════════════════════════════════════════════════════════════════════════╗
║╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳║
╠════════════════════════════════════════════════════════════════════════════════╣
║    My Discord: Lukegotjellyfish#0473                                           ║
║    GitHub rep: https://github.com/lukegotjellyfish/Media-Keys                  ║
║    Copyright (C) 2019  Luke Roper                                              ║
╚════════════════════════════════════════════════════════════════════════════════╝
*/