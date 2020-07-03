# Cheat engine HP overlay
- Using OBS Studio script to automatically change level of opacity according to HP value.
- Also using cheat engine script to output value health to `output.txt`
# Setup
- OBS Studio with scripting support , cheat engine , python3.6 
Note : Python script is somewhat unstable at the moment.
- Assuming color source has been created and it has Opacity filter set to 50 , with name `py_color`
- load script in OBS
- find address of health value in game, change description to `hp`.
- load lua script in cheat engine, start script by pressing `f3`, `f4` to stop.
- finish setup by Start / Stop buttons in OBS Studio, check `console output` it will show `tick` every 200 ms .
# Reference
Video - [How Speedrunners Use Game Hacking Tools](https://www.youtube.com/watch?v=elI6vZR6HGE)
Video - [Pointer scan](https://www.youtube.com/watch?v=qHau4rYNs0s)
https://wiki.cheatengine.org/index.php?title=Lua:Class:Addresslist
https://wiki.cheatengine.org/index.php?title=createTimer
https://learnxinyminutes.com/docs/lua/
