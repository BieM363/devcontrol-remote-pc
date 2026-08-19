"""
DevControl - Screen Capture & Encoding Engine
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import io
import time
import logging
from typing import Tuple
from PIL import Image
import mss

logger = logging.getLogger("DevControl.ScreenCap")

class ScreenCapturer:
    def __init__(self, monitor_index: int = 1, target_width: int = 1280, quality: int = 75, fmt: str = "JPEG"):
        self.monitor_index = monitor_index
        self.target_width = target_width
        self.quality = quality
        self.fmt = fmt.upper() # 'JPEG' or 'WEBP'
        self.sct = mss.mss()
        self.author = "BieM363"
        
        monitors = self.sct.monitors
        if self.monitor_index >= len(monitors):
            self.monitor_index = 1
        
        self.monitor = monitors[self.monitor_index]
        self.screen_width = self.monitor["width"]
        self.screen_height = self.monitor["height"]
        logger.info(f"Screen Capturer initialized (by {self.author}). Monitor {self.monitor_index}: {self.screen_width}x{self.screen_height}")

    def get_screen_dimensions(self) -> Tuple[int, int]:
        return self.screen_width, self.screen_height

    def capture_frame(self) -> bytes:
        """
        Ultra low-latency screen capture & compression pipeline.
        Optimized with fast BILINEAR downscaling and zero-copy buffers.
        """
        sct_img = self.sct.grab(self.monitor)
        
        # Convert MSS raw BGRA bytes directly to RGB PIL Image
        img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")
        
        # Downscale if needed for high FPS & minimal latency over Wi-Fi / 4G
        if self.target_width and self.target_width < self.screen_width:
            aspect_ratio = self.screen_height / self.screen_width
            target_height = int(self.target_width * aspect_ratio)
            img = img.resize((self.target_width, target_height), Image.Resampling.BILINEAR)
            
        buffer = io.BytesIO()
        if self.fmt == "WEBP":
            img.save(buffer, format="WEBP", quality=self.quality, method=0) # method 0 is ultra fast
        else:
            # Fast standard JPEG encoding for universal compatibility with all Android decoders
            img.save(buffer, format="JPEG", quality=self.quality, optimize=False)
            
        return buffer.getvalue()


    def set_quality(self, quality: int):
        self.quality = max(20, min(95, quality))

    def set_target_width(self, width: int):
        self.target_width = max(320, min(self.screen_width, width))

