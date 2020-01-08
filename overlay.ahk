; changing window transparencies control+space
^SPACE::  Winset, Alwaysontop, , A
#WheelUp::  ; Increments transparency up by 3.375% (with wrap-around)
    DetectHiddenWindows, on
    WinGet, curtrans, Transparent, A
    if ! curtrans
        curtrans = 255
    newtrans := curtrans + 8
    if newtrans > 0
    {
        WinSet, Transparent, %newtrans%, A
    }
    else
    {
        WinSet, Transparent, OFF, A
        WinSet, Transparent, 255, A
    }
return
; non clickable /clicakble 
; alt x non clicakble
!x::
WinGet, currentWindow, ID, A
WinSet, ExStyle, +0x80020, ahk_id %currentWindow%
return
;get back
!z::
MouseGetPos,,, MouseWin ; Gets the unique ID of the window under the mouse
WinSet, ExStyle, -0x80020, ahk_id %currentWindow%
Return
; !c: : <del space
;MouseGetPos,,, MouseWin
;WinSet, Region, 50-0 W200 H250, ahk_id %MouseWin%
;Return
#WheelDown::  ; Increments transparency down by 3.375% (with wrap-around)
    DetectHiddenWindows, on
    WinGet, curtrans, Transparent, A
    if ! curtrans
        curtrans = 255
    newtrans := curtrans - 8
    if newtrans > 0
    {
        WinSet, Transparent, %newtrans%, A
    }
    ;else
    ;{
    ;    WinSet, Transparent, 255, A
    ;    WinSet, Transparent, OFF, A
    ;}
return

#o::  ; Reset Transparency Settings
    WinSet, Transparent, 255, A
    WinSet, Transparent, OFF, A
return
