"""
DevControl - Native Desktop GUI App
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import sys
import os
import threading
import tkinter as tk
from tkinter import ttk, messagebox
import customtkinter as ctk

# Ensure desktop_daemon modules can be imported
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "desktop_daemon"))

try:
    from web_server import DevControlServer
    from tunnel_manager import TunnelManager, get_local_ip
except ImportError:
    from desktop_daemon.web_server import DevControlServer
    from desktop_daemon.tunnel_manager import TunnelManager, get_local_ip

ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class DevControlDesktopApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("DevControl - Native PC Controller Server (by BieM363)")
        self.geometry("640x720")
        self.resizable(False, False)

        self.server = None
        self.server_thread = None
        self.is_running = False
        self.tunnel_mgr = None

        self._build_ui()

    def _build_ui(self):
        # HEADER CARD
        self.header_frame = ctk.CTkFrame(self, corner_radius=12, fg_color="#161B22")
        self.header_frame.pack(fill="x", padx=16, pady=16)

        self.title_label = ctk.CTkLabel(
            self.header_frame,
            text="📱💻 DevControl Desktop Server",
            font=ctk.CTkFont(size=22, weight="bold"),
            text_color="#00F0FF"
        )
        self.title_label.pack(anchor="w", padx=16, pady=(12, 2))

        self.subtitle_label = ctk.CTkLabel(
            self.header_frame,
            text="Crafted by BieM363 • Native Remote Controller for Mobile Coding",
            font=ctk.CTkFont(size=12),
            text_color="#8B949E"
        )
        self.subtitle_label.pack(anchor="w", padx=16, pady=(0, 12))


        # PIN CARD
        self.pin_frame = ctk.CTkFrame(self, corner_radius=12, fg_color="#0D1117", border_width=1, border_color="#00F0FF")
        self.pin_frame.pack(fill="x", padx=16, pady=8)

        self.pin_title = ctk.CTkLabel(self.pin_frame, text="🔐 SECURE SESSION PIN", font=ctk.CTkFont(size=11, weight="bold"), text_color="#8B949E")
        self.pin_title.pack(pady=(10, 0))

        self.pin_val_label = ctk.CTkLabel(self.pin_frame, text="••••••", font=ctk.CTkFont(family="Consolas", size=32, weight="bold"), text_color="#FFCC00")
        self.pin_val_label.pack(pady=4)

        self.btn_copy_pin = ctk.CTkButton(
            self.pin_frame, text="Copy PIN to Clipboard", width=180, fg_color="#003847", hover_color="#005C75", text_color="#00F0FF", command=self._copy_pin
        )
        self.btn_copy_pin.pack(pady=(0, 10))

        # CLOUDFLARE REMOTE TUNNEL CARD
        self.info_frame = ctk.CTkFrame(self, corner_radius=12, fg_color="#161B22", border_width=1, border_color="#30363D")
        self.info_frame.pack(fill="x", padx=16, pady=8)

        self.tunnel_title = ctk.CTkLabel(self.info_frame, text="🌍 CLOUDFLARE REMOTE TUNNEL (4G/5G/Wi-Fi)", font=ctk.CTkFont(size=11, weight="bold"), text_color="#00F0FF")
        self.tunnel_title.pack(anchor="w", padx=16, pady=(10, 4))

        self.ngrok_label = ctk.CTkLabel(self.info_frame, text="Status: Menunggu server dinyalakan...", font=ctk.CTkFont(size=13), text_color="#8B949E")
        self.ngrok_label.pack(anchor="w", padx=16, pady=(0, 6))

        self.btn_copy_tunnel = ctk.CTkButton(
            self.info_frame,
            text="📋 Salin URL Cloudflare Tunnel ke Clipboard",
            font=ctk.CTkFont(size=12, weight="bold"),
            height=32,
            fg_color="#003847",
            hover_color="#005C75",
            text_color="#00F0FF",
            command=self._copy_tunnel_url
        )
        self.btn_copy_tunnel.pack(anchor="w", padx=16, pady=(2, 10))

        # CONTROLS
        self.ctrl_frame = ctk.CTkFrame(self, corner_radius=12, fg_color="#161B22")
        self.ctrl_frame.pack(fill="x", padx=16, pady=8)


        self.btn_start_stop = ctk.CTkButton(
            self.ctrl_frame,
            text="🚀 START DAEMON SERVER",
            font=ctk.CTkFont(size=15, weight="bold"),
            height=45,
            fg_color="#00F0FF",
            hover_color="#00B8C4",
            text_color="#000000",
            command=self._toggle_server
        )
        self.btn_start_stop.pack(fill="x", padx=16, pady=12)

        # LOG PANEL
        self.log_frame = ctk.CTkFrame(self, corner_radius=12, fg_color="#0D1117")
        self.log_frame.pack(fill="both", expand=True, padx=16, pady=12)

        self.log_textbox = ctk.CTkTextbox(self.log_frame, font=ctk.CTkFont(family="Consolas", size=11), text_color="#2ECC71", fg_color="transparent")
        self.log_textbox.pack(fill="both", expand=True, padx=8, pady=8)
        self._log("DevControl Native PC GUI initialized. Click 'START DAEMON SERVER' to launch.")

    def _log(self, text: str):
        self.log_textbox.insert("end", f"> {text}\n")
        self.log_textbox.see("end")

    def _copy_pin(self):
        pin = self.pin_val_label.cget("text")
        if pin and pin != "••••••":
            self.clipboard_clear()
            self.clipboard_append(pin)
            messagebox.showinfo("DevControl", f"PIN {pin} copied to clipboard!")

    def _copy_tunnel_url(self):
        txt = self.ngrok_label.cget("text")
        if "wss://" in txt or "ws://" in txt:
            url = txt.split("Tunnel: ")[-1].strip()
            self.clipboard_clear()
            self.clipboard_append(url)
            messagebox.showinfo("DevControl", f"Cloudflare URL copied:\n{url}")
        else:
            messagebox.showwarning("DevControl", "Cloudflare Tunnel belum aktif! Klik START DAEMON SERVER terlebih dahulu.")

    def _activate_tunnel(self):
        self._log("Mengaktifkan 4G/5G Remote Tunnel (Cloudflare)...")
        self.tunnel_mgr = TunnelManager(port=8081)
        pub_url, err_msg = self.tunnel_mgr.start_cloudflare_tunnel()
        
        if not pub_url:
            self._log("Mencoba fallback ke Ngrok Tunnel...")
            pub_url, err_msg = self.tunnel_mgr.start_ngrok()

        if pub_url:
            ws_url = pub_url.replace("http://", "ws://").replace("https://", "wss://")
            self.ngrok_label.configure(text=f"🌍 4G/5G Tunnel: {ws_url}", text_color="#00F0FF")
            self._log(f"4G/5G Remote Tunnel Active! Masukkan URL ini di HP Telkomsel 4G: {ws_url}")
        else:
            self.ngrok_label.configure(text="🌍 4G/5G Tunnel: Error", text_color="#FF4D4D")
            self._log(f"ERROR TUNNEL: {err_msg}")

    def _toggle_ngrok(self):
        if self.ngrok_switch.get() == 1:
            if self.is_running and not self.tunnel_mgr:
                threading.Thread(target=self._activate_tunnel, daemon=True).start()
            else:
                self._log("4G/5G Remote Tunnel diaktifkan. Akan berjalan otomatis saat tombol START diklik.")
        else:
            if self.tunnel_mgr:
                self.tunnel_mgr.stop_tunnel()
                self.tunnel_mgr = None
            self.ngrok_label.configure(text="🌍 4G/5G Remote Tunnel: Disabled", text_color="#8B949E")
            self._log("4G/5G Remote Tunnel dinonaktifkan.")

    def _toggle_server(self):
        if not self.is_running:
            self._start_server()
        else:
            self._stop_server()

    def _start_server(self):
        try:
            self.server = DevControlServer(http_port=8080, ws_port=8081)
            pin = self.server.get_pin()
            self.pin_val_label.configure(text=pin)

            # Automatically activate Cloudflare Remote Tunnel
            threading.Thread(target=self._activate_tunnel, daemon=True).start()


            self.server_thread = threading.Thread(target=self.server.run, daemon=True)
            self.server_thread.start()

            self.is_running = True
            self.btn_start_stop.configure(text="🛑 STOP SERVER", fg_color="#E74C3C", hover_color="#C0392B", text_color="#FFFFFF")
            self._log(f"Server started on ws://{get_local_ip()}:8081 | PIN: {pin}")
        except Exception as e:
            self._log(f"Error starting server: {e}")
            messagebox.showerror("Error", f"Failed to start server: {e}")

    def _stop_server(self):
        self.is_running = False
        self.pin_val_label.configure(text="••••••")
        self.btn_start_stop.configure(text="🚀 START DAEMON SERVER", fg_color="#00F0FF", hover_color="#00B8C4", text_color="#000000")
        self.ngrok_label.configure(text="🌍 4G/5G Remote Tunnel: Disabled", text_color="#8B949E")
        if self.server:
            self.server.stop()
            self.server = None
        if self.tunnel_mgr:
            self.tunnel_mgr.stop_tunnel()
            self.tunnel_mgr = None
        self._log("Server stopped.")

def main():
    app = DevControlDesktopApp()
    app.mainloop()

if __name__ == "__main__":
    main()
