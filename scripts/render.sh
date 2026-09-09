#!/bin/bash
# RandomSaver ASCII renderer.
#
# Third-party code notice: the awk engine and embedded Delta Corps Priest 1
# font below are adapted from omacom/omarchy bin/omarchy-ascii
# (https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-ascii),
# Copyright (c) David Heinemeier Hansson, MIT License. Full text in
# THIRD-PARTY-NOTICES at the repo root. Changes vs upstream: CLI contract is
#   render.sh "<text>" <output_file>
# (upstream reads args/stdin and prints to stdout; we take a word + output
# path). The awk program and font data themselves are unchanged.
#
# Delta Corps Priest 1 draws letters and spaces only. Digits and punctuation
# have no glyph in it, so they are skipped (noted on stderr).

set -o pipefail

usage() {
  cat <<'EOF'
Usage: render.sh "<text>" <output_file>

Renders text as ASCII art in Delta Corps Priest 1 and writes it to
<output_file>. Same engine as `omarchy ascii`.
EOF
}

if (( $# != 2 )); then
  usage >&2
  exit 1
fi

text="$1"
output="$2"

if [[ -z ${text//[[:space:]]/} ]]; then
  echo "Nothing to render" >&2
  exit 1
fi

if [[ -z $output ]]; then
  echo "No output file given" >&2
  exit 1
fi

# The text arrives as awk's input, one record per line, and the font on a
# descriptor of its own. Handing the text to awk as a variable instead would
# read backslash escapes in it as awk's own, and would put a long text through
# the argument list, which has a size limit that a piped one does not.
awk '
function rtrim(s) {
  sub(/ +$/, "", s)
  return s
}

function ltrim(s) {
  sub(/^ +/, "", s)
  return s
}

# A single-character replacement that never treats its needle as a pattern,
# because the hardblank is "$" in this font and would anchor a regex instead.
function replace(s, from, to,   at, result) {
  while ((at = index(s, from)) > 0) {
    result = result substr(s, 1, at - 1) to
    s = substr(s, at + 1)
  }

  return result s
}

function load_font(   line, header, position, code, i) {
  while ((getline line < FONT) > 0) {
    font_line++

    if (font_line == 1) {
      split(line, header, " ")
      hardblank = substr(header[1], length(header[1]))
      height = header[2]
      comment_lines = header[6]
      continue
    }

    if (font_line <= comment_lines + 1) {
      continue
    }

    # Glyphs follow the comments in character order from 32, `height` lines
    # each, every line closed by the endmark the first one introduces.
    position = font_line - comment_lines - 2
    code = 32 + int(position / height)
    if (code > 126) {
      continue
    }

    if (endmark == "") {
      endmark = substr(line, length(line))
    }

    while (length(line) > 0 && substr(line, length(line)) == endmark) {
      line = substr(line, 1, length(line) - 1)
    }

    for (i = 1; i <= blocks; i++) {
      gsub(block[i], stand_in[i], line)
    }

    # The hardblank becomes a marker here, while the string is one glyph wide,
    # so printing a finished row is a single pass rather than one rescan per
    # hardblank in it.
    line = replace(line, hardblank, hardblank_mark)

    glyph[code, position % height] = line
    if (length(line) > width[code]) {
      width[code] = length(line)
    }
  }

  close(FONT)
}

function drawable(source,   chars, total, i, code) {
  total = split(source, chars, "")
  for (i = 1; i <= total; i++) {
    code = code_of[chars[i]]
    if (code != "" && width[code] > 0) {
      return 1
    }
  }

  return 0
}

# Lay one glyph beside what is drawn so far, kerned: slid left until the two
# would touch, which is the smallest run of blanks between them across all rows.
function draw(source,   chars, total, i, r, ch, code, piece, glyph_width, out, trail, amount, lead, cut, keep, remaining, fragment, body, pad, line, drew) {
  total = split(source, chars, "")
  drew = 0

  for (i = 1; i <= total; i++) {
    ch = chars[i]
    code = code_of[ch]

    if (code == "" || width[code] == 0) {
      if (!(ch in skipped)) {
        skipped[ch] = 1
        skipped_list[++skipped_total] = (ch in escaped) ? escaped[ch] : ch
      }

      continue
    }

    glyph_width = width[code]
    for (r = 0; r < height; r++) {
      piece[r] = sprintf("%-" glyph_width "s", glyph[code, r])
    }

    if (!drew) {
      for (r = 0; r < height; r++) {
        out[r] = rtrim(piece[r])
        trail[r] = glyph_width - length(out[r])
      }

      drew = 1
      continue
    }

    amount = -1
    for (r = 0; r < height; r++) {
      lead = glyph_width - length(ltrim(piece[r]))
      if (amount < 0 || trail[r] + lead < amount) {
        amount = trail[r] + lead
      }
    }

    # Every row gives up the same number of columns, taken from its own trailing
    # blanks first and from the glyph leading ones once those run out. A row is
    # held without its trailing blanks, counted in trail[] instead, so placing a
    # glyph costs its own width rather than the width of the art so far -- which
    # is what keeps a long line from taking time in the square of its length.
    for (r = 0; r < height; r++) {
      cut = (amount < trail[r]) ? amount : trail[r]
      keep = amount - cut
      remaining = trail[r] - cut
      fragment = substr(piece[r], keep + 1)
      body = rtrim(fragment)

      if (body == "") {
        trail[r] = remaining + length(fragment)
      } else {
        pad = (remaining > 0) ? sprintf("%" remaining "s", "") : ""
        out[r] = out[r] pad body
        trail[r] = length(fragment) - length(body)
      }
    }
  }

  # A line that drew nothing still occupies its block, the way a blank line
  # between two words of art does, so the art keeps the shape of the text.
  for (r = 0; r < height; r++) {
    line = out[r]
    for (i = 1; i <= blocks; i++) {
      gsub(stand_in[i], block[i], line)
    }

    gsub(hardblank_mark, " ", line)
    sub(/ +$/, "", line)
    print line
  }
}

BEGIN {
  FONT = "/dev/fd/3"

  # The font draws with five block characters, and the layout above is column
  # arithmetic. Each one becomes a single byte for the duration and turns back
  # at print time, so length() and substr() count columns no matter what the
  # locale believes a character is.
  blocks = split("█ ▀ ▄ ▌ ▐", block, " ")
  for (i = 1; i <= blocks; i++) {
    stand_in[i] = sprintf("%c", i)
  }

  hardblank_mark = sprintf("%c", blocks + 1)

  for (i = 32; i <= 126; i++) {
    code_of[sprintf("%c", i)] = i
  }

  # Skipped characters are named on stderr, and a control character named there
  # would reach the terminal as a control character. Name those by code.
  for (i = 1; i < 32; i++) {
    escaped[sprintf("%c", i)] = sprintf("\\x%02x", i)
  }

  escaped[sprintf("%c", 127)] = "\\x7f"

  load_font()

  if (height == "") {
    print "Could not read the embedded font." >"/dev/stderr"
    aborted = 1
    exit 1
  }
}

{
  source[++source_count] = $0
  if (drawable($0)) {
    any_drawable = 1
  }
}

END {
  if (aborted) {
    exit 1
  }

  if (!any_drawable) {
    print "Delta Corps Priest 1 draws letters and spaces only, and that text has neither." >"/dev/stderr"
    exit 1
  }

  for (i = 1; i <= source_count; i++) {
    draw(source[i])
  }

  if (skipped_total > 0) {
    list = skipped_list[1]
    for (i = 2; i <= skipped_total; i++) {
      list = list " " skipped_list[i]
    }

    print "Skipped, no glyph in Delta Corps Priest 1: " list >"/dev/stderr"
  }
}
' 3<<'DELTA_CORPS_PRIEST_1' <<<"$text" >"$output"
flf2a$ 9 8 19 0 3 0 64 0
Font Author: CoSMiC cHiLD

FIGFont created by patorjk.com's FIGFont Editor: http://patorjk.com/figfont-editor
$   $@
$   $@
$   $@
$   $@
$   $@
$   $@
$   $@
$   $@
$   $@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
   ▄████████$@
  ███    ███$@
  ███    ███$@
  ███    ███$@
▀███████████$@
  ███    ███$@
  ███    ███$@
  ███    █▀ $@
             @@
▀█████████▄ $@
  ███    ███$@
  ███    ███$@
 ▄███▄▄▄██▀ $@
▀▀███▀▀▀██▄ $@
  ███    ██▄$@
  ███    ███$@
▄█████████▀ $@
             @@
 ▄████████$@
███    ███$@
███    █▀ $@
███       $@
███       $@
███    █▄ $@
███    ███$@
████████▀ $@
           @@
████████▄ $@
███   ▀███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███   ▄███$@
████████▀ $@
           @@
   ▄████████$@
  ███    ███$@
  ███    █▀ $@
 ▄███▄▄▄    $@
▀▀███▀▀▀    $@
  ███    █▄ $@
  ███    ███$@
  ██████████$@
             @@
   ▄████████$@
  ███    ███$@
  ███    █▀ $@
 ▄███▄▄▄    $@
▀▀███▀▀▀    $@
  ███       $@
  ███       $@
  ███       $@
             @@
   ▄██████▄ $@
  ███    ███$@
  ███    █▀ $@
 ▄███       $@
▀▀███ ████▄ $@
  ███    ███$@
  ███    ███$@
  ████████▀ $@
             @@
   ▄█    █▄   $@
  ███    ███  $@
  ███    ███  $@
 ▄███▄▄▄▄███▄▄$@
▀▀███▀▀▀▀███▀ $@
  ███    ███  $@
  ███    ███  $@
  ███    █▀   $@
               @@
 ▄█ $@
███ $@
███▌$@
███▌$@
███▌$@
███ $@
███ $@
█▀  $@
     @@
     ▄█$@
    ███$@
    ███$@
    ███$@
    ███$@
    ███$@
    ███$@
█▄ ▄███$@
▀▀▀▀▀▀ $@@
   ▄█   ▄█▄$@
  ███ ▄███▀$@
  ███▐██▀  $@
 ▄█████▀   $@
▀▀█████▄   $@
  ███▐██▄  $@
  ███ ▀███▄$@
  ███   ▀█▀$@
  ▀        $@@
 ▄█      $@
███      $@
███      $@
███      $@
███      $@
███      $@
███▌    ▄$@
█████▄▄██$@
▀        $@@
   ▄▄▄▄███▄▄▄▄  $@
 ▄██▀▀▀███▀▀▀██▄$@
 ███   ███   ███$@
 ███   ███   ███$@
 ███   ███   ███$@
 ███   ███   ███$@
 ███   ███   ███$@
  ▀█   ███   █▀ $@
                 @@
███▄▄▄▄  $@
███▀▀▀██▄$@
███   ███$@
███   ███$@
███   ███$@
███   ███$@
███   ███$@
 ▀█   █▀ $@
          @@
 ▄██████▄ $@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
 ▀██████▀ $@
           @@
   ▄███████▄$@
  ███    ███$@
  ███    ███$@
  ███    ███$@
▀█████████▀ $@
  ███       $@
  ███       $@
 ▄████▀     $@
             @@
████████▄  $@
███    ███ $@
███    ███ $@
███    ███ $@
███    ███ $@
███    ███ $@
███  ▀ ███ $@
 ▀██████▀▄█$@
            @@
   ▄████████$@
  ███    ███$@
  ███    ███$@
 ▄███▄▄▄▄██▀$@
▀▀███▀▀▀▀▀  $@
▀███████████$@
  ███    ███$@
  ███    ███$@
  ███    ███$@@
   ▄████████$@
  ███    ███$@
  ███    █▀ $@
  ███       $@
▀███████████$@
         ███$@
   ▄█    ███$@
 ▄████████▀ $@
             @@
    ███    $@
▀█████████▄$@
   ▀███▀▀██$@
    ███   ▀$@
    ███    $@
    ███    $@
    ███    $@
   ▄████▀  $@
            @@
███    █▄ $@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
████████▀ $@
           @@
 ▄█    █▄ $@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
 ▀██████▀ $@
           @@
 ▄█     █▄ $@
███     ███$@
███     ███$@
███     ███$@
███     ███$@
███     ███$@
███ ▄█▄ ███$@
 ▀███▀███▀ $@
            @@
▀████    ▐████▀$@
  ███▌   ████▀ $@
   ███  ▐███   $@
   ▀███▄███▀   $@
   ████▀██▄    $@
  ▐███  ▀███   $@
 ▄███     ███▄ $@
████       ███▄$@
                @@
▄██   ▄  $@
███   ██▄$@
███▄▄▄███$@
▀▀▀▀▀▀███$@
▄██   ███$@
███   ███$@
███   ███$@
 ▀█████▀ $@
          @@
 ▄███████▄ $@
██▀     ▄██$@
      ▄███▀$@
 ▀█▀▄███▀▄▄$@
  ▄███▀   ▀$@
▄███▀      $@
███▄     ▄█$@
 ▀████████▀$@
            @@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
   ▄████████$@
  ███    ███$@
  ███    ███$@
  ███    ███$@
▀███████████$@
  ███    ███$@
  ███    ███$@
  ███    █▀ $@
             @@
▀█████████▄ $@
  ███    ███$@
  ███    ███$@
 ▄███▄▄▄██▀ $@
▀▀███▀▀▀██▄ $@
  ███    ██▄$@
  ███    ███$@
▄█████████▀ $@
             @@
 ▄████████$@
███    ███$@
███    █▀ $@
███       $@
███       $@
███    █▄ $@
███    ███$@
████████▀ $@
           @@
████████▄ $@
███   ▀███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███   ▄███$@
████████▀ $@
           @@
   ▄████████$@
  ███    ███$@
  ███    █▀ $@
 ▄███▄▄▄    $@
▀▀███▀▀▀    $@
  ███    █▄ $@
  ███    ███$@
  ██████████$@
             @@
   ▄████████$@
  ███    ███$@
  ███    █▀ $@
 ▄███▄▄▄    $@
▀▀███▀▀▀    $@
  ███       $@
  ███       $@
  ███       $@
             @@
   ▄██████▄ $@
  ███    ███$@
  ███    █▀ $@
 ▄███       $@
▀▀███ ████▄ $@
  ███    ███$@
  ███    ███$@
  ████████▀ $@
             @@
   ▄█    █▄   $@
  ███    ███  $@
  ███    ███  $@
 ▄███▄▄▄▄███▄▄$@
▀▀███▀▀▀▀███▀ $@
  ███    ███  $@
  ███    ███  $@
  ███    █▀   $@
               @@
 ▄█ $@
███ $@
███▌$@
███▌$@
███▌$@
███ $@
███ $@
█▀  $@
     @@
     ▄█$@
    ███$@
    ███$@
    ███$@
    ███$@
    ███$@
    ███$@
█▄ ▄███$@
▀▀▀▀▀▀ $@@
   ▄█   ▄█▄$@
  ███ ▄███▀$@
  ███▐██▀  $@
 ▄█████▀   $@
▀▀█████▄   $@
  ███▐██▄  $@
  ███ ▀███▄$@
  ███   ▀█▀$@
  ▀        $@@
 ▄█      $@
███      $@
███      $@
███      $@
███      $@
███      $@
███▌    ▄$@
█████▄▄██$@
▀        $@@
   ▄▄▄▄███▄▄▄▄  $@
 ▄██▀▀▀███▀▀▀██▄$@
 ███   ███   ███$@
 ███   ███   ███$@
 ███   ███   ███$@
 ███   ███   ███$@
 ███   ███   ███$@
  ▀█   ███   █▀ $@
                 @@
███▄▄▄▄  $@
███▀▀▀██▄$@
███   ███$@
███   ███$@
███   ███$@
███   ███$@
███   ███$@
 ▀█   █▀ $@
          @@
 ▄██████▄ $@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
 ▀██████▀ $@
           @@
   ▄███████▄$@
  ███    ███$@
  ███    ███$@
  ███    ███$@
▀█████████▀ $@
  ███       $@
  ███       $@
 ▄████▀     $@
             @@
████████▄  $@
███    ███ $@
███    ███ $@
███    ███ $@
███    ███ $@
███    ███ $@
███  ▀ ███ $@
 ▀██████▀▄█$@
            @@
   ▄████████$@
  ███    ███$@
  ███    ███$@
 ▄███▄▄▄▄██▀$@
▀▀███▀▀▀▀▀  $@
▀███████████$@
  ███    ███$@
  ███    ███$@
  ███    ███$@@
   ▄████████$@
  ███    ███$@
  ███    █▀ $@
  ███       $@
▀███████████$@
         ███$@
   ▄█    ███$@
 ▄████████▀ $@
             @@
    ███    $@
▀█████████▄$@
   ▀███▀▀██$@
    ███   ▀$@
    ███    $@
    ███    $@
    ███    $@
   ▄████▀  $@
            @@
███    █▄ $@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
████████▀ $@
           @@
 ▄█    █▄ $@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
███    ███$@
 ▀██████▀ $@
           @@
 ▄█     █▄ $@
███     ███$@
███     ███$@
███     ███$@
███     ███$@
███     ███$@
███ ▄█▄ ███$@
 ▀███▀███▀ $@
            @@
▀████    ▐████▀$@
  ███▌   ████▀ $@
   ███  ▐███   $@
   ▀███▄███▀   $@
   ████▀██▄    $@
  ▐███  ▀███   $@
 ▄███     ███▄ $@
████       ███▄$@
                @@
▄██   ▄  $@
███   ██▄$@
███▄▄▄███$@
▀▀▀▀▀▀███$@
▄██   ███$@
███   ███$@
███   ███$@
 ▀█████▀ $@
          @@
 ▄███████▄ $@
██▀     ▄██$@
      ▄███▀$@
 ▀█▀▄███▀▄▄$@
  ▄███▀   ▀$@
▄███▀      $@
███▄     ▄█$@
 ▀████████▀$@
            @@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
@
@
@
@
@
@
@
@
@@
DELTA_CORPS_PRIEST_1
