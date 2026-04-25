from pathlib import Path


def hex_to_rgba(hex_color: str, alpha: float = 1.0) -> tuple[int, int, int, float]:
    hex_color = hex_color.lstrip("#")
    if len(hex_color) == 6:
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
    elif len(hex_color) == 3:
        r = int(hex_color[0] * 2, 16)
        g = int(hex_color[1] * 2, 16)
        b = int(hex_color[2] * 2, 16)
    else:
        raise ValueError(f"Invalid hex color: {hex_color}")
    return (r, g, b, alpha)


CONFIG_DIR = Path.home().joinpath(".config/")

COLOR_BG = "#151727"  # shadow-grey
COLOR_BG_ALT = "#2C182D"  # midnight-violet
COLOR_FG = "#CADBEF"  # pale-sky
COLOR_PRIMARY = "#444F6C"  # dusk-blue
COLOR_ACTIVE = "#898AA3"  # lavender-grey
COLOR_HYPR_PRIMARY = "#3B2F4F"  # vintage-grape
COLOR_HYPR_SECONDARY = "#444F6C"  # reuse dusk-blue (no exact pair)


EWW_TEMPLATE = f"""
* {{
    $background: {COLOR_BG};
    $background-alt: {COLOR_BG_ALT};
    $foreground: {COLOR_FG};
    $primary: {COLOR_PRIMARY};
    $active: {COLOR_ACTIVE};
    $hypr-primary: {COLOR_HYPR_PRIMARY};
    $hypr-secondary: {COLOR_HYPR_SECONDARY};
}}
"""

ROFI_TEMPLATE = f"""
* {{
    background: {COLOR_BG};
    background-alt: {COLOR_BG_ALT};
    foreground: {COLOR_FG};
    selected: {COLOR_PRIMARY};
    active: {COLOR_ACTIVE};
    urgent: {COLOR_PRIMARY};
}}
"""

f = lambda color: str(hex_to_rgba(color[1:]))[1:-1].replace(" ", "")

HYPR_TEMPLATE = f"""
$primary = rgba({f(COLOR_HYPR_PRIMARY)})
$secondary = rgba({f(COLOR_HYPR_SECONDARY)})
$foreground = rgba({f(COLOR_FG)})
$background = rgba({f(COLOR_BG)})
$backgroundAlt = rgba({f(COLOR_BG_ALT)})
"""

paths = {
    "rofi": (ROFI_TEMPLATE, "rofi/themes/colors.rasi"),
    "hypr": (HYPR_TEMPLATE, "hypr/modules/colors.conf"),
    "eww": (EWW_TEMPLATE, "eww/colors.scss"),
}


def colorize():
    for name, (content, relative_path) in paths.items():
        path = CONFIG_DIR.joinpath(relative_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        path.write_text(content)
        print(f"{name}\t>\t{path}")


colorize()
