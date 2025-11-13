# -*- coding: utf-8 -*-
"""
Jarvis (version SUPERCAL — héritage + améliorations)
----------------------------------------------------
✅ Conserve toutes tes anciennes fonctionnalités (HUD, commandes FR, YouTube, TTS, Mistral/Ollama,
   surveillance par webcam, journalisation, préférence WO Mic) ET ajoute des sécurités/robustesses :
   - pyttsx3 via file/worker (anti-crash)
   - Écoute micro robuste (timeouts, UnknownValueError silencieux)
   - Healthcheck + autostart d'Ollama (serve) avant /api/generate
   - YouTube par raccourcis clavier (pas de coordonnées absolues)
   - Surveillance caméra avec cooldown + **déclenchement auto** sur activité clavier/souris (pynput)
   - Logging rotatif
   - Nettoyage des listeners à l’arrêt
   - + Intentions supplémentaires : Google, ouvrir Chrome, WhatsApp Web, commandes médias (play/pause/volume)

Dépendances (pip) :
    pip install pyttsx3 SpeechRecognition pyautogui opencv-python requests psutil pyaudio pynput

Conseils Windows :
- Autorise l’accès micro/caméra dans Paramètres Windows.
- Si pyttsx3 plante sur la voix : choisis une voix **Desktop** dans le panneau Text‑to‑Speech classique.
"""
from __future__ import annotations

import os
import re
import time
import queue
import psutil
import threading
import datetime as dt
import logging
from logging.handlers import RotatingFileHandler
import subprocess
import requests
import webbrowser

# GUI / Audio / Vision
import tkinter as tk
import speech_recognition as sr
import pyttsx3
import pyautogui
import cv2

# Activité clavier/souris
from pynput import keyboard, mouse

# -----------------------------
# Configuration
# -----------------------------
APP_NAME = "Jarvis"
LOG_FILE = "journal_jarvis.log"
OLLAMA_URL = "http://127.0.0.1:11434"
OLLAMA_MODEL = "mistral"
ASR_LANGUAGE = "fr-FR"
ASR_TIMEOUT = 6            # temps pour commencer à parler (s)
ASR_PHRASE_LIMIT = 15      # durée max d'une phrase (s)

SURV_COOLDOWN_S = 10       # délai mini entre deux captures (s)

# Préférence micro (WO Mic en priorité si présent)
PREFERRED_MIC_KEYWORDS = ["wo mic", "wo mic device"]

# Emplacements typiques d'applis (Chrome)
PATHS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
]

# -----------------------------
# Journalisation
# -----------------------------
logger = logging.getLogger(APP_NAME)
logger.setLevel(logging.INFO)
_handler = RotatingFileHandler(LOG_FILE, maxBytes=1_000_000, backupCount=3, encoding="utf-8")
_formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
_handler.setFormatter(_formatter)
logger.addHandler(_handler)

