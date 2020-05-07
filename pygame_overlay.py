"""
prefer running everything with admin rights 
change that_window variable 
use overlay.ahk , to allow click through, alt+x toggle on/alt +  z toggle off' 
overlay - https://guidedhacking.com/threads/python-overlay-using-pygame.12633/#post-73190
find window regex - https://git.io/JfZSN
"""
import pygame
import time
import win32api
import win32con
import win32gui
import keyboard
import random
import re

# -----------------WIN32----------------------------
window_id = 0

that_window = "OpenSpades"


def locate_window(name):
    global window_id
    window_id = win32gui.FindWindow(None, name)
    if window_id != 0:
        return window_id

    def callback(wid, pattern):
        global window_id
        if re.match(pattern, str(win32gui.GetWindowText(wid))) is not None:
            window_id = wid

    win32gui.EnumWindows(callback, name)

    return window_id


def get_game_window():
    hwnd = locate_window(that_window)
    windowrect = win32gui.GetWindowRect(hwnd)
    x = windowrect[0] - 5  # -5 so it lines up perfectly
    y = windowrect[1]
    width = windowrect[2] - x
    height = windowrect[3] - y
    return x, y, width, height


def track_game():
    """ track game window"""
    win32gui.SetWindowPos(
        pygame.display.get_wm_info()["window"],
        -1,
        get_game_window()[0],
        get_game_window()[1],
        0,
        0,
        0x0001,
    )


# ---------------------PYGAME -------------------
pygame.init()
pygame.font.init()

screen = pygame.display.set_mode(
    (get_game_window()[2], get_game_window()[3]), pygame.NOFRAME
)
fuchsia = (255, 0, 128)  # Transparency color
dark_red = (139, 0, 0)
white = (255, 255, 255)
overlay_font = pygame.font.SysFont(None, 30)

# Set window transparency color
hwnd = pygame.display.get_wm_info()["window"]
win32gui.SetWindowLong(
    hwnd,
    win32con.GWL_EXSTYLE,
    win32gui.GetWindowLong(hwnd, win32con.GWL_EXSTYLE) | win32con.WS_EX_LAYERED,
)
win32gui.SetLayeredWindowAttributes(
    hwnd, win32api.RGB(*fuchsia), 0, win32con.LWA_COLORKEY
)
# ------------------LOOP------------------------------

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            break

    track_game()  # Make sure overlay follows AC
    screen.fill(fuchsia)  # Transparent background fuchsia
    # pygame.draw.rect(screen, dark_red, pygame.Rect(30, 30, 60, 60))

    # PYGAME TEXT UPDATES:
    local_text = overlay_font.render("Hello world!", True, (255, 0, 0))
    # huge fps drop
    random_number = random.randint(0, 100)
    # random_number = 0
    x_text = overlay_font.render("X: " + str(random_number), True, (255, 0, 0))

    # OVERLAY DRAWS:
    screen.blit(local_text, (15, 40))
    screen.blit(x_text, (15, 65))
    pygame.time.delay(1000)
    pygame.display.update()
    if keyboard.is_pressed("9"):  # Press K to exit.
        pygame.quit()
        quit()
        break
