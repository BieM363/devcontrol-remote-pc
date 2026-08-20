"""
DevControl - Input Simulation Controller (Mouse, Keyboard & Gestures)
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import logging
import pyautogui
from pynput.mouse import Button, Controller as MouseController
from pynput.keyboard import Key, Controller as KeyboardController

logger = logging.getLogger("DevControl.Input")

# Zero artificial delay for instant, fluid responsiveness
pyautogui.FAILSAFE = False
pyautogui.PAUSE = 0.0

class InputHandler:
    def __init__(self, screen_width: int, screen_height: int):
        self.screen_width = screen_width
        self.screen_height = screen_height
        self.mouse = MouseController()
        self.keyboard = KeyboardController()
        self.author = "BieM363"
        self.active_modifiers = set()
        
        # Mapping string key names to pynput Key objects
        self.SPECIAL_KEYS = {
            "ctrl": Key.ctrl_l,
            "control": Key.ctrl_l,
            "alt": Key.alt_l,
            "shift": Key.shift,
            "super": Key.cmd,
            "cmd": Key.cmd,
            "win": Key.cmd,
            "tab": Key.tab,
            "enter": Key.enter,
            "return": Key.enter,
            "esc": Key.esc,
            "escape": Key.esc,
            "backspace": Key.backspace,
            "delete": Key.delete,
            "space": Key.space,
            "up": Key.up,
            "down": Key.down,
            "left": Key.left,
            "right": Key.right,
            "home": Key.home,
            "end": Key.end,
            "pageup": Key.page_up,
            "pagedown": Key.page_down,
            "f1": Key.f1,
            "f2": Key.f2,
            "f3": Key.f3,
            "f4": Key.f4,
            "f5": Key.f5,
            "f6": Key.f6,
            "f7": Key.f7,
            "f8": Key.f8,
            "f9": Key.f9,
            "f10": Key.f10,
            "f11": Key.f11,
            "f12": Key.f12,
        }

    def update_screen_dimensions(self, width: int, height: int):
        self.screen_width = width
        self.screen_height = height

    def _normalize_coords(self, nx: float, ny: float):
        x = int(max(0, min(1.0, nx)) * self.screen_width)
        y = int(max(0, min(1.0, ny)) * self.screen_height)
        return x, y

    def handle_mouse_move(self, nx: float, ny: float):
        x, y = self._normalize_coords(nx, ny)
        try:
            import ctypes
            ctypes.windll.user32.SetCursorPos(x, y)
        except Exception:
            self.mouse.position = (x, y)

    def handle_mouse_move_rel(self, dx: float, dy: float):
        try:
            cx, cy = self.mouse.position
            nx = int(max(0, min(self.screen_width, cx + dx)))
            ny = int(max(0, min(self.screen_height, cy + dy)))
            try:
                import ctypes
                ctypes.windll.user32.SetCursorPos(nx, ny)
            except Exception:
                self.mouse.position = (nx, ny)
        except Exception:
            pass

    def handle_mouse_click(self, button: str = "left", count: int = 1):
        btn = Button.right if button == "right" else Button.middle if button == "middle" else Button.left
        self.mouse.click(btn, count)

    def handle_mouse_down(self, button: str = "left"):
        btn = Button.right if button == "right" else Button.middle if button == "middle" else Button.left
        self.mouse.press(btn)

    def handle_mouse_up(self, button: str = "left"):
        btn = Button.right if button == "right" else Button.middle if button == "middle" else Button.left
        self.mouse.release(btn)

    def handle_mouse_scroll(self, dx: int, dy: int):
        # dy > 0 is scroll up, dy < 0 is scroll down
        self.mouse.scroll(dx, dy)

    def _resolve_key(self, key_name: str):
        k_lower = key_name.lower()
        return self.SPECIAL_KEYS.get(k_lower, key_name)

    def handle_key_combination(self, keys: list[str]):
        """
        Executes key shortcuts e.g. ["ctrl", "a"], ["ctrl", "c"], ["ctrl", "v"],
        ["shift", "left"], ["shift", "right"], ["ctrl", "s"].
        """
        parsed_keys = [self._resolve_key(k) for k in keys]

        # Press keys down in order
        for key in parsed_keys:
            self.keyboard.press(key)
        
        # Release in reverse order
        for key in reversed(parsed_keys):
            self.keyboard.release(key)

    def handle_key_down(self, key_name: str):
        key_obj = self._resolve_key(key_name)
        self.keyboard.press(key_obj)
        self.active_modifiers.add(key_name.lower())

    def handle_key_up(self, key_name: str):
        key_obj = self._resolve_key(key_name)
        self.keyboard.release(key_obj)
        self.active_modifiers.discard(key_name.lower())

    def handle_type_text(self, text: str):
        if not text:
            return
        try:
            # If text has multiple characters, newlines, tabs, or symbols, use instant clipboard paste
            if len(text) > 1 or '\n' in text or '\t' in text:
                import pyperclip
                pyperclip.copy(text)
                self.handle_key_combination(["ctrl", "v"])
            else:
                self.keyboard.type(text)
        except Exception:
            try:
                pyautogui.write(text, interval=0.0)
            except Exception as e:
                logger.error(f"Error typing text: {e}")

    def handle_single_key(self, key_name: str):
        key_obj = self._resolve_key(key_name)
        self.keyboard.press(key_obj)
        self.keyboard.release(key_obj)