# -----------------------------
# HUD Tkinter
# -----------------------------
class JarvisHUD(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(APP_NAME)
        self.geometry("420x260+40+40")
        self.configure(bg="#0f172a")  # slate-900
        self.overrideredirect(False)

        self.lbl_status = tk.Label(self, text=f"{APP_NAME} prêt.", fg="#e2e8f0", bg="#0f172a", font=("Segoe UI", 11))
        self.lbl_status.pack(pady=10)

        self.txt = tk.Text(self, height=10, width=52, bg="#0b1220", fg="#cbd5e1", insertbackground="#cbd5e1",
                           font=("Consolas", 10), wrap="word")
        self.txt.pack(padx=10, pady=6, fill="both", expand=True)

        self.btn_row = tk.Frame(self, bg="#0f172a")
        self.btn_row.pack(pady=4)
        tk.Button(self.btn_row, text="Activer sécurité", command=lambda: activer_surveillance(True)).pack(side="left", padx=4)
        tk.Button(self.btn_row, text="Désactiver sécurité", command=desactiver_surveillance).pack(side="left", padx=4)
        tk.Button(self.btn_row, text="Capture", command=lambda: [prendre_photo_intrus(), parler("Capture effectuée.")]).pack(side="left", padx=4)
        tk.Button(self.btn_row, text="Quitter", command=self.on_quit).pack(side="left", padx=4)

        self.bind("<Escape>", lambda e: self.on_quit())

        self._queue = queue.Queue()
        self.after(100, self._process_queue)

    def _process_queue(self):
        try:
            while True:
                msg, kind = self._queue.get_nowait()
                if kind == "status":
                    self.lbl_status.config(text=msg)
                elif kind == "append":
                    self.txt.insert("end", msg + "\n")
                    self.txt.see("end")
                self._queue.task_done()
        except queue.Empty:
            pass
        self.after(100, self._process_queue)

    def set_status(self, text: str):
        self._queue.put((text, "status"))

    def append(self, text: str):
        self._queue.put((text, "append"))

    def on_quit(self):
        try:
            arreter_listeners()
        except Exception:
            pass
        self.destroy()


HUD: JarvisHUD | None = None


# -----------------------------
# TTS sécurisé (file + worker)
# -----------------------------
_tts_engine = None
_tts_queue = queue.Queue()


def _select_valid_voice(engine: pyttsx3.Engine):
    try:
        voices = engine.getProperty('voices')
        for v in voices:
            if "desktop" in (v.name or "").lower() or "desktop" in (v.id or "").lower():
                engine.setProperty('voice', v.id)
                return
        if voices:
            engine.setProperty('voice', voices[0].id)
    except Exception as e:
        logger.warning(f"Sélection voix échouée: {e}")


def _tts_worker():
    while True:
        text = _tts_queue.get()
        try:
            if _tts_engine is not None and text:
                _tts_engine.say(text)
                _tts_engine.runAndWait()
        except Exception as e:
            logger.error(f"TTS error: {e}")
        finally:
            _tts_queue.task_done()


def init_tts():
    global _tts_engine
    try:
        engine = pyttsx3.init()
        _select_valid_voice(engine)
        _tts_engine = engine
        threading.Thread(target=_tts_worker, daemon=True).start()
        return True
    except Exception as e:
        logger.error(f"pyttsx3 init échouée: {e}")
        return False


def parler(message: str):
    if HUD:
        HUD.append(f"🧠 {message}")
    logger.info(f"SAY: {message}")
    _tts_queue.put(message)


# -----------------------------
# ASR / Micro
# -----------------------------
_recognizer = sr.Recognizer()


def lister_microphones():
    try:
        return sr.Microphone.list_microphone_names()
    except Exception:
        return []


def get_microphone_index() -> int | None:
    noms = lister_microphones()
    if not noms:
        return None
    low = [n.lower() for n in noms]
    for kw in PREFERRED_MIC_KEYWORDS:
        if kw in low:
            return low.index(kw)
    return None


def ecouter() -> str:
    idx = get_microphone_index()
    if HUD:
        HUD.set_status("🎙️ Écoute… (parle)")
    try:
        with sr.Microphone(device_index=idx) as source:
            _recognizer.adjust_for_ambient_noise(source, duration=0.5)
            audio = _recognizer.listen(source, timeout=ASR_TIMEOUT, phrase_time_limit=ASR_PHRASE_LIMIT)
        try:
            txt = _recognizer.recognize_google(audio, language=ASR_LANGUAGE)
            s = txt.strip().lower()
            if HUD and s:
                HUD.append(f"🗣️ Tu as dit : {s}")
            return s
        except sr.UnknownValueError:
            return ""
        except sr.RequestError as e:
            logger.warning(f"ASR request error: {e}")
            return ""
    except sr.WaitTimeoutError:
        return ""
    except Exception as e:
        logger.error(f"ASR error: {e}")
        return ""
    finally:
        if HUD:
            HUD.set_status(f"{APP_NAME} prêt.")


# -----------------------------
# Ollama (serve + healthcheck + génération)
# -----------------------------

def ollama_est_dispo() -> bool:
    try:
        r = requests.get(f"{OLLAMA_URL}/api/tags", timeout=1.5)
        return r.status_code == 200
    except Exception:
        return False


def lancer_ollama_si_non_actif(timeout_s: int = 20):
    if ollama_est_dispo():
        logger.info("Ollama déjà dispo.")
        return True
    for p in psutil.process_iter(['name']):
        if (p.info.get('name') or '').lower().startswith('ollama'):
            for _ in range(timeout_s):
                if ollama_est_dispo():
                    logger.info("Ollama prêt (process existant).")
                    return True
                time.sleep(1)
            break
    try:
        creation = subprocess.CREATE_NEW_CONSOLE if os.name == 'nt' else 0
        subprocess.Popen(["ollama", "serve"], creationflags=creation)
    except Exception as e:
        logger.error(f"Impossible de lancer ollama serve: {e}")
        return False
    for _ in range(timeout_s):
        if ollama_est_dispo():
            logger.info("Ollama prêt (serve).")
            return True
        time.sleep(1)
    logger.warning("Ollama ne répond pas sur 11434.")
    return False


def llm_repond(prompt: str, temperature: float = 0.6) -> str:
    ok = lancer_ollama_si_non_actif()
    if not ok:
        return "Le moteur local (Ollama) n'est pas disponible."
    try:
        payload = {
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "options": {"temperature": temperature},
            "stream": False
        }
        r = requests.post(f"{OLLAMA_URL}/api/generate", json=payload, timeout=60)
        if r.status_code == 200:
            data = r.json()
            return (data.get("response") or "").strip()
        else:
            logger.error(f"Ollama HTTP {r.status_code}: {r.text[:200]}")
            return "Erreur du moteur local."
    except Exception as e:
        logger.error(f"Ollama req error: {e}")
        return "Erreur de connexion au moteur local."


# -----------------------------
# Surveillance / Listeners
# -----------------------------
_derniere_photo_ts = 0.0
surveillance_active = False
_listeners: list = []


def _cooldown_ok() -> bool:
    global _derniere_photo_ts
    now = time.time()
    if now - _derniere_photo_ts >= SURV_COOLDOWN_S:
        _derniere_photo_ts = now
        return True
    return False


def prendre_photo_intrus(path: str | None = None):
    if not _cooldown_ok():
        return
    nom = path or f"intrus_{dt.datetime.now():%Y-%m-%d_%H-%M-%S}.jpg"
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        logger.warning("Caméra non disponible")
        return
    ret, frame = cap.read()
    if ret:
        cv2.imwrite(nom, frame)
        logger.info(f"Photo: {nom}")
        if HUD:
            HUD.append(f"📸 Photo capturée: {nom}")
    cap.release()
    cv2.destroyAllWindows()


def _on_key_event(key):
    if surveillance_active:
        prendre_photo_intrus()


def _on_mouse_event(*args, **kwargs):
    if surveillance_active:
        prendre_photo_intrus()


def activer_surveillance(announce: bool = False):
    global surveillance_active
    if surveillance_active:
        if announce:
            parler("La sécurité est déjà activée.")
        return
    surveillance_active = True

    # Listeners clavier + souris
    kb = keyboard.Listener(on_press=_on_key_event)
    ms = mouse.Listener(on_move=_on_mouse_event, on_click=_on_mouse_event, on_scroll=_on_mouse_event)
    kb.start()
    ms.start()
    _listeners.extend([kb, ms])

    if HUD:
        HUD.append("🛡️ Sécurité ACTIVÉE (photo sur activité)")
    if announce:
        parler("Sécurité activée.")


def desactiver_surveillance():
    global surveillance_active
    surveillance_active = False
    arreter_listeners()
    if HUD:
        HUD.append("🛡️ Sécurité désactivée")
    parler("Sécurité désactivée.")


def arreter_listeners():
    global _listeners
    for l in list(_listeners):
        try:
            l.stop()
        except Exception:
            pass
    _listeners.clear()


# -----------------------------
# Actions utiles
# -----------------------------

def action_heure():
    maintenant = dt.datetime.now().strftime("%H:%M")
    parler(f"Il est {maintenant}.")


def action_date():
    today = dt.datetime.now().strftime("%A %d %B %Y")
    parler(f"Nous sommes le {today}.")


def ouvrir_chrome():
    for p in PATHS:
        if os.path.exists(p):
            try:
                os.startfile(p)
                return True
            except Exception:
                pass
    try:
        subprocess.Popen(["start", "", "chrome"], shell=True)
        return True
    except Exception:
        return False


def ouvrir_url(url: str):
    try:
        webbrowser.open(url)
        return True
    except Exception:
        return False


def action_youtube_recherche(termes: str):
    pyautogui.hotkey('ctrl', 'l')
    pyautogui.typewrite('https://www.youtube.com\n', interval=0.02)
    time.sleep(2.5)
    pyautogui.press('/')
    pyautogui.typewrite(termes + '\n', interval=0.03)
    parler(f"Recherche YouTube pour {termes}")


def action_google_recherche(termes: str):
    url = f"https://www.google.com/search?q={requests.utils.quote(termes)}"
    ouvrir_url(url)
    parler(f"Recherche Google pour {termes}")


def action_whatsapp_web():
    ouvrir_url("https://web.whatsapp.com")
    parler("Ouverture de WhatsApp Web")


def media_play_pause():
    pyautogui.press('space')  # fonctionne sur YouTube focalisé


def media_volume(up=True):
    key = 'volumeup' if up else 'volumedown'
    try:
        pyautogui.press(key)
    except Exception:
        pass


# -----------------------------
# Intentions (NLU minimaliste)
# -----------------------------
INTENTS = [
    (re.compile(r"\b(quelle heure|il est quelle heure|heure)\b"), lambda m: action_heure()),
    (re.compile(r"\b(quelle date|quel jour|date)\b"), lambda m: action_date()),

    # Sécurité
    (re.compile(r"\b(active(r)?|lance(r)?) la s[ée]curit[ée]\b|\bsurveillance on\b"), lambda m: activer_surveillance(True)),
    (re.compile(r"\b(d[ée]sactive(r)?|retire(r)?) la s[ée]curit[ée]\b|\bsurveillance off\b"), lambda m: desactiver_surveillance()),
    (re.compile(r"\b(photo|capture|intrus)\b"), lambda m: [prendre_photo_intrus(), parler("Capture effectuée.")]),

    # Apps / Web
    (re.compile(r"\b(ouvre|lance) (chrome|navigateur)\b"), lambda m: parler("Chrome ouvert.") if ouvrir_chrome() else parler("Impossible d'ouvrir Chrome.")),
    (re.compile(r"\b(ouvre|lance) (whatsapp|whatsapp web)\b"), lambda m: action_whatsapp_web()),
    (re.compile(r"\b(ouvre|va sur) youtube\b"), lambda m: ouvrir_url("https://www.youtube.com") or parler("YouTube ouvert.")),

    # Médias
    (re.compile(r"\b(pause|reprends|lecture|play)\b"), lambda m: media_play_pause()),
    (re.compile(r"\b(volume \+|augmente le volume)\b"), lambda m: media_volume(True)),
    (re.compile(r"\b(volume -|baisse le volume)\b"), lambda m: media_volume(False)),

    # Quitter
    (re.compile(r"\b(quit|quitte|arrête|stop)\b"), lambda m: (_ for _ in ()).throw(SystemExit())),
]


def interpreter_commande(texte: str):
    if not texte:
        return

    # YouTube avec termes
    m = re.search(r"(?:youtube|recherche youtube) (.+)$", texte)
    if m:
        termes = m.group(1).strip()
        if termes:
            action_youtube_recherche(termes)
            return

    # Google avec termes
    m = re.search(r"(?:google|recherche google|cherche sur google) (.+)$", texte)
    if m:
        termes = m.group(1).strip()
        if termes:
            action_google_recherche(termes)
            return

    for pattern, fn in INTENTS:
        if pattern.search(texte):
            try:
                fn(None)
            except StopIteration:
                raise SystemExit
            return

    # Sinon LLM local
    reponse = llm_repond(texte)
    parler(reponse or "Je n'ai pas compris.")


# -----------------------------
# Boucle principale
# -----------------------------

def boucle_principale():
    parler("Bonjour, je suis prêt.")
    while True:
        try:
            cmd = ecouter()
            if not cmd:
                continue
            interpreter_commande(cmd)
        except SystemExit:
            parler("Au revoir !")
            break
        except Exception as e:
            logger.exception(f"Erreur boucle: {e}")
            if HUD:
                HUD.append(f"❌ Erreur: {e}")
            time.sleep(0.5)


# -----------------------------
# Entrée programme
# -----------------------------
if __name__ == "__main__":
    try:
        pyautogui.FAILSAFE = True  # coin haut gauche = arrêt d'urgence

        HUD = JarvisHUD()
        HUD.set_status(f"{APP_NAME} prêt.")
        HUD.append("Démarrage…")

        if not init_tts():
            if HUD:
                HUD.append("⚠️ TTS pyttsx3 indisponible.")

        # LLM lancé à la demande (lazy)

        t = threading.Thread(target=boucle_principale, daemon=True)
        t.start()

        HUD.mainloop()
    except KeyboardInterrupt:
        pass
    finally:
        desactiver_surveillance()
        logger.info("Extinction.")

