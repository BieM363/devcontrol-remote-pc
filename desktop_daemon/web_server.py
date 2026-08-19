"""
DevControl - Web & WebSocket Realtime Server
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import sys
import asyncio
import json
import logging
import os
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
import websockets

try:
    from auth import AuthManager
    from screencap import ScreenCapturer
    from input_handler import InputHandler
except ImportError:
    from desktop_daemon.auth import AuthManager
    from desktop_daemon.screencap import ScreenCapturer
    from desktop_daemon.input_handler import InputHandler

logger = logging.getLogger("DevControl.Server")

def get_static_dir() -> str:
    if hasattr(sys, '_MEIPASS'):
        p1 = os.path.join(sys._MEIPASS, "desktop_daemon", "static")
        if os.path.exists(p1):
            return p1
        p2 = os.path.join(sys._MEIPASS, "static")
        if os.path.exists(p2):
            return p2
    p3 = os.path.join(os.path.dirname(__file__), "static")
    if os.path.exists(p3):
        return p3
    return "static"

class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        static_dir = get_static_dir()
        super().__init__(*args, directory=static_dir, **kwargs)

    def log_message(self, format, *args):
        # Suppress verbose standard HTTP request logs
        pass


def start_http_server(host: str, port: int):
    httpd = HTTPServer((host, port), CustomHTTPRequestHandler)
    logger.info(f"HTTP Web Client active at http://{host}:{port}/ (Crafted by BieM363)")
    httpd.serve_forever()

class DevControlServer:
    def __init__(self, host: str = "0.0.0.0", http_port: int = 8080, ws_port: int = 8081, pin: str = None):
        self.host = host
        self.http_port = http_port
        self.ws_port = ws_port
        self.author = "BieM363"
        self.auth = AuthManager(pin=pin)
        self.screencap = ScreenCapturer(target_width=1280, quality=75)
        sw, sh = self.screencap.get_screen_dimensions()
        self.input_handler = InputHandler(sw, sh)
        self.active_connections = set()
        self.streaming_tasks = {}
        self.httpd = None
        self.loop = None
        self._stop_event = None
        self.ws_server = None
        self.is_running = False

    def get_pin(self) -> str:
        return self.auth.get_pin()

    async def _stream_frames(self, websocket, token: str):
        """
        Ultra-low latency streaming loop with backpressure protection.
        Prevents frame accumulation queues so video streaming has ZERO lag buildup.
        """
        fps_target = 30
        frame_interval = 1.0 / fps_target
        
        try:
            while self.is_running:
                start_time = asyncio.get_event_loop().time()
                
                if not self.auth.validate_token(token):
                    logger.warning("Token invalidated during streaming loop.")
                    break

                # Capture frame using native Windows GDI
                frame_bytes = self.screencap.capture_frame()
                
                # Send binary JPEG frame over WebSocket
                await websocket.send(frame_bytes)
                
                elapsed = asyncio.get_event_loop().time() - start_time
                sleep_time = max(0.001, frame_interval - elapsed)
                await asyncio.sleep(sleep_time)
        except (websockets.exceptions.ConnectionClosed, websockets.exceptions.ConnectionClosedOK, websockets.exceptions.ConnectionClosedError):
            logger.info("Streaming ended: Client disconnected.")
        except Exception as e:
            logger.error(f"Error in streaming loop: {e}")


    async def _handle_message(self, websocket, message):
        """
        Handles inbound control messages from mobile client (Web & Flutter).
        """
        try:
            if isinstance(message, str):
                data = json.loads(message)
                msg_type = data.get("type")
                
                # Auth Handshake
                if msg_type == "auth":
                    pin_attempt = data.get("pin")
                    
                    # Safe client ID extraction
                    client_id = data.get("client_id")
                    if not client_id:
                        if websocket.remote_address and isinstance(websocket.remote_address, (list, tuple)):
                            client_id = str(websocket.remote_address[0])
                        else:
                            client_id = str(websocket.remote_address or "client")

                    token = self.auth.verify_pin(client_id, pin_attempt)
                    
                    if token:
                        sw, sh = self.screencap.get_screen_dimensions()
                        response = {
                            "type": "auth_result",
                            "success": True,
                            "token": token,
                            "screen_width": sw,
                            "screen_height": sh,
                            "author": "BieM363"
                        }
                        await websocket.send(json.dumps(response))
                        
                        # Start streaming loop task for this authenticated client
                        task = asyncio.create_task(self._stream_frames(websocket, token))
                        self.streaming_tasks[websocket] = task
                    else:
                        response = {
                            "type": "auth_result",
                            "success": False,
                            "message": "PIN Keamanan Salah!"
                        }
                        await websocket.send(json.dumps(response))
                    return

                # Validate token for all control actions
                token = data.get("token")
                if not self.auth.validate_token(token):
                    await websocket.send(json.dumps({"type": "error", "message": "Unauthorized"}))
                    return

                # Handle Input Controls
                if msg_type == "mouse_move":
                    self.input_handler.handle_mouse_move(data["nx"], data["ny"])
                elif msg_type == "mouse_move_rel":
                    self.input_handler.handle_mouse_move_rel(data.get("dx", 0), data.get("dy", 0))
                elif msg_type == "mouse_click":
                    self.input_handler.handle_mouse_click(data.get("button", "left"), data.get("count", 1))
                elif msg_type == "mouse_down":
                    self.input_handler.handle_mouse_down(data.get("button", "left"))
                elif msg_type == "mouse_up":
                    self.input_handler.handle_mouse_up(data.get("button", "left"))
                elif msg_type == "mouse_scroll":
                    self.input_handler.handle_mouse_scroll(data.get("dx", 0), data.get("dy", 0))
                elif msg_type == "shortcut":
                    self.input_handler.handle_key_combination(data.get("keys", []))
                elif msg_type == "key_press":
                    self.input_handler.handle_single_key(data.get("key"))
                elif msg_type == "key_down":
                    self.input_handler.handle_key_down(data.get("key"))
                elif msg_type == "key_up":
                    self.input_handler.handle_key_up(data.get("key"))
                elif msg_type == "type_text":
                    self.input_handler.handle_type_text(data.get("text", ""))
                elif msg_type == "settings":
                    if "target_width" in data:
                        self.screencap.set_target_width(data["target_width"])
                    if "quality" in data:
                        self.screencap.set_quality(data["quality"])
                elif msg_type == "ping":
                    await websocket.send(json.dumps({"type": "pong", "timestamp": data.get("timestamp")}))
                    
        except Exception as e:
            logger.error(f"Error handling message: {e}")

    async def _ws_handler(self, websocket):
        self.active_connections.add(websocket)
        logger.info(f"New client connected from {websocket.remote_address}")
        try:
            async for message in websocket:
                await self._handle_message(websocket, message)
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            if websocket in self.active_connections:
                self.active_connections.remove(websocket)
            if websocket in self.streaming_tasks:
                self.streaming_tasks[websocket].cancel()
                del self.streaming_tasks[websocket]
            logger.info(f"Client disconnected {websocket.remote_address}")

    def run(self):
        # Start HTTP server thread for static web app
        try:
            self.httpd = HTTPServer((self.host, self.http_port), CustomHTTPRequestHandler)
            http_thread = threading.Thread(
                target=self.httpd.serve_forever,
                daemon=True
            )
            http_thread.start()
            logger.info(f"HTTP Web Client active at http://{self.host}:{self.http_port}/ (Crafted by BieM363)")
        except Exception as e:
            logger.warning(f"Could not start HTTP server on port {self.http_port}: {e}")

        # Start WebSocket server loop
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self._stop_event = asyncio.Event()

        async def main_loop():
            async with websockets.serve(self._ws_handler, self.host, self.ws_port) as server:
                self.ws_server = server
                self.is_running = True
                logger.info(f"WebSocket Server active at ws://{self.host}:{self.ws_port}/")
                await self._stop_event.wait()
                server.close()
                await server.wait_closed()

        try:
            self.loop.run_until_complete(main_loop())
        except Exception as e:
            logger.error(f"WebSocket server loop error: {e}")
        finally:
            try:
                self.loop.close()
            except Exception:
                pass

    def stop(self):
        self.is_running = False
        if self.httpd:
            try:
                self.httpd.shutdown()
                self.httpd.server_close()
            except Exception:
                pass
            self.httpd = None

        if self.loop and self._stop_event:
            try:
                self.loop.call_soon_threadsafe(self._stop_event.set)
            except Exception:
                pass

