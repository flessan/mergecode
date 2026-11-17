#!/usr/bin/env python3
"""Generates Merge Code's original SVG artwork (customers, generators,
backgrounds, effects). Item/UI silhouettes are downloaded Game-Icons assets
(see assets/ASSET_CREDITS.md); everything produced here is original artwork
created for this project and released into the public domain (CC0).

Run:  python3 tools/generate_artwork.py
Outputs are written under assets/ and imported by Godot as textures.
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent


def write(rel: str, svg: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(svg.strip() + "\n")
    print("wrote", rel)


# ---------------------------------------------------------------- customers
# id, skin, hair colour, hair style, shirt, accessory
CUSTOMERS = [
    ("indie_dev",   "#F2C297", "#3B2A20", "cap",      "#4A90D9", "cap"),
    ("startup",     "#8D5524", "#1E1410", "bun",      "#E8873A", "earring"),
    ("student",     "#FFDBAC", "#14100C", "curly",    "#6BCB77", "none"),
    ("sysadmin",    "#C68863", "#5A3A22", "beard",    "#3AA6A0", "beard"),
    ("designer",    "#F2C297", "#B5502A", "long",     "#D96C8A", "glasses"),
    ("data_lead",   "#A0663A", "#100C08", "short",    "#9B6BD9", "beard"),
    ("oss",         "#FFDBAC", "#7A4A21", "scarf",    "#D9A441", "scarf"),
    ("studio",      "#8D5524", "#241812", "short",    "#D96C4A", "glasses"),
]

HAIR_PATHS = {
    "short": '<path d="M60 78 Q60 34 100 34 Q140 34 140 78 Q140 58 124 52 Q100 44 76 52 Q60 58 60 78Z" fill="{h}"/>',
    "curly": '<circle cx="72" cy="52" r="14" fill="{h}"/><circle cx="92" cy="42" r="15" fill="{h}"/><circle cx="112" cy="42" r="15" fill="{h}"/><circle cx="130" cy="54" r="13" fill="{h}"/><path d="M58 84 Q56 40 100 38 Q144 40 142 84 L132 84 Q134 56 100 54 Q66 56 68 84Z" fill="{h}"/>',
    "bun": '<circle cx="100" cy="30" r="13" fill="{h}"/><path d="M60 80 Q60 36 100 36 Q140 36 140 80 Q140 60 122 52 Q100 45 78 52 Q60 60 60 80Z" fill="{h}"/>',
    "long": '<path d="M56 150 Q48 40 100 34 Q152 40 144 150 L128 150 Q136 70 118 54 Q100 46 82 54 Q64 70 72 150Z" fill="{h}"/>',
    "beard": '<path d="M60 78 Q60 34 100 34 Q140 34 140 78 Q140 58 124 52 Q100 44 76 52 Q60 58 60 78Z" fill="{h}"/>',
    "cap": '<path d="M58 72 Q60 30 102 30 Q142 32 142 72 L58 72Z" fill="{h}"/><rect x="48" y="68" width="104" height="10" rx="5" fill="{h}"/>',
    "scarf": '<path d="M52 96 Q46 28 100 26 Q154 28 148 96 Q160 150 138 168 L62 168 Q40 150 52 96Z" fill="{h}"/>',
}


def customer_svg(skin, hair, style, shirt, accessory):
    hair_svg = HAIR_PATHS[style].format(h=hair)
    extra = ""
    if accessory == "beard":
        extra += '<path d="M68 108 Q100 150 132 108 Q128 146 100 148 Q72 146 68 108Z" fill="%s"/>' % hair
    if accessory == "glasses":
        extra += ('<circle cx="82" cy="92" r="13" fill="none" stroke="#333" stroke-width="3.5"/>'
                  '<circle cx="118" cy="92" r="13" fill="none" stroke="#333" stroke-width="3.5"/>'
                  '<path d="M95 92 L105 92" stroke="#333" stroke-width="3.5"/>')
    if accessory == "earring":
        extra += '<circle cx="59" cy="112" r="4.5" fill="#FFD94A"/><circle cx="141" cy="112" r="4.5" fill="#FFD94A"/>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
<rect x="0" y="0" width="200" height="200" rx="28" fill="{shirt}" opacity="0.25"/>
<path d="M28 200 Q32 150 100 148 Q168 150 172 200Z" fill="{shirt}"/>
<rect x="88" y="128" width="24" height="26" rx="8" fill="{skin}"/>
<circle cx="100" cy="92" r="44" fill="{skin}"/>
{hair_svg}
<circle cx="84" cy="90" r="4.5" fill="#2E2A26"/><circle cx="116" cy="90" r="4.5" fill="#2E2A26"/>
<path d="M84 112 Q100 124 116 112" fill="none" stroke="#2E2A26" stroke-width="4" stroke-linecap="round"/>
<circle cx="70" cy="106" r="6" fill="#F0A080" opacity="0.55"/><circle cx="130" cy="106" r="6" fill="#F0A080" opacity="0.55"/>
{extra}
</svg>'''


for cid, skin, hair, style, shirt, acc in CUSTOMERS:
    write(f"assets/sprites/customers/{cid}.svg", customer_svg(skin, hair, style, shirt, acc))


# ---------------------------------------------------------------- generators
def machine(body, accent, screen_inner, extra=""):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 260 190" width="260" height="190">
<ellipse cx="130" cy="172" rx="105" ry="12" fill="#000" opacity="0.10"/>
<rect x="28" y="26" width="204" height="140" rx="18" fill="{body}"/>
<rect x="28" y="26" width="204" height="140" rx="18" fill="#FFF" opacity="0.08"/>
<rect x="46" y="42" width="168" height="86" rx="12" fill="#2E3440"/>
{screen_inner}
<circle cx="62" cy="148" r="7" fill="{accent}"/><circle cx="84" cy="148" r="7" fill="#FFD94A"/>
<rect x="150" y="140" width="66" height="14" rx="7" fill="{accent}"/>
{extra}
</svg>'''


SCREEN_CODE = '<path d="M62 62 L82 78 L62 94" fill="none" stroke="#7EE787" stroke-width="6" stroke-linecap="round"/><rect x="92" y="92" width="52" height="7" rx="3.5" fill="#7EE787"/><rect x="62" y="106" width="86" height="7" rx="3.5" fill="#58A6FF"/>'
GENERATORS = {
    "code_notebook": machine("#4A90D9", "#FFD94A", SCREEN_CODE,
        '<rect x="96" y="118" width="120" height="10" rx="5" fill="#2E2A26" opacity="0.25"/>'),
    "editor_studio": machine("#7C6BD9", "#6BCB77",
        '<rect x="58" y="54" width="60" height="8" rx="4" fill="#F0A080"/><rect x="58" y="70" width="90" height="8" rx="4" fill="#7EE787"/><rect x="58" y="86" width="74" height="8" rx="4" fill="#58A6FF"/><rect x="58" y="102" width="98" height="8" rx="4" fill="#E8A33D"/>'),
    "web_scaffold": machine("#E8873A", "#4A90D9",
        '<rect x="56" y="50" width="148" height="14" rx="6" fill="#58A6FF"/><rect x="56" y="72" width="66" height="42" rx="8" fill="#FFF" opacity="0.85"/><rect x="130" y="72" width="74" height="18" rx="8" fill="#FFD94A"/><rect x="130" y="96" width="74" height="18" rx="8" fill="#6BCB77"/>'),
    "toolbox": machine("#4CAF7D", "#E8873A",
        '<rect x="70" y="66" width="120" height="52" rx="10" fill="#D9604A"/><rect x="70" y="84" width="120" height="10" fill="#B8452F"/><rect x="112" y="52" width="36" height="18" rx="8" fill="none" stroke="#8A5A2B" stroke-width="7"/><rect x="118" y="78" width="24" height="14" rx="4" fill="#FFD94A"/>'),
    "data_sprout": machine("#3AA6A0", "#6BCB77",
        '<path d="M130 118 Q128 84 104 70 M130 118 Q134 78 160 64" stroke="#4CAF50" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M104 70 Q84 68 80 50 Q100 48 104 70Z" fill="#6BCB77"/><path d="M160 64 Q162 42 182 40 Q184 62 160 64Z" fill="#6BCB77"/><ellipse cx="130" cy="122" rx="42" ry="10" fill="#8A5A2B"/>'),
    "package_box": machine("#D9A441", "#D96C4A",
        '<path d="M76 118 L76 66 L130 50 L184 66 L184 118 L130 132Z" fill="#E8B45A"/><path d="M76 66 L130 82 L184 66 M130 82 L130 132" stroke="#B57F27" stroke-width="6" fill="none"/><rect x="112" y="52" width="36" height="16" rx="4" fill="#FFF" opacity="0.7"/>'),
    "game_lab": machine("#D96C4A", "#FFD94A",
        '<rect x="66" y="62" width="128" height="56" rx="26" fill="#2E2A26"/><circle cx="94" cy="90" r="7" fill="#FFD94A"/><path d="M88 90 L100 90 M94 84 L94 96" stroke="#FFD94A" stroke-width="4"/><circle cx="160" cy="82" r="6" fill="#D9604A"/><circle cx="172" cy="96" r="6" fill="#58A6FF"/><circle cx="148" cy="96" r="6" fill="#6BCB77"/>'),
    "hardware_bench": machine("#8A8F98", "#E8A33D",
        '<rect x="58" y="56" width="92" height="62" rx="8" fill="#3E7C4F"/><path d="M70 72 L138 72 M70 88 L138 88 M70 104 L120 104" stroke="#FFD94A" stroke-width="4"/><circle cx="86" cy="64" r="4" fill="#FFD94A"/><circle cx="168" cy="70" r="17" fill="#5A6068"/><circle cx="168" cy="70" r="8" fill="#FFD94A"/>'),
}
for gid, svg in GENERATORS.items():
    write(f"assets/sprites/generators/{gid}.svg", svg)


# ---------------------------------------------------------------- backgrounds
write("assets/backgrounds/workshop.svg", '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 720" width="1280" height="720">
<rect width="1280" height="720" fill="#F7E3C3"/>
<rect y="470" width="1280" height="250" fill="#D9A066"/>
<path d="M0 470 L1280 470 L1280 492 L0 492Z" fill="#C78D52"/>
<rect x="70" y="80" width="330" height="240" rx="18" fill="#BFE3F2"/>
<rect x="70" y="80" width="330" height="240" rx="18" fill="none" stroke="#FFF" stroke-width="14"/>
<path d="M70 200 L400 200 M235 80 L235 320" stroke="#FFF" stroke-width="10"/>
<circle cx="150" cy="140" r="26" fill="#FFD94A"/>
<rect x="880" y="70" width="330" height="26" rx="10" fill="#B57F27"/>
<rect x="900" y="30" width="34" height="42" rx="5" fill="#D9604A"/><rect x="940" y="24" width="34" height="48" rx="5" fill="#4A90D9"/><rect x="980" y="34" width="34" height="38" rx="5" fill="#6BCB77"/><rect x="1030" y="28" width="52" height="44" rx="6" fill="#E8A33D"/><rect x="1100" y="36" width="70" height="36" rx="8" fill="#58A6FF"/>
<rect x="880" y="170" width="330" height="26" rx="10" fill="#B57F27"/>
<rect x="910" y="128" width="70" height="44" rx="8" fill="#9B6BD9"/><rect x="1000" y="136" width="48" height="36" rx="8" fill="#D96C8A"/><rect x="1070" y="124" width="90" height="48" rx="10" fill="#3AA6A0"/>
<rect x="480" y="96" width="300" height="190" rx="14" fill="#FFF6E8"/>
<rect x="500" y="116" width="58" height="44" rx="6" fill="#FFD94A"/><rect x="570" y="116" width="58" height="44" rx="6" fill="#F2A0B5"/><rect x="640" y="116" width="58" height="44" rx="6" fill="#9AD1F2"/><rect x="500" y="172" width="58" height="44" rx="6" fill="#A8D8A8"/><rect x="570" y="172" width="58" height="44" rx="6" fill="#FFD94A"/><rect x="640" y="172" width="58" height="44" rx="6" fill="#C3B2F2"/>
<rect x="500" y="228" width="260" height="40" rx="6" fill="#F0DFC0"/>
<rect x="90" y="392" width="300" height="26" rx="10" fill="#8A5A2B"/>
<rect x="120" y="418" width="18" height="70" fill="#8A5A2B"/><rect x="332" y="418" width="18" height="70" fill="#8A5A2B"/>
<rect x="150" y="322" width="120" height="72" rx="8" fill="#2E3440"/><rect x="160" y="332" width="100" height="44" rx="5" fill="#7EE787" opacity="0.75"/>
<rect x="186" y="394" width="48" height="12" fill="#5A6068"/>
<rect x="1050" y="330" width="54" height="62" rx="8" fill="#D9604A"/>
<path d="M1077 330 Q1048 288 1010 296 Q1040 268 1064 292 Q1062 258 1090 246 Q1112 268 1100 296 Q1132 282 1148 310 Q1112 322 1096 330Z" fill="#4CAF50"/>
<ellipse cx="640" cy="640" rx="430" ry="52" fill="#C78D52" opacity="0.55"/>
</svg>''')

write("assets/backgrounds/board_surface.svg", '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 640" width="800" height="640">
<rect width="800" height="640" rx="26" fill="#A9743F"/>
<rect x="14" y="14" width="772" height="612" rx="20" fill="#C08B4E"/>
<rect x="30" y="30" width="740" height="580" rx="16" fill="#D9A866"/>
<circle cx="70" cy="70" r="7" fill="#8A5A2B"/><circle cx="730" cy="70" r="7" fill="#8A5A2B"/><circle cx="70" cy="570" r="7" fill="#8A5A2B"/><circle cx="730" cy="570" r="7" fill="#8A5A2B"/>
</svg>''')

write("assets/sprites/effects/starburst.svg", '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
<path d="M100 4 L118 66 L184 40 L134 86 L196 104 L132 114 L160 172 L106 132 L84 190 L80 124 L18 142 L66 100 L6 72 L74 76 Z" fill="#FFD94A" stroke="#E8A33D" stroke-width="5" stroke-linejoin="round"/>
<circle cx="100" cy="100" r="22" fill="#FFF3C4"/>
</svg>''')

print("artwork generation complete")
