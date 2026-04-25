import subprocess
import json
import requests
import tempfile
import os
import argparse


TEMP_DIR = os.path.join(tempfile.gettempdir(), "spotify_widget")
os.makedirs(TEMP_DIR, exist_ok=True)

def get_spotify_metadata(download_cover=True):
    metadata = { "fetched": False }

    try:
        result = subprocess.run(
            ["playerctl", "-p", "spotify", "metadata"],
            capture_output=True,
            text=True,
            check=True
        )


        playing = False
        status = subprocess.run(
            ["playerctl", "-p", "spotify", "status"],
            capture_output=True,
            text=True,
            check=True
        ).stdout.strip()
        
        if status == "Playing":
            playing = True
        
        metadata["playing"] = playing

        for line in result.stdout.splitlines():
            parts = line.split(None, 2)
            if len(parts) == 3:
                _, key, value = parts
                short_key = key.split(":", 1)[1] if ":" in key else key
                metadata[short_key] = value

        track_id = metadata.get("trackid", "").replace("/com/spotify/track/", "")
        art_url = metadata.get("artUrl")
        metadata["fetched"] = True

        if download_cover and track_id and art_url:
            for file in os.listdir(TEMP_DIR):
                if file.endswith(".spotify.jpg") and file != f"{track_id}.spotify.jpg":
                    os.remove(os.path.join(TEMP_DIR, file))

            cover_path = os.path.join(TEMP_DIR, f"{track_id}.spotify.jpg")
            try:
                if not os.path.exists(os.path.join(TEMP_DIR, f"{track_id}.spotify.jpg")):
                    resp = requests.get(art_url)
                    resp.raise_for_status()
                    with open(cover_path, "wb") as f:
                        f.write(resp.content)
            except Exception as e:
                print(f"{e}")

        metadata["cover_file"] = cover_path
    except Exception as e:
        pass

    return metadata

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--field", help="Print only the specified metadata field")
    args = parser.parse_args()
    download_cover = args.field and args.field == "cover_file"

    meta = get_spotify_metadata(download_cover)
    if args.field:
        print(meta.get(args.field, ""))
    else:
        json_str = json.dumps(meta, ensure_ascii=False)
        print(json_str)

