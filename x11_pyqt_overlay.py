import sys
from ast import literal_eval
from threading import Thread
from PyQt5.QtGui import QWindow
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtWidgets import QWidget, QApplication, QHBoxLayout
from types import SimpleNamespace as _G

G = _G()

G.running = False
G.done = False
__version__ = "0.1.0"


def event_loop():
    print("commands: start - starts click through, exit - gracefully stop")
    try:
        while True:
            data = input(">").lower()
            if data == "start":
                print("start")
                G.running = True

            if data == "exit":
                sys.exit(0)
                print("exit")
            if "opacity" in data:
                print("to be implemented")

    except (KeyboardInterrupt, EOFError):
        sys.exit(0)


class Main(QWidget):
    def __init__(self, hwnd, parent=None):
        QWidget.__init__(self, parent)
        window = QWindow.fromWinId(hwnd)
        self.container = self.createWindowContainer(window)
        self.setGeometry(100, 100, 1024, 768)
        # layout = QVBoxLayout(self)
        layout = QHBoxLayout(self)
        layout.addWidget(self.container)
        self.setLayout(layout)
        self.show()
        self.launch_timer()

    def launch_timer(self):
        self.timer = QTimer()
        self.timer.setInterval(15)
        self.timer.timeout.connect(self.interal_event_loop)
        self.timer.start()

    def interal_event_loop(self):
        if G.running and not G.done:
            self.make_overlay()
            G.done = True

    def make_overlay(self):
        print("overlay created")
        self.setWindowFlags(
            Qt.Window
            | Qt.CustomizeWindowHint
            | Qt.WindowStaysOnTopHint
            | Qt.FramelessWindowHint
            | Qt.X11BypassWindowManagerHint
            | Qt.WindowTransparentForInput
        )
        self.show()


if __name__ == "__main__":
    print("You should provide window id, get it using xwininfo")

    Thread(target=event_loop).start()
    app = QApplication(sys.argv)
    win = Main(int(literal_eval(sys.argv[1])))
    win.setWindowTitle("Window container")
    sys.exit(app.exec_())
