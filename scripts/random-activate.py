#!/usr/bin/env python3
"""Random screensaver activation: picks a random word and writes ASCII art."""
import sys, os, random
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

word_file = "/home/darren/Work/RandomSaver/words.txt"
with open(word_file) as f:
    words = [w.strip() for w in f.read().splitlines() if w.strip()]

if not words:
    words = ["hello"]

chosen = random.choice(words)
convert_path = "/home/darren/Work/RandomSaver/scripts/convert.py"
os.system(f"python3 {convert_path} \"{chosen}\" /home/darren/.config/omarchy/branding/screensaver.txt")
print(f"RandomSaver activated with: {chosen}")
