"""
DevControl - Session Authentication & Security Lockout
Author: BieM363 (https://github.com/BieM363)
Repository: https://github.com/BieM363/devcontrol-remote-pc
"""

import random
import string
import secrets
import time
import logging

logger = logging.getLogger("DevControl.Auth")


class AuthManager:
    def __init__(self, pin: str = None):
        if pin:
            self.pin = pin
        else:
            self.pin = "".join(random.choices(string.digits, k=6))
        
        self.active_sessions = set()
        self.failed_attempts = {}
        self.max_attempts = 5
        self.lockout_time_sec = 60

    def get_pin(self) -> str:
        return self.pin

    def verify_pin(self, client_id: str, pin_attempt: str) -> str | None:
        # Verifies client PIN. Returns session_token if valid, None if invalid.
        now = time.time()
        
        # Check lockout
        if client_id in self.failed_attempts:
            count, lock_until = self.failed_attempts[client_id]
            if now < lock_until:
                logger.warning(f"Client {client_id} is locked out for PIN attempts.")
                return None
            elif now >= lock_until and count >= self.max_attempts:
                # Reset counter after lockout period expires
                self.failed_attempts[client_id] = (0, 0)

        pin_clean = str(pin_attempt or "").strip()
        if pin_clean == str(self.pin).strip():
            token = secrets.token_hex(16)
            self.active_sessions.add(token)
            if client_id in self.failed_attempts:
                del self.failed_attempts[client_id]
            logger.info(f"Client {client_id} authenticated successfully.")
            return token
        else:
            count, _ = self.failed_attempts.get(client_id, (0, 0))
            count += 1
            lock_until = now + self.lockout_time_sec if count >= self.max_attempts else 0
            self.failed_attempts[client_id] = (count, lock_until)
            logger.warning(f"Client {client_id} failed PIN attempt ({count}/{self.max_attempts}).")
            return None

    def validate_token(self, token: str) -> bool:
        return token in self.active_sessions

    def revoke_token(self, token: str):
        self.active_sessions.discard(token)
