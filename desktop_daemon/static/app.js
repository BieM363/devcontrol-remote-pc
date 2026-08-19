/**
 * DevControl - Mobile Web Client Engine
 * Author: BieM363 (https://github.com/BieM363)
 * Repository: https://github.com/BieM363/devcontrol-remote-pc
 */

(function () {
  console.log("%c⚡ DevControl Remote PC Controller — Developed by BieM363", "color: #00f0ff; font-size: 14px; font-weight: bold;");

  let ws = null;
  let authToken = null;
  let screenWidth = 1920;
  let screenHeight = 1080;
  
  // UI Elements
  const authModal = document.getElementById('authModal');
  const appContainer = document.getElementById('appContainer');
  const pinInput = document.getElementById('pinInput');
  const connectBtn = document.getElementById('connectBtn');
  const authError = document.getElementById('authError');
  const wsHostInput = document.getElementById('wsHostInput');
  const canvas = document.getElementById('remoteCanvas');
  const ctx = canvas.getContext('2d', { alpha: false });
  const touchSurface = document.getElementById('touchSurface');
  const hiddenKeyboardInput = document.getElementById('hiddenKeyboardInput');
  
  const connectionStatus = document.getElementById('connectionStatus');
  const fpsCounter = document.getElementById('fpsCounter');
  const pingCounter = document.getElementById('pingCounter');
  
  const toggleKeyboardBtn = document.getElementById('toggleKeyboardBtn');
  const toggleEditModeBtn = document.getElementById('toggleEditModeBtn');
  const selectionRow = document.getElementById('selectionRow');
  const settingsBtn = document.getElementById('settingsBtn');
  const disconnectBtn = document.getElementById('disconnectBtn');
  const settingsModal = document.getElementById('settingsModal');
  const closeSettingsBtn = document.getElementById('closeSettingsBtn');
  const resSelect = document.getElementById('resSelect');
  const qualitySlider = document.getElementById('qualitySlider');
  const qualityVal = document.getElementById('qualityVal');

  // Active modifier toggles (Shift, Ctrl, Alt)
  const activeModifiers = {
    shift: false,
    ctrl: false,
    alt: false
  };

  // Metrics
  let frameCount = 0;
  let lastFpsCalcTime = performance.now();
  let lastPingSendTime = 0;
  let isRendering = false;

  // Auto-detect default WS host
  const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const defaultWsPort = 8081;
  const defaultWsUrl = `${protocol}//${location.hostname}:${defaultWsPort}`;
  wsHostInput.value = defaultWsUrl;

  // AUTO CONNECT IF PIN SAVED IN LOCALSTORAGE
  const savedPin = localStorage.getItem('devcontrol_pin');
  if (savedPin) {
    pinInput.value = savedPin;
  }

  connectBtn.addEventListener('click', initConnection);
  disconnectBtn.addEventListener('click', disconnect);

  function initConnection() {
    const pin = pinInput.value.trim();
    const wsUrl = wsHostInput.value.trim();

    if (!pin || pin.length !== 6) {
      showError('Please enter a 6-digit PIN.');
      return;
    }

    showError('');
    connectBtn.disabled = true;
    connectBtn.innerText = 'Connecting...';

    try {
      ws = new WebSocket(wsUrl);
      ws.binaryType = 'blob';

      ws.onopen = () => {
        // Send Auth Payload
        const authPayload = {
          type: 'auth',
          pin: pin,
          client_id: 'mobile_web_' + Math.random().toString(36).substring(2, 8)
        };
        ws.send(JSON.stringify(authPayload));
      };

      ws.onmessage = (event) => {
        if (typeof event.data === 'string') {
          handleJsonMessage(JSON.parse(event.data));
        } else if (event.data instanceof Blob) {
          renderFrameFast(event.data);
        }
      };

      ws.onerror = (err) => {
        console.error('WebSocket Error:', err);
        showError('Could not connect to server. Check IP/Tunnel.');
        resetConnectBtn();
      };

      ws.onclose = () => {
        handleDisconnected();
      };
    } catch (e) {
      showError('Invalid WebSocket URL.');
      resetConnectBtn();
    }
  }

  function handleJsonMessage(msg) {
    if (msg.type === 'auth_result') {
      if (msg.success) {
        authToken = msg.token;
        screenWidth = msg.screen_width || 1920;
        screenHeight = msg.screen_height || 1080;
        
        localStorage.setItem('devcontrol_pin', pinInput.value.trim());
        
        authModal.classList.add('hidden');
        appContainer.classList.remove('hidden');
        connectionStatus.innerText = 'Connected';
        
        startPingLoop();
      } else {
        showError(msg.message || 'Authentication Failed');
        resetConnectBtn();
        ws.close();
      }
    } else if (msg.type === 'pong') {
      const pingTime = Math.round(performance.now() - lastPingSendTime);
      pingCounter.innerText = `Ping: ${pingTime}ms`;
    }
  }

  // ULTRA FAST FRAME RENDERING (Zero-lag Canvas Draw)
  function renderFrameFast(blob) {
    if ('createImageBitmap' in window) {
      createImageBitmap(blob).then(bitmap => {
        if (canvas.width !== bitmap.width || canvas.height !== bitmap.height) {
          canvas.width = bitmap.width;
          canvas.height = bitmap.height;
        }
        ctx.drawImage(bitmap, 0, 0);
        bitmap.close();

        // Calculate FPS
        frameCount++;
        const now = performance.now();
        if (now - lastFpsCalcTime >= 1000) {
          fpsCounter.innerText = `FPS: ${frameCount}`;
          frameCount = 0;
          lastFpsCalcTime = now;
        }
      }).catch(() => {});
    } else {
      const img = new Image();
      const url = URL.createObjectURL(blob);
      img.onload = () => {
        canvas.width = img.width;
        canvas.height = img.height;
        ctx.drawImage(img, 0, 0);
        URL.revokeObjectURL(url);

        frameCount++;
        const now = performance.now();
        if (now - lastFpsCalcTime >= 1000) {
          fpsCounter.innerText = `FPS: ${frameCount}`;
          frameCount = 0;
          lastFpsCalcTime = now;
        }
      };
      img.src = url;
    }
  }

  function sendControl(data) {
    if (ws && ws.readyState === WebSocket.OPEN && authToken) {
      data.token = authToken;
      ws.send(JSON.stringify(data));
    }
  }

  function startPingLoop() {
    setInterval(() => {
      if (ws && ws.readyState === WebSocket.OPEN && authToken) {
        lastPingSendTime = performance.now();
        sendControl({ type: 'ping', timestamp: lastPingSendTime });
      }
    }, 3000);
  }

  function showError(text) {
    if (text) {
      authError.innerText = text;
      authError.classList.remove('hidden');
    } else {
      authError.classList.add('hidden');
    }
  }

  function resetConnectBtn() {
    connectBtn.disabled = false;
    connectBtn.innerText = 'Connect & Start Coding';
  }

  function disconnect() {
    if (ws) {
      ws.close();
    }
    handleDisconnected();
  }

  function handleDisconnected() {
    authToken = null;
    appContainer.classList.add('hidden');
    authModal.classList.remove('hidden');
    resetConnectBtn();
  }

  // GESTURE & TOUCHPAD CONTROLLER (Throttled for zero lag & maximum fluidness)
  let touchStartX = 0;
  let touchStartY = 0;
  let lastTouchX = 0;
  let lastTouchY = 0;
  let touchStartTime = 0;
  let isMultiTouch = false;
  let lastMouseMoveTime = 0;

  touchSurface.addEventListener('touchstart', (e) => {
    e.preventDefault();
    const touches = e.touches;
    touchStartTime = performance.now();
    
    if (touches.length === 1) {
      isMultiTouch = false;
      const rect = touchSurface.getBoundingClientRect();
      touchStartX = touches[0].clientX - rect.left;
      touchStartY = touches[0].clientY - rect.top;
      lastTouchX = touchStartX;
      lastTouchY = touchStartY;
    } else if (touches.length === 2) {
      isMultiTouch = true;
      lastTouchY = (touches[0].clientY + touches[1].clientY) / 2;
    }
  });

  touchSurface.addEventListener('touchmove', (e) => {
    e.preventDefault();
    const touches = e.touches;
    const rect = touchSurface.getBoundingClientRect();
    const now = performance.now();

    if (touches.length === 1 && !isMultiTouch) {
      // 16ms throttle (~60fps) prevents packet congestion while feeling instant
      if (now - lastMouseMoveTime >= 15) {
        lastMouseMoveTime = now;
        const currentX = touches[0].clientX - rect.left;
        const currentY = touches[0].clientY - rect.top;
        
        const nx = currentX / rect.width;
        const ny = currentY / rect.height;

        sendControl({
          type: 'mouse_move',
          nx: Math.max(0, Math.min(1.0, nx)),
          ny: Math.max(0, Math.min(1.0, ny))
        });

        lastTouchX = currentX;
        lastTouchY = currentY;
      }
    } else if (touches.length === 2) {
      // 2-finger scroll in code editor
      const currentAvgY = (touches[0].clientY + touches[1].clientY) / 2;
      const deltaY = currentAvgY - lastTouchY;
      
      if (Math.abs(deltaY) > 5) {
        const scrollAmount = deltaY > 0 ? 3 : -3;
        sendControl({
          type: 'mouse_scroll',
          dx: 0,
          dy: scrollAmount
        });
        lastTouchY = currentAvgY;
      }
    }
  });

  touchSurface.addEventListener('touchend', (e) => {
    e.preventDefault();
    const duration = performance.now() - touchStartTime;

    // Detect Taps (Duration < 250ms)
    if (duration < 250) {
      if (!isMultiTouch && e.touches.length === 0) {
        // Single Tap = Left Click
        sendControl({ type: 'mouse_click', button: 'left', count: 1 });
      } else if (isMultiTouch) {
        // Two-Finger Tap = Right Click
        sendControl({ type: 'mouse_click', button: 'right', count: 1 });
      }
    }
  });

  // MODIFIER TOGGLE HANDLERS (Ctrl, Alt, Shift)
  document.querySelectorAll('.key-btn.toggleable').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const mod = btn.dataset.modifier;
      activeModifiers[mod] = !activeModifiers[mod];
      
      if (activeModifiers[mod]) {
        btn.classList.add('active');
        if (navigator.vibrate) navigator.vibrate(25);
      } else {
        btn.classList.remove('active');
        if (navigator.vibrate) navigator.vibrate(10);
      }
    });
  });

  // DEVELOPER KEYPAD OVERLAY LOGIC (With Selection & Modifier support)
  document.querySelectorAll('.key-btn').forEach(btn => {
    if (btn.classList.contains('toggleable')) return;

    btn.addEventListener('click', (e) => {
      e.preventDefault();

      if (navigator.vibrate) {
        navigator.vibrate(15);
      }

      const key = btn.dataset.key;
      const shortcut = btn.dataset.shortcut;
      const symbol = btn.dataset.type;

      if (shortcut) {
        // Direct shortcut like ctrl,a or shift,left or ctrl,c
        const keysArr = shortcut.split(',');
        sendControl({ type: 'shortcut', keys: keysArr });
      } else if (key) {
        // Check if Shift or Ctrl is active for selection
        const keysToSend = [];
        if (activeModifiers.ctrl) keysToSend.push('ctrl');
        if (activeModifiers.alt) keysToSend.push('alt');
        if (activeModifiers.shift) keysToSend.push('shift');

        if (keysToSend.length > 0) {
          keysToSend.push(key);
          sendControl({ type: 'shortcut', keys: keysToSend });
        } else {
          sendControl({ type: 'key_press', key: key });
        }
      } else if (symbol) {
        sendControl({ type: 'type_text', text: symbol });
      }
    });
  });

  // TOGGLE SELECTION / EDITING BAR
  if (toggleEditModeBtn && selectionRow) {
    toggleEditModeBtn.addEventListener('click', () => {
      selectionRow.classList.toggle('hidden');
    });
  }

  // NATIVE KEYBOARD SYNC
  toggleKeyboardBtn.addEventListener('click', () => {
    hiddenKeyboardInput.focus();
  });

  hiddenKeyboardInput.addEventListener('input', (e) => {
    const text = e.target.value;
    if (text.length > 0) {
      sendControl({ type: 'type_text', text: text });
      hiddenKeyboardInput.value = '';
    }
  });

  hiddenKeyboardInput.addEventListener('keydown', (e) => {
    if (e.key === 'Backspace') {
      sendControl({ type: 'key_press', key: 'backspace' });
    } else if (e.key === 'Enter') {
      sendControl({ type: 'key_press', key: 'enter' });
    } else if (e.key === 'Tab') {
      e.preventDefault();
      sendControl({ type: 'key_press', key: 'tab' });
    }
  });

  // SETTINGS CONTROLLER
  settingsBtn.addEventListener('click', () => {
    settingsModal.classList.remove('hidden');
  });

  closeSettingsBtn.addEventListener('click', () => {
    settingsModal.classList.add('hidden');
  });

  qualitySlider.addEventListener('input', (e) => {
    qualityVal.innerText = `${e.target.value}%`;
  });

  qualitySlider.addEventListener('change', (e) => {
    sendControl({
      type: 'settings',
      quality: parseInt(e.target.value)
    });
  });

  resSelect.addEventListener('change', (e) => {
    sendControl({
      type: 'settings',
      target_width: parseInt(e.target.value)
    });
  });

})();

