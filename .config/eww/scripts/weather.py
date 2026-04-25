import os
import sys
import json
import subprocess
import dotenv

dotenv.load_dotenv()

cache_dir = os.path.expanduser("~/.cache/eww/weather")
paths = {
    "stat": f"{cache_dir}/weather-stat",
    "degree": f"{cache_dir}/weather-degree",
    "quote": f"{cache_dir}/weather-quote",
    "hex": f"{cache_dir}/weather-hex",
    "icon": f"{cache_dir}/weather-icon",
}

os.makedirs(cache_dir, exist_ok=True)


API_KEY = os.getenv("OWM_API_KEY")
CITY_ID = os.getenv("CITY_ID")

table = {
    "50d": (" ", "Soft mist hugs the day.", "#84afdb"),
    "50n": (" ", "The night drifts in gentle mist.", "#84afdb"),
    "01d": (" ", "Sunshine spills across the sky.", "#ffd86b"),
    "01n": (" ", "A calm, starry night settles in.", "#fcdcf6"),
    "02d": (" ", "Clouds wander through a quiet sky.", "#adadff"),
    "02n": (" ", "Dim clouds drift under moonlight.", "#adadff"),
    "03d": (" ", "Grey clouds keep things mellow.", "#adadff"),
    "03n": (" ", "Clouds linger in the silent night.", "#adadff"),
    "04d": (" ", "The sky rests under a soft blanket.", "#adadff"),
    "04n": (" ", "A heavy sky wraps the night.", "#adadff"),
    "09d": (" ", "Rain taps softly on everything.", "#6b95ff"),
    "09n": (" ", "Night rain whispers in the dark.", "#6b95ff"),
    "10d": (" ", "A steady rain refreshes the world.", "#6b95ff"),
    "10n": (" ", "Rain falls in a quiet rhythm.", "#6b95ff"),
    "11d": ("", "Thunder stirs the restless sky.", "#ffeb57"),
    "11n": ("", "Storms crackle through the night.", "#ffeb57"),
    "13d": (" ", "Snowflakes dance in the cold air.", "#e3e6fc"),
    "13n": (" ", "Snow falls under a hushed sky.", "#e3e6fc"),
    "40d": (" ", "A light fog softens the day.", "#84afdb"),
    "40n": (" ", "Fog wraps the night in quiet.", "#84afdb"),
}

default = (" ", "Sort of odd, I don't know what to forecast", "#adadff")


def write(path, value):
    with open(path, "w") as f:
        f.write(value)


def read(path):
    with open(path) as f:
        return f.read()


def get_weather():
    url = f"http://api.openweathermap.org/data/2.5/weather?APPID={API_KEY}&id={CITY_ID}&units=metric"
    try:
        raw = subprocess.check_output(["curl", "-sf", url]).decode()
        data = json.loads(raw)

    except:
        write(paths["stat"], "Weather Unavailable")
        write(paths["icon"], " ")
        write(paths["quote"], "Ah well, no weather huh?")
        write(paths["degree"], "-")
        write(paths["hex"], "#adadff")
        return

    temp = str(int(data["main"]["temp"]))
    icon_code = data["weather"][0]["icon"]
    desc = data["weather"][0]["description"].title()

    icon, quote, hexv = table.get(icon_code, default)

    write(paths["icon"], icon)
    write(paths["stat"], desc)
    write(paths["degree"], f"{temp}°C")
    write(paths["quote"], quote)
    write(paths["hex"], hexv)


arg = sys.argv[1] if len(sys.argv) > 1 else ""


import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--getdata", action="store_true")
    parser.add_argument("--icon", action="store_true")
    parser.add_argument("--temp", action="store_true")
    parser.add_argument("--hex", action="store_true")
    parser.add_argument("--stat", action="store_true")
    parser.add_argument("--quote", action="store_true")

    args = parser.parse_args()

    if args.getdata:
        get_weather()
    elif args.icon:
        print(read(paths["icon"]), end="")
    elif args.temp:
        print(read(paths["degree"]), end="")
    elif args.hex:
        print(read(paths["hex"]), end="")
    elif args.stat:
        print(read(paths["stat"]), end="")
    elif args.quote:
        print(read(paths["quote"]).splitlines()[0])
