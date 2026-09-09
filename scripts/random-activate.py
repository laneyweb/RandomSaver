#!/usr/bin/env python3
"""Random screensaver activation: picks a random word and renders ASCII art."""
import os
import random
import subprocess
import sys

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALLED_DIR = os.path.join(
    os.path.expanduser("~"), ".config/omarchy/plugins/darren.randomsaver"
)
BASE_DIR = INSTALLED_DIR if os.path.isdir(INSTALLED_DIR) else REPO_DIR

WORD_FILE = os.path.join(BASE_DIR, "words.txt")
RENDER_SCRIPT = os.path.join(BASE_DIR, "scripts", "render.sh")
OUTPUT = os.path.join(
    os.path.expanduser("~"), ".config/omarchy/branding/screensaver.txt"
)


def main():
    try:
        with open(WORD_FILE) as f:
            words = [w.strip() for w in f.read().splitlines() if w.strip()]
    except OSError:
        words = []

    if not words:
        words = ["hello"]

    chosen = random.choice(words)
    subprocess.run(["bash", RENDER_SCRIPT, chosen, OUTPUT], check=True)
    print(f"RandomSaver activated with: {chosen}")


if __name__ == "__main__":
    sys.exit(main())
