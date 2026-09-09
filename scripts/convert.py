#!/usr/bin/env python3
"""Local ASCII art conversion using bundled pyfiglet and Delta Corps Priest 1 font."""
import sys
import os

# Ensure bundled pyfiglet is importable
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

# Point pyfiglet to our bundled font directory
os.environ['SHARED_DIRECTORY'] = os.path.join(os.path.dirname(__file__), '..', 'fonts')

from pyfiglet import Figlet

def convert(word, output_path, font_name):
    f = Figlet(font=font_name)
    art = f.renderText(word)
    with open(output_path, 'w') as out:
        out.write(art)

if __name__ == '__main__':
    word = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else '/home/darren/.config/omarchy/branding/screensaver.txt'
    font_name = "Delta Corps Priest 1"
    convert(word, output, font_name)
