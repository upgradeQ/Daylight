# Fullscreen in game overlays, on screen display software and tools.

- Playclaw can draw these types of overlay : text, web browser, web cam, hardware stats etc...  
Text can be read from file, at 0.5 seconds interval, supports webcam input from obs virtual cam plugin.  
SDK for version 6 - https://github.com/CyberDemonLord/playclaw6-sdk  

- Rivatuner provides shared memory interface to draw text overlay.  
repo - https://github.com/upgradeQ/RTSSSharedMemoryPythonNET   

# Dual monitor/screen/display based overlay
OBS Studio supports sending preview to another monitor, so you can grab fullscreen application,  
typically a game, compose a scene with overlays, then send it RMB > Fullscreen project > Some monitor.  
This also can be used with single monitors, but its requires setting up a virtual(fake) monitor,  
for windows required steps described https://superuser.com/questions/62051/is-there-a-way-to-fake-a-dual-second-monitor  
http://dualmonitortool.sourceforge.net/ this software has these features:  
- send current application to second monitor - http://dualmonitortool.sourceforge.net/dmt_swapscreen.html
- lock mouse in one monitor - dualmonitortool.sourceforge.net/dmt_cursor.html  
To maximize preview performance, go to Settings > Video > FPS and set the Integral value to double your monitor's refresh rate (Hz).

# Directory listing 
- `/osu` - Check [`osu`](osu/osu.md) on how to play flashlight + hidden with overlaying transparent normal replay video.
- `/cheatengine` -  Output health value to txt file repeatedly and then using OBS scripting to set level of opacity filter according to HP value,[`cheatengine`](cheatengine/cheatengine.md)
- `pygame_overlay.py` - overlay for game OpenSpades running in windowed mode
- `overlay.ahk` - ahk script to set any window to be non clickable 
- `x11_pyqt_overlay.py` - creates overlay from any window on X11.
- `obs-desktop-hud.lua` - dwm based overlay for Windows 11 
