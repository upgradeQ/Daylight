# osu-overlay 
A set of tools to play osu with recorded replay , useful for hidden/flashlight modes.
# Requirements 
- Autohotkey - used to create transparent overlay 
- Python - used to manage overlay
- OBS - used to record perfect replay , but there is also a possibility to setup scenes & to project it ,like in autohotkey
- mpv - replay managment 
# Installation
1. Install autohotkey , python 64 bit , [mpv 64 bit](https://sourceforge.net/projects/mpv-player-windows/files/64bit/mpv-x86_64-20200105-git-9eb3991.7z/download), [mpv-1.dll](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/mpv-dev-x86_64-20200105-git-9eb3991.7z/download) 64 bit (dev version)
2. Place mpv.exe & mpv-1.dll  where is your python.exe  [details](https://github.com/jaseg/python-mpv#libmpv) , run `python -m pip install python-mpv keyboard`
3. Record / find replay matching your screen resolution
# Usage 
Launch `python osu_overlay.py`, modify `p.time_pos` if needed. Keys are: `e` : pause , `1`: go to start of the song , `2`: fullscreen toggle 

Launch `overlay.ahk` Calibrate transparancy level of mpv player with `win+wheel up /down`, set it always on top with `control + space`, and `alt+x` to click through 

Now launch beatmap , pause mpv player by pressing `e` with approaching circle, wait till songs stars, hit circle + `e` (timing involved)
# How can I help?
1. Open issues on things that are broken
2. Fix open issues by sending PRs
3. Add documentation

# Similar projects
https://github.com/mrflashstudio/osu-hiddenhax