"""
DevControl - Desktop Daemon CLI Entrypoint
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import sys
import os
import argparse
import logging
from colorama import init, Fore, Style

from web_server import DevControlServer
from tunnel_manager import TunnelManager, get_local_ip

# Initialize colorama for colored terminal output
init(autoreset=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger("DevControl.Main")

BANNER = f"""
{Fore.CYAN}{Style.BRIGHT}
 📱💻 DevControl Desktop Daemon
 =========================================================
 Cross-Network Native Remote PC Controller for Mobile Coding
 Author & Lead Developer: BieM363
 Repository: https://github.com/BieM363/devcontrol-remote-pc
 Target Device: ZTE Blade V50 Design (1080x2408 @ 90Hz)
 =========================================================
{Style.RESET_ALL}"""


def parse_args():
    parser = argparse.ArgumentParser(description="DevControl Desktop Daemon")
    parser.add_argument("--pin", type=str, default=None, help="Custom 6-digit session PIN")
    parser.add_argument("--http-port", type=int, default=8080, help="Port for Mobile Web Client PWA")
    parser.add_argument("--ws-port", type=int, default=8081, help="Port for WebSocket control stream")
    parser.add_argument("--ngrok", action="store_true", help="Enable Ngrok Tunnel for 4G/5G remote data access")
    parser.add_argument("--ngrok-token", type=str, default=None, help="Ngrok Auth Token")
    return parser.parse_args()

def main():
    args = parse_args()
    print(BANNER)
    
    server = DevControlServer(
        http_port=args.http_port,
        ws_port=args.ws_port,
        pin=args.pin
    )
    
    pin = server.get_pin()
    local_ip = get_local_ip()
    
    tunnel_mgr = TunnelManager(port=args.http_port, ngrok_authtoken=args.ngrok_token)
    
    print(f"{Fore.GREEN}{Style.BRIGHT}🔐 SECURE SESSION PIN: {Fore.YELLOW}{Style.BRIGHT}{pin}{Style.RESET_ALL}")
    print(f"{Fore.BLUE}🌐 Local Wi-Fi Web App: {Style.BRIGHT}http://{local_ip}:{args.http_port}/{Style.RESET_ALL}")
    print(f"{Fore.BLUE}⚡ Local WebSocket Stream: {Style.BRIGHT}ws://{local_ip}:{args.ws_port}/{Style.RESET_ALL}\n")

    url_for_qr = f"http://{local_ip}:{args.http_port}/"

    if args.ngrok:
        print(f"{Fore.YELLOW}🚀 Starting Ngrok Tunnel for Remote Cellular 4G/5G Access...{Style.RESET_ALL}")
        public_url = tunnel_mgr.start_ngrok()
        if public_url:
            print(f"{Fore.GREEN}{Style.BRIGHT}🌍 REMOTE CELLULAR URL: {public_url}{Style.RESET_ALL}")
            url_for_qr = public_url

    tunnel_mgr.print_qr_code(url_for_qr)
    
    print(f"{Fore.CYAN}Ready for connections! Press Ctrl+C to terminate server.{Style.RESET_ALL}\n")
    
    try:
        server.run()
    except KeyboardInterrupt:
        print(f"\n{Fore.RED}DevControl Daemon stopped.{Style.RESET_ALL}")
        sys.exit(0)

if __name__ == "__main__":
    main()
