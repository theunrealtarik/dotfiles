import sys
import argparse
from enum import Enum


class Command(str, Enum):
    CAVA = "cava"
    CORES = "cores"


class Theme(str, Enum):
    BLOCKS = "▁▂▃▄▅▆▇█"
    BLOCKS_ALT = "▁▃▄▅▆▇█"
    BARS = "▏▎▍▌▋▊▉█"

    ASCII = " .:-=+*#%@"
    ASCII_PLAIN = "._-~=+*#"
    DIGITS = "0123456789"

    SHADE = "░▒▓█"

    BRAILLE = "⠁⠃⠇⠧⠷⠿⡿⣿"
    BRAILLE_ALT = "⡀⡄⡆⡇⣇⣧⣷⣿"

    DOTS = "·•●"
    LED = "⠂⠆⠇⠧⠷⠿"

    WAVE = "⎽⎼⎻⎺"
    WAVE_ASCII = "~-^~^-"

    WEIRD = "▖▘▝▗▚▞█"

    @property
    def levels(self) -> str:
        return self.value

    @property
    def len(self) -> int:
        return self.value.__len__()


def wave(values: list[int], base: int, theme: Theme) -> str | None:
    out = ""
    levels = theme.levels

    for v in values:
        r = v / base
        idx = min(r * len(levels), len(levels))
        out += levels[int(idx)]

    return out


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("target", type=Command)

    args = parser.parse_args()

    match args.target:
        case Command.CAVA:
            lines = sys.stdin
            for line in lines:
                parts = line.strip().split(";")
                values: list[int] = []
                for p in parts:
                    if p:
                        values.append(int(p))

                w = wave(values, 8, Theme.BLOCKS)
                print(w, flush=True)

        case Command.CORES:
            import json

            lines = sys.stdin
            for line in lines:
                data = json.loads(line)
                w = wave([int(c) for c in data], 100, Theme.BLOCKS)
                print(w, flush=True)
