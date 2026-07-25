import json
import os
import re
import sys
import urllib.request
from pathlib import Path

API = "https://wow.curseforge.com/api/game/versions?token={token}"


def interface_values(toc):
    for line in toc.read_text(encoding="utf-8-sig").splitlines():
        match = re.match(r"^##\s*Interface\s*:\s*(.+)$", line.strip())
        if match:
            return [value.strip() for value in match.group(1).split(",") if value.strip()]
    return []


def main():
    token = os.environ.get("CURSEFORGE_API_TOKEN")
    if not token:
        sys.exit("CURSEFORGE_API_TOKEN is not set")

    with urllib.request.urlopen(API.format(token=token)) as response:
        catalog = json.load(response)

    # A few legacy interface numbers are listed under more than one product, so
    # the most recently added entry wins.
    by_interface = {}
    for entry in sorted(catalog, key=lambda entry: entry["id"]):
        by_interface[entry["apiVersion"]] = entry

    tocs = sorted(Path(".").glob("*.toc"))
    if not tocs:
        sys.exit("no .toc files found")

    matched = {}
    for toc in tocs:
        values = interface_values(toc)
        if not values:
            sys.exit("{}: no '## Interface:' line".format(toc.name))
        for value in values:
            entry = by_interface.get(value)
            if entry is None:
                sys.exit("{}: interface {} is not a CurseForge game version".format(toc.name, value))
            matched[entry["id"]] = "{} {} ({})".format(toc.name, entry["name"], value)

    for version_id, label in sorted(matched.items()):
        print("{} -> {}".format(label, version_id), file=sys.stderr)

    print("GAME_VERSIONS=" + ",".join(str(version_id) for version_id in sorted(matched)))


main()
