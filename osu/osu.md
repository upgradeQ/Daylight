# Play osu over overlay (easily pass HD and or FL).  
  
## Requirements 
- OBS 
- Autohotkey **optional**
- Python 3 and mpv with scripting support **optional**
## Installation
* Install autohotkey(optional) , python 64 bit , [mpv 64 bit](https://sourceforge.net/projects/mpv-player-windows/files/64bit/mpv-x86_64-20200105-git-9eb3991.7z/download), [mpv-1.dll](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/mpv-dev-x86_64-20200105-git-9eb3991.7z/download) 64 bit (dev version)
* Place mpv.exe & mpv-1.dll  where is your python.exe  [details](https://github.com/jaseg/python-mpv#libmpv) , run `python -m pip install python-mpv keyboard`
* Record / find replay matching your screen resolution
## Methods 
**AHK and scripted video** `windows` - fullscreen transparent overlay  
1. Change replay recording  to `song_name.mp4`
2. Launch `python osu_overlay.py`, modify `p.time_pos` if needed. Keys are: `e` : pause , `1`: go to start of the song , `2`: fullscreen toggle 
3. Launch `overlay.ahk` Calibrate transparancy level of mpv player with `win+wheel up /down`, set it always on top with `control + space`, and `alt+x` to click through 
4. Now launch beatmap , pause mpv overlay by pressing `e` . Wait till songs stars,unpause overlay when game and replay matched.  
You may fail, so you need to restart replay and repeat again. Obviously you can't pause the game, it should run without lags , otherwise
overlay and the game  will not be synchronized.
#
**OBS version 25 and up** `crossplatform` - window or second monitor 
> Added Media source hotkeys to allow control of playback (stop/pause/play/restart) [cg2121]  
>    For now, these are just hotkeys. User interface for this is also planned for future updates  
[source](https://github.com/obsproject/obs-studio/releases/tag/25.0.0)
1. First of all , add hotkeys for play/pause (set same key) and for restart. 
2. Setup game capture and media source capture,add Color Correction filter and set opacity for **media source**
3. Project it to window or second screen 
4. same from previous method
#
**OBS and scripted media source** `crossplatform` - window or second monitor 
1. It is requires replay recording with max resolution for second screen or custom resolution for window projector.  
2. `1,2` steps from *AHK method*   
3. In OBS , create a new scene , add to sources mpv controlled replay, add to sources osu client,  
add Color Correction filter and set opacity to mpv source, project it to window or second screen 
4. same 
# Notes
replay recording with max resolution for second screen or custom resolution for window projector.  
With OBS you can tweak aspect ratio.  
pygame overlay requires ahk running under admin , so it's only `windows`