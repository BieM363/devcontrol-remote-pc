"""
DevControl - Cloudflare & Ngrok Tunnel Manager
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import os
import sys
import socket
import logging
import io
import subprocess
import re
import time

logger = logging.getLogger("DevControl.Tunnel")


def get_local_ip() -> str:
    # Returns primary LAN IPv4 address of laptop.
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def get_cloudflared_path() -> str:
    if hasattr(sys, '_MEIPASS'):
        p1 = os.path.join(sys._MEIPASS, 'desktop_daemon', 'cloudflared.exe')
        if os.path.exists(p1):
            return p1
        p2 = os.path.join(sys._MEIPASS, 'cloudflared.exe')
        if os.path.exists(p2):
            return p2

    p3 = os.path.join(os.path.dirname(__file__), "cloudflared.exe")
    if os.path.exists(p3):
        return p3

    return "cloudflared"

class TunnelManager:
    def __init__(self, port: int = 8081, ngrok_authtoken: str = None):
        self.port = port
        self.ngrok_authtoken = ngrok_authtoken
        self.public_url = None
        self.cloudflared_proc = None
        self.local_url = f"http://{get_local_ip()}:{self.port}"

    def start_cloudflare_tunnel(self) -> tuple[str | None, str | None]:
        # Starts Cloudflare Tunnel using bundled cloudflared.exe (100% Antivirus Safe)
        try:
            exe_path = get_cloudflared_path()
            logger.info(f"Using Cloudflare executable: {exe_path}")

            self.cloudflared_proc = subprocess.Popen(
                [exe_path, "tunnel", "--url", f"http://localhost:{self.port}"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            )

            start_time = time.time()
            while time.time() - start_time < 15:
                line = self.cloudflared_proc.stdout.readline()
                if not line:
                    break
                match = re.search(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com', line)
                if match:
                    self.public_url = match.group(0)
                    logger.info(f"Cloudflare Tunnel active: {self.public_url}")
                    return self.public_url, None
            
            return None, "Cloudflare Tunnel timeout saat menghubungkan server."
        except Exception as e:
            return None, f"Error Cloudflare Tunnel: {e}"

    def start_ngrok(self) -> tuple[str | None, str | None]:
        # Starts Ngrok tunnel as secondary option.
        try:
            from pyngrok import ngrok, conf
            
            if self.ngrok_authtoken:
                ngrok.set_auth_token(self.ngrok_authtoken)
            
            tunnel = ngrok.connect(self.port, "http")
            self.public_url = tunnel.public_url
            logger.info(f"Ngrok Tunnel active: {self.public_url}")
            return self.public_url, None
        except Exception as e:
            err_msg = str(e)
            if "225" in err_msg or "virus" in err_msg.lower() or "operation did not complete" in err_msg.lower():
                err_msg = "Windows Defender memblokir ngrok.exe."
            elif "authtoken" in err_msg.lower():
                err_msg = "Ngrok memerlukan Auth Token gratis."
            logger.warning(f"Ngrok tunnel error: {err_msg}")
            return None, err_msg

    def stop_tunnel(self):
        if self.cloudflared_proc:
            try:
                self.cloudflared_proc.terminate()
                self.cloudflared_proc.kill()
            except Exception:
                pass
            self.cloudflared_proc = None
        
        if os.name == 'nt':
            try:
                subprocess.run(["taskkill", "/F", "/IM", "cloudflared.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass

    def print_qr_code(self, url: str):
        # Prints ASCII QR code in terminal for easy phone camera pairing.
        try:
            import qrcode
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=1,
                border=2,
            )
            qr.add_data(url)
            qr.make(fit=True)
            
            f = io.StringIO()
            qr.print_ascii(out=f, invert=True)
            logger.info(f"\nScan QR Code with ZTE Blade V50 Design:\n{f.getvalue()}")
        except Exception as e:
            logger.debug(f"Could not render ASCII QR code: {e}")
