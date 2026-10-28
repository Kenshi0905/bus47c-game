"""Rebuild editable vector art. Requires fonttools; uses the bundled OFL font.

The playable menu reinterprets the editable Canva layout recorded in docs/menu-design.txt.
SVG paths stay editable in Inkscape, Figma, Blender or any vector editor.
"""
from pathlib import Path
import random
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'work/pythondeps'))
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

OUT = ROOT / 'game/assets/ui'
font = TTFont(OUT / 'fonts/BebasNeue-Regular.ttf')
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
units = font['head'].unitsPerEm
pen = SVGPathPen(glyphs)
cursor = 12
scale = 220 / units
for char in 'BUS 47C':
    name = cmap[ord(char)]
    glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, cursor, 174)))
    cursor += glyphs[name].width * scale + 2
width = round(cursor + 12)
rng = random.Random(4736)
scratches = []
for _ in range(200):
    x, y = rng.uniform(4, width-4), rng.uniform(20, 180)
    w, h = rng.uniform(.5, 5.5), rng.uniform(.4, 2.2)
    scratches.append(f'<path d="M{x:.2f} {y:.2f}l{w:.2f} -1 .8 {h:.2f} -{w:.2f} 1Z" fill="black"/>')
logo = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="192" viewBox="0 0 {width} 192">
<title>Bus 47C distressed night service wordmark</title>
<defs><mask id="weathering"><rect width="{width}" height="192" fill="white"/>{''.join(scratches)}</mask></defs>
<g id="editable-letter-outlines" fill="#e3decd" mask="url(#weathering)"><path d="{pen.getCommands()}"/></g>
<g id="haunted-bus-emblem" transform="translate({width-109},118)" stroke="#e3decd" stroke-width="2" fill="#121917">
<path d="M5 7 10 2 45 2 50 7 52 48 3 48Z"/><path d="M9 12H46V31H9Z"/><path d="M27 12V31M11 36H44M12 40H43" fill="none"/>
<path d="M8 48V55H17V48M38 48V55H47V48"/><path d="M0 15H4M51 15H55"/>
<path d="M6 34H13V38H6ZM42 34H49V38H42Z" fill="#b63f35" stroke="none"/>
<path d="M14 6H41V9H14Z" fill="#e3decd" stroke="none"/>
</g></svg>'''
(OUT / 'bus47c-logo.svg').write_text(logo, encoding='utf-8')

# Irregular opaque brush, with genuinely transparent chips at the ends.
points = [(4, 6), (57, 3), (140, 6), (208, 2), (292, 6), (358, 3), (352, 10), (361, 13), (353, 20), (359, 26), (350, 29), (354, 36), (291, 35), (225, 39), (152, 36), (78, 39), (7, 35), (12, 30), (3, 25), (8, 20), (2, 14), (9, 11)]
brush = '<svg xmlns="http://www.w3.org/2000/svg" width="364" height="42" viewBox="0 0 364 42"><title>Selected menu brush</title><path fill="#ded9c8" d="M' + 'L'.join(f'{x} {y}' for x,y in points) + 'Z"/></svg>'
(OUT / 'selection-brush.svg').write_text(brush, encoding='utf-8')
print('Wrote editable logo and selection SVGs.')
