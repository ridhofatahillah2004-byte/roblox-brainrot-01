#!/usr/bin/env python3
"""Build default.project.json for Brainrot Egg Rush.

The world is a sunny plaza: a conveyor belt through the middle where eggs
ride, eight base plots in a ring around it, a spawn pad to the south, palm
trees around the edge and a beacon to the north. The numbers here must
agree with BrainrotConfig.World (plot radius, belt length, belt height).

Run: python3 gen_project.py
"""

import json
import math

PLOT_COUNT = 8
PLOT_RADIUS = 46
BELT_HALF_LENGTH = 28

BASE_COLORS = [
    (255, 60, 60),
    (255, 150, 40),
    (255, 220, 60),
    (80, 200, 90),
    (60, 200, 200),
    (80, 120, 255),
    (180, 100, 255),
    (255, 120, 200),
]


def color(rgb):
    return [c / 255 for c in rgb]


def part(name, size, pos, rgb, classname="Part", extra=None):
    node = {
        "$className": classname,
        "$properties": {
            "Anchored": True,
            "Color": color(rgb),
            "Locked": True,
            "Position": list(pos),
            "Size": list(size),
        },
    }
    if extra:
        node["$properties"].update(extra)
    return node


def base_plot(index):
    """One base plot: a coloured pad, a sign post, and ten slot anchors."""
    angle = math.radians(index * (360 / PLOT_COUNT))
    x = PLOT_RADIUS * math.cos(angle)
    z = PLOT_RADIUS * math.sin(angle)
    rgb = BASE_COLORS[index % len(BASE_COLORS)]
    children = {}
    children["Pad"] = part("Pad", (22, 1, 22), (x, 0.5, z), rgb, extra={"Material": "SmoothPlastic"})
    children["Post"] = part("Post", (1, 6, 1), (x, 4, z - 9), (70, 70, 80))
    children["Sign"] = part("Sign", (6, 3, 0.5), (x, 7, z - 9), rgb, extra={"Material": "Neon"})
    # Ten slot anchors in a 5 by 2 grid on the pad.
    slot = 0
    for row_z in (-4, 4):
        for col_x in (-8, -4, 0, 4, 8):
            slot += 1
            children["Slot%d" % slot] = part(
                "Slot%d" % slot,
                (2, 0.5, 2),
                (x + col_x, 1.25, z + row_z),
                (240, 240, 240),
                extra={"Transparency": 0.5, "CanCollide": False, "Material": "SmoothPlastic"},
            )
    return {"$className": "Model", "Pad": children["Pad"], "Post": children["Post"],
            "Sign": children["Sign"],
            **{k: v for k, v in children.items() if k.startswith("Slot")}}


def palm(index):
    """One palm tree: a blocky trunk and a round leafy top."""
    angle = math.radians(10 + index * 36)
    x = 120 * math.cos(angle)
    z = 120 * math.sin(angle)
    return {
        "$className": "Model",
        "Trunk": part("Trunk", (1.2, 8, 1.2), (x, 4, z), (150, 105, 55), extra={"Material": "Wood"}),
        "Leaves": part("Leaves", (6, 4, 6), (x, 9, z), (60, 180, 90), extra={"Material": "SmoothPlastic"}),
    }


def build():
    workspace = {
        "$properties": {"FilteringEnabled": True},
        "Ground": part("Ground", (280, 2, 280), (0, -1, 0), (86, 165, 77), extra={"Material": "Grass"}),
        "Plaza": part("Plaza", (90, 1, 90), (0, 0.5, 0), (205, 200, 185), extra={"Material": "Concrete"}),
        "Conveyor": part("Conveyor", (64, 1, 8), (0, 1.5, 0), (64, 64, 72), extra={"Material": "Metal"}),
        "RailL": part("RailL", (64, 0.5, 0.5), (0, 2.2, -4.2), (255, 210, 60), extra={"Material": "SmoothPlastic"}),
        "RailR": part("RailR", (64, 0.5, 0.5), (0, 2.2, 4.2), (255, 210, 60), extra={"Material": "SmoothPlastic"}),
        "SpawnLocation": part(
            "SpawnLocation", (16, 1, 16), (0, 0.5, 60), (80, 220, 90),
            classname="SpawnLocation",
            extra={"Neutral": True, "AllowTeamChangeOnTouch": False, "Duration": 0},
        ),
        "Beacon": part("Beacon", (4, 30, 4), (0, 15, -75), (230, 215, 100), extra={"Material": "Neon"}),
        "BeaconTop": part("BeaconTop", (8, 8, 8), (0, 32, -75), (255, 230, 80), extra={"Material": "Neon"}),
        "Bases": {"$className": "Folder"},
        "Palms": {"$className": "Folder"},
    }
    for i in range(PLOT_COUNT):
        workspace["Bases"]["Base%d" % (i + 1)] = base_plot(i)
    for i in range(10):
        workspace["Palms"]["Palm%d" % (i + 1)] = palm(i)

    project = {
        "name": "brainrot-egg-rush",
        "tree": {
            "$className": "DataModel",
            "Players": {"$properties": {"CharacterAutoLoads": True}},
            "ServerScriptService": {"Server": {"$path": "src/server"}},
            "StarterPlayer": {"StarterPlayerScripts": {"Client": {"$path": "src/client"}}},
            "ReplicatedStorage": {"Shared": {"$path": "src/shared"}},
            "Workspace": workspace,
            "Lighting": {"$properties": {
                "Ambient": [0.3, 0.3, 0.35],
                "Brightness": 2,
                "ClockTime": 14,
                "GlobalShadows": True,
                "Outlines": False,
                "Technology": "Voxel",
            }},
            "SoundService": {"$properties": {"RespectFilteringEnabled": True}},
        },
    }
    return project


if __name__ == "__main__":
    with open("default.project.json", "w") as handle:
        json.dump(build(), handle, indent=2)
        handle.write("\n")
    print("wrote default.project.json")
