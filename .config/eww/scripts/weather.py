import argparse
import json
import os
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Optional

import requests

PATH_ENV_FILE = Path(__file__).parent.joinpath(".env")
PATH_WEATHER_CACHE = Path(os.path.expanduser("~/.cache/eww/weather"))

ENV_API_KEY: Optional[str] = None
ENV_CITY_ID: Optional[str] = None


@dataclass
class Data:
    icon: str
    status: str
    quote: str
    degree: str


def read(path: Path) -> str:
    with open(path, "r") as f:
        return f.read()


def write(path: Path, data: str) -> int:
    with open(path, "w") as f:
        return f.write(data)


PATH_WEATHER_CACHE_RAW = PATH_WEATHER_CACHE.joinpath("raw.json")
PATH_WEATHER_CACHE_FMT = PATH_WEATHER_CACHE.joinpath("fmt.json")

# env
with open(PATH_ENV_FILE, "r") as f:
    env = f.read()
    for line in env.split("\n"):
        key, value = line.split("=")
        if key == "API_KEY":
            ENV_API_KEY = value
        if key == "CITY_ID":
            ENV_CITY_ID = value

if ENV_API_KEY is None and ENV_CITY_ID is None:
    print("failed to load environment variables")
    exit(1)

os.makedirs(PATH_WEATHER_CACHE, exist_ok=True)

table = {
    "50d": (" ", "Soft mist hugs the day."),
    "50n": (" ", "The night drifts in gentle mist."),
    "01d": (" ", "Sunshine spills across the sky."),
    "01n": (" ", "A calm, starry night settles in."),
    "02d": (" ", "Clouds wander through a quiet sky."),
    "02n": (" ", "Dim clouds drift under moonlight."),
    "03d": (" ", "Grey clouds keep things mellow."),
    "03n": (" ", "Clouds linger in the silent night."),
    "04d": (" ", "The sky rests under a soft blanket."),
    "04n": (" ", "A heavy sky wraps the night."),
    "09d": (" ", "Rain falls in restless bursts."),
    "09n": (" ", "Night rain taps in steady rhythm."),
    "10d": (" ", "Sunlit rain shimmers in the air."),
    "10n": (" ", "Rain whispers through the dark."),
    "11d": ("", "Thunder stirs the restless sky."),
    "11n": ("", "Storms crackle through the night."),
    "13d": (" ", "Snowflakes dance in the cold air."),
    "13n": (" ", "Snow falls under a hushed sky."),
    "40d": (" ", "A light fog softens the day."),
    "40n": (" ", "Fog wraps the night in quiet."),
}

default = (" ", "Sort of odd, I don't know what to forecast")


# fetching
def fetch_weather() -> Optional[dict]:
    try:
        raw_cache = json.loads(read(PATH_WEATHER_CACHE_RAW))
        timestamp = raw_cache["timestamp"]
        elapsed = time.time() - timestamp

        if elapsed < 60 * 30:
            return raw_cache
    except Exception:
        pass

    url = f"http://api.openweathermap.org/data/2.5/weather?APPID={ENV_API_KEY}&id={ENV_CITY_ID}&units=metric"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        data["timestamp"] = time.time()
        write(PATH_WEATHER_CACHE_RAW, json.dumps(data))
        return data

    raise Exception("failed to fetch weather")


def format_data() -> Data:
    try:
        fmt_cache = json.loads(read(PATH_WEATHER_CACHE_FMT))
        timestamp = fmt_cache["timestamp"]
        elapsed = time.time() - timestamp

        if elapsed < 60 * 30:
            return fmt_cache
    except Exception:
        pass

    data = Data(
        icon=" ",
        status="Weather Unavailable",
        quote="Ah well, no weather huh?",
        degree="-",
    )

    data_raw = fetch_weather()
    if data_raw is None:
        return data

    temp = str(int(data_raw["main"]["temp"]))
    icon_code = data_raw["weather"][0]["icon"]
    desc = data_raw["weather"][0]["description"].title()
    icon, quote = table.get(icon_code, default)

    data.icon = icon
    data.status = desc
    data.quote = quote
    data.degree = temp

    write(PATH_WEATHER_CACHE_FMT, json.dumps(asdict(data)))

    return data


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--fetch", action="store_true")
    parser.add_argument("--icon", action="store_true")
    parser.add_argument("--temp", action="store_true")
    parser.add_argument("--status", action="store_true")
    parser.add_argument("--quote", action="store_true")

    args = parser.parse_args()

    if args.fetch:
        format_data()
    else:
        json = json.loads(read(PATH_WEATHER_CACHE_FMT))
        data = Data(**json)
        if args.icon:
            print(data.icon)
        elif args.temp:
            print(data.degree)
        elif args.status:
            print(data.status)
        elif args.quote:
            print(data.quote)
