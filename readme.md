# Daylight 
Play osu over overlay (easy pass HD and or FL).  
Using mpv API to control video , and python to control hotkeys.  
Easily control media source for use in OBS scene as overlay with mpv.  
# Requirements 
- Python 3
- OBS 
- _optional_ Autohotkey 
- mpv with scripting support
# Installation
* Install autohotkey(optional) , python 64 bit , [mpv 64 bit](https://sourceforge.net/projects/mpv-player-windows/files/64bit/mpv-x86_64-20200105-git-9eb3991.7z/download), [mpv-1.dll](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/mpv-dev-x86_64-20200105-git-9eb3991.7z/download) 64 bit (dev version)
* Place mpv.exe & mpv-1.dll  where is your python.exe  [details](https://github.com/jaseg/python-mpv#libmpv) , run `python -m pip install python-mpv keyboard`
* Record / find replay matching your screen resolution
# Usage 
**AHK method** `windows` - fullscreen transparent overlay  
1. Change replay recording  to `song_name.mp4`
2. Launch `python osu_overlay.py`, modify `p.time_pos` if needed. Keys are: `e` : pause , `1`: go to start of the song , `2`: fullscreen toggle 
3. Launch `overlay.ahk` Calibrate transparancy level of mpv player with `win+wheel up /down`, set it always on top with `control + space`, and `alt+x` to click through 
4. Now launch beatmap , pause mpv overlay by pressing `e` with approaching circle, wait till songs stars,unpause and  hit circle.
---
**OBS Projector method** `crossplatform` - window / second monitor with game capture and overlay over it 

1. It is requires replay recording with max resolution for second screen or custom resolution for window projector.  
2. `1,2` steps from *AHK method*   
3. OBS steps:
    * create a new scene
    * add to sources mpv controlled replay
    * add to sources osu client
    * create overlay with it (set transparancy level)
    * project it to window or second screen 
4. And last one is just  `4` step from *AHK method**  
# Notes 
[no native OBS API support for media sources](https://ideas.obsproject.com/posts/144/better-media-source-playback-control)
