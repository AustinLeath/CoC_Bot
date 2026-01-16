import loguru
import warnings

loguru.logger.remove()
warnings.filterwarnings("ignore", category=UserWarning, module='torch')

import sys
import time
import psutil
import requests
import subprocess
import utils
from utils import *
from configs import *
from upgrader import Upgrader
from attacker import Attacker

class CoC_Bot:
    def __init__(self):
        if DISABLE_DEEVICE_SLEEP:
            disable_sleep()
            Exit_Handler.register(enable_sleep)
        
        self.start_bluestacks()
        self.upgrader = Upgrader()
        self.attacker = Attacker()

    # ============================================================
    # 🖥️ System & Emulator Management
    # ============================================================
    
    def update_status(self, status):
        if WEB_APP_URL == "": return
        for _ in range(5):
            try:
                requests.post(
                    f"{WEB_APP_URL}/{utils.INSTANCE_ID}/status",
                    auth=(WEB_APP_AUTH_USERNAME, WEB_APP_AUTH_PASSWORD),
                    json={"status": status},
                    timeout=(10, 20)
                )
                return
            except Exception as e:
                if configs.DEBUG: print("update_status", e)
    
    def start_web_app(self):
        proc = subprocess.Popen(
            [sys.executable, "./app/app.py"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.STDOUT,
        )
        def cleanup():
            try:
                proc.terminate()
            except Exception:
                pass
        Exit_Handler.register(cleanup)
    
    def start_bluestacks(self):
        if sys.platform == "darwin":
            subprocess.Popen([
                "osascript", "-e",
                'tell application "BlueStacks" to launch\n'
                'tell application "BlueStacks" to set visible of front window to false'
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif sys.platform == "win32":
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 6
            subprocess.Popen([r"C:\Program Files\BlueStacks_nxt\HD-Player.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, startupinfo=startupinfo)
        
        for _ in range(120):
            if self.check_bluestacks(): break
            time.sleep(0.5)
        if configs.DEBUG: print("BlueStacks started.")
        
        for _ in range(120):
            try:
                connect_adb()
                return
            except Exception as e:
                if configs.DEBUG: print("start_bluestacks", e)
            time.sleep(0.5)
        if configs.DEBUG: print("Connected to ADB.")
        
        raise Exception("BlueStacks failed to start.")
    
    def check_bluestacks(self):
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] and 'bluestacks' in proc.info['name'].lower():
                return True
        return False

    # ============================================================
    # ⏱️ Task Execution
    # ============================================================
    
    def run(self):
        print("Starting CoC Bot main loop")
        while True:
            try:
                print("Main loop iteration started")
                if not running():
                    print("Bot is paused or not running, sleeping 1 second")
                    time.sleep(1)
                    continue

                print("Bot is active, attempting to start CoC")
                if start_coc():
                    print("CoC started successfully, updating status to active")
                    self.update_status("now")

                    # Check home base
                    if UPGRADE_HOME_BASE:
                        print("Home base upgrades enabled, navigating to home base")
                        to_home_base()
                        print("Starting home base upgrades")
                        self.upgrader.run_home_base()
                    if ATTACK_HOME_BASE:
                        if not UPGRADE_HOME_BASE:
                            print("Home base attacks enabled, navigating to home base")
                            to_home_base()
                        print("Starting home base attacks")
                        self.attacker.run_home_base(restart=UPGRADE_BUILDER_BASE or ATTACK_BUILDER_BASE)

                    # Check builder base
                    if UPGRADE_BUILDER_BASE:
                        print("Builder base upgrades enabled, navigating to builder base")
                        to_builder_base()
                        print("Collecting builder base attack elixir")
                        self.upgrader.collect_builder_attack_elixir()
                        print("Starting builder base upgrades")
                        self.upgrader.run_builder_base()
                    if ATTACK_BUILDER_BASE:
                        if not UPGRADE_BUILDER_BASE:
                            print("Builder base attacks enabled, navigating to builder base")
                            to_builder_base()
                        print("Starting builder base attacks")
                        self.attacker.run_builder_base(restart=False)

                    print("All tasks completed, returning to home base")
                    to_home_base()
                    print("Sleeping 2 seconds before stopping CoC")
                    time.sleep(2)

                    #print("Stopping CoC")
                    #stop_coc()
                    print("CoC stopped, updating status with completion time")
                    self.update_status(time.time())

                print(f"Sleeping for {CHECK_INTERVAL} seconds before next cycle")
                time.sleep(CHECK_INTERVAL)

            except Exception as e:
                print(f"Exception in main loop: {e}")
                print("Stopping CoC due to error")
                stop_coc()
                print("Updating status to error")
                self.update_status("error")
