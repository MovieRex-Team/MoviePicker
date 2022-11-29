#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; https://github.com/jNizM/ahk_notepad-plus-plus 
; https://stackoverflow.com/questions/45466733/autohotkey-syntax-highlighting-in-notepad

^+!p::
	RoutineX()
	SetTimer, RoutineX, 60000
	;MyFunc(1,2, 3)
	return

RoutineX()
{
	Loop, 6
	{
		; MouseGetPos, x, y
		; msgBox, x = %x% - y = %y%
		mouseClick, Left
		MouseMove, 0, 50, 100, R
		Sleep, 1000 ; milliseconds
		MouseMove, 0, -50, 100, R
		Loop, 10
		{
			Send, {WheelDown}
			Sleep, 50
		}
	}
	
}

/*
MouseClickDrag, left, 0, 0, 100, 100, 100
*/


Esc::ExitApp
