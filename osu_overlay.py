import mpv
import keyboard
import time

p = mpv.MPV()

p.play("song_name.mp4")


def play_pause():
    p.pause = not p.pause


keyboard.add_hotkey("e", play_pause)


def full():
    p.fullscreen = not p.fullscreen


keyboard.add_hotkey("2", full)


def go_to_start():
    p.time_pos = 2


keyboard.add_hotkey("1", go_to_start)

while 1:
    time.sleep(40)
