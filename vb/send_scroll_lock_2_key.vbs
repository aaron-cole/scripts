Set WshShell= CreateObject("WScript.Shell")
Do
WshShell.Sendkeys ("{SCROLLLOCK 2}")
WScript.Sleep(2*60*1000)
Loop