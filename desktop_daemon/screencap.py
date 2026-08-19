"""
DevControl - Screen Capture & Encoding Engine
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import os
import io
import time
import logging
from typing import Tuple
from PIL import Image

logger = logging.getLogger("DevControl.ScreenCap")

# Windows GDI ctypes definitions for direct hardware screen capture
if os.name == 'nt':
    import ctypes
    import ctypes.wintypes

    user32 = ctypes.windll.user32
    gdi32 = ctypes.windll.gdi32

    # Enable per-monitor DPI awareness for accurate screen dimensions
    try:
        user32.SetProcessDPIAware()
    except Exception:
        pass

    class BITMAPINFOHEADER(ctypes.Structure):
        _fields_ = [
            ('biSize', ctypes.wintypes.DWORD),
            ('biWidth', ctypes.wintypes.LONG),
            ('biHeight', ctypes.wintypes.LONG),
            ('biPlanes', ctypes.wintypes.WORD),
            ('biBitCount', ctypes.wintypes.WORD),
            ('biCompression', ctypes.wintypes.DWORD),
            ('biSizeImage', ctypes.wintypes.DWORD),
            ('biXPelsPerMeter', ctypes.wintypes.LONG),
            ('biYPelsPerMeter', ctypes.wintypes.LONG),
            ('biClrUsed', ctypes.wintypes.DWORD),
            ('biClrImportant', ctypes.wintypes.DWORD)
        ]

class ScreenCapturer:
    def __init__(self, monitor_index: int = 1, target_width: int = 1280, quality: int = 75, fmt: str = "JPEG"):
        self.monitor_index = monitor_index
        self.target_width = target_width
        self.quality = quality
        self.fmt = fmt.upper()
        self.author = "BieM363"
        self.is_windows = (os.name == 'nt')
        
        if self.is_windows:
            self.screen_width = user32.GetSystemMetrics(0)
            self.screen_height = user32.GetSystemMetrics(1)
            
            # Setup pre-allocated bitmap header for top-down raw DIB reading
            self.bmi = BITMAPINFOHEADER()
            self.bmi.biSize = ctypes.sizeof(BITMAPINFOHEADER)
            self.bmi.biWidth = self.screen_width
            self.bmi.biHeight = -self.screen_height # Negative = Top-Down
            self.bmi.biPlanes = 1
            self.bmi.biBitCount = 32
            self.bmi.biCompression = 0
            self.raw_buffer = ctypes.create_string_buffer(self.screen_width * self.screen_height * 4)
        else:
            import mss
            self.sct = mss.mss()
            monitors = self.sct.monitors
            m = monitors[1] if len(monitors) > 1 else monitors[0]
            self.screen_width = m["width"]
            self.screen_height = m["height"]
            self.monitor = m

        logger.info(f"Screen Capturer initialized (by {self.author}). Resolution: {self.screen_width}x{self.screen_height}")

    def get_screen_dimensions(self) -> Tuple[int, int]:
        return self.screen_width, self.screen_height

    def capture_frame(self) -> bytes:
        """
        Ultra low-latency screen capture & compression pipeline (50+ FPS).
        Uses native Windows GDI BitBlt + GetDIBits with zero-copy PIL buffer.
        """
        if self.is_windows:
            hdc_screen = user32.GetDC(0)
            hdc_mem = gdi32.CreateCompatibleDC(hdc_screen)
            hbmp = gdi32.CreateCompatibleBitmap(hdc_screen, self.screen_width, self.screen_height)
            hbmp_old = gdi32.SelectObject(hdc_mem, hbmp)
            
            # SRCCOPY (0x00CC0020) without CAPTUREBLT flag for 100% reliable GDI capture
            gdi32.BitBlt(hdc_mem, 0, 0, self.screen_width, self.screen_height, hdc_screen, 0, 0, 0x00CC0020)
            gdi32.GetDIBits(hdc_mem, hbmp, 0, self.screen_height, self.raw_buffer, ctypes.byref(self.bmi), 0)
            
            # Clean up Windows GDI handles immediately to prevent memory leak
            gdi32.SelectObject(hdc_mem, hbmp_old)
            gdi32.DeleteObject(hbmp)
            gdi32.DeleteDC(hdc_mem)
            user32.ReleaseDC(0, hdc_screen)
            
            # Create PIL image directly from memory buffer
            img = Image.frombuffer('RGB', (self.screen_width, self.screen_height), self.raw_buffer, 'raw', 'BGRX', 0, 1)
        else:
            sct_img = self.sct.grab(self.monitor)
            img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")

        # Downscale if needed for lower network bandwidth and ultra-smooth frame rates
        if self.target_width and self.target_width < self.screen_width:
            aspect_ratio = self.screen_height / self.screen_width
            target_height = int(self.target_width * aspect_ratio)
            img = img.resize((self.target_width, target_height), Image.Resampling.BILINEAR)
            
        buffer = io.BytesIO()
        if self.fmt == "WEBP":
            img.save(buffer, format="WEBP", quality=self.quality, method=0)
        else:
            # Fast standard baseline JPEG encoding
            img.save(buffer, format="JPEG", quality=self.quality, optimize=False)
            
        return buffer.getvalue()

    def set_quality(self, quality: int):
        self.quality = max(20, min(95, quality))

    def set_target_width(self, width: int):
        self.target_width = max(320, min(self.screen_width, width))


