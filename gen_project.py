#!/usr/bin/env python3
"""Generate default.project.json for Brainrot Egg Rush.

Builds the static 3D world as Rojo JSON: baseplate, central plaza with
the egg conveyor, 8 base plots (each with 6 brainrot slot markers),
spawn pad, palm trees, a tsunami beacon tower and fences.
CFrame values are [x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22].
"""
import json
import math
import os

OUT = os.path.expanduser("~/workspace/makefun/roblox-brainrot-01/default.project.json")


def cframe(x, y, z, rx=0.0, ry=0.0, rz=0.0):
    """Position + XYZ euler rotation (degrees) -> Rojo CFrame array."""
    ax, ay, az = (math.radians(a) for a in (rx, ry, rz))
    cx, sx, cy, sy, cz, sz = math.cos(ax), math.sin(ax), math.cos(ay), math.sin(ay), math.cos(az), math.sin(az)
    # R = Rz * Ry * Rx (Roblox CFrame.Angles order)
    r00 = cy * cz
    r01 = cz * sx * sy - cx * sz
    r02 = cx * cz * sy + sx * sz
    r10 = cy * sz
    r11 = cx * cz + sx * sy * sz
    r12 = cx * sy * sz - cz * sx
    r20 = -sy
    r21 = cy * sx
    r22 = cx * cy
    return [x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22]


def part(name, size, color, cframe_vals, material="SmoothPlastic", shape=None,
         anchored=True, can_collide=True, transparency=0.0):
    p = {
        "$className": "Part",
        "$properties": {
            "Anchored": anchored,
            "CanCollide": can_collide,
            "Color": [c / 255.0 for c in color],
            "Material": material,
            "Size": list(size),
            "CFrame": cframe_vals,
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        },
    }
    if shape:
        p["$properties"]["Shape"] = shape
    if transparency:
        p["$properties"]["Transparency"] = transparency
    return p


def model(name, children):
    m = {"$className": "Model"}
    m.update(children)
    return m


def folder(name, children):
    f = {"$className": "Folder"}
    f.update(children)
    return f


def vec(x, y, z):
    return [x, y, z]


# --- World pieces -------------------------------------------------------
workspace = {}

# Baseplate: grass.
workspace["Baseplate"] = part(
    "Baseplate", (512, 20, 512), (110, 190, 90),
    cframe(0, -10, 0), material="Grass", can_collide=True,
)

# Central plaza.
workspace["Plaza"] = part(
    "Plaza", (70, 2, 70), (210, 205, 195),
    cframe(0, 0, 0), material="Slate",
)

# Conveyor belt: a raised dark belt across the plaza, X axis.
workspace["Conveyor"] = model("Conveyor", {
    "Belt": part("Belt", (44, 1, 10), (60, 60, 70), cframe(0, 1.5, 0), material="Metal"),
    "RailLeft": part("RailLeft", (44, 1.2, 0.8), (240, 200, 60), cframe(0, 2.2, -5.2), material="Metal"),
    "RailRight": part("RailRight", (44, 1.2, 0.8), (240, 200, 60), cframe(0, 2.2, 5.2), material="Metal"),
    "EggSpots": folder("EggSpots", {
        f"EggSpot{i + 1}": part(f"EggSpot{i + 1}", (2, 0.4, 2), (255, 255, 255),
                                cframe(-18 + i * 7.2, 2.2, 0), transparency=0.7,
                                anchored=True, can_collide=False)
        for i in range(6)
    }),
})

# Spawn pad: where players appear, south of the plaza.
workspace["SpawnLocation"] = {
    "$className": "SpawnLocation",
    "$properties": {
        "Anchored": True,
        "Color": [0.5, 0.85, 0.5],
        "Duration": 0,
        "Enabled": True,
        "Neutral": True,
        "Size": [20, 1, 10],
        "CFrame": cframe(0, 0.5, 44),
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    },
}

# Tsunami beacon tower (north-west corner): flashes red before a wave.
workspace["Beacon"] = model("Beacon", {
    "Pole": part("Pole", (2, 26, 2), (120, 120, 130), cframe(-62, 13, -62), shape="Cylinder", material="Metal"),
    "BeaconLight": part("BeaconLight", (5, 5, 5), (255, 220, 60), cframe(-62, 27.5, -62), shape="Ball", material="SmoothPlastic"),
    "Base": part("Base", (6, 1, 6), (100, 100, 110), cframe(-62, 0.5, -62), material="Slate"),
})

# Base plots: 8 around the plaza at radius 52, each 22x22 with 6 slots.
BASE_COLORS = [
    (255, 120, 120), (120, 170, 255), (120, 230, 130), (255, 220, 90),
    (255, 160, 70), (190, 110, 255), (255, 130, 210), (80, 230, 230),
]
bases_children = {}
for i in range(8):
    ang = math.radians(i * 45)
    cx, cz = 52 * math.sin(ang), 52 * math.cos(ang)
    # Slots: two rows of three on the pad, in pad-local space.
    slots = {}
    for s in range(6):
        row, col = divmod(s, 3)
        lx, lz = (col - 1) * 6.5, (row - 0.5) * 6.5
        # Rotate local offset by the base angle (pad faces the plaza).
        wx = cx + lx * math.cos(ang) + lz * math.sin(ang)
        wz = cz - lx * math.sin(ang) + lz * math.cos(ang)
        slots[f"Slot{s + 1}"] = part(
            f"Slot{s + 1}", (3, 0.3, 3), (255, 255, 255),
            cframe(wx, 1.15, wz), transparency=0.55, anchored=True, can_collide=False,
        )
    slots_folder = folder("Slots", slots)
    pad = part("Pad", (22, 1, 22), BASE_COLORS[i], cframe(cx, 0.5, cz), material="Slate")
    # Sign post at the pad's outer corner.
    sign_x = cx + 9 * math.sin(ang)
    sign_z = cz + 9 * math.cos(ang)
    sign = model("Sign", {
        "Pole": part("Pole", (0.8, 7, 0.8), (90, 90, 100), cframe(sign_x, 4, sign_z), material="Metal"),
        "Board": part("Board", (7, 3, 0.6), BASE_COLORS[i], cframe(sign_x, 8, sign_z), material="SmoothPlastic"),
    })
    owner = {
        "$className": "ObjectValue",
        "$properties": {},
    }
    base_model = model(f"Base{i + 1}", {
        "Pad": pad,
        "Slots": slots_folder,
        "Sign": sign,
        "Owner": owner,
    })
    bases_children[f"Base{i + 1}"] = base_model
workspace["Bases"] = folder("Bases", bases_children)

# Palm trees around the map edge.
palms = {}
for i, (px, pz) in enumerate([(-70, 20), (70, 20), (-70, -20), (70, -20),
                              (-40, 75), (40, 75), (-75, -55), (75, -55)]):
    trunk = part(f"Trunk{i}", (2, 14, 2), (150, 110, 70), cframe(px, 7, pz), shape="Cylinder", material="Wood")
    leaves = {}
    for j in range(4):
        la = math.radians(j * 90 + 20)
        leaves[f"Leaf{j}"] = part(
            f"Leaf{j}", (1, 0.4, 9), (60, 180, 80),
            cframe(px + 3.5 * math.sin(la), 14.5, pz + 3.5 * math.cos(la),
                   rx=25, ry=math.degrees(la), rz=0),
            anchored=True, can_collide=False,
        )
    palms[f"Palm{i}"] = model(f"Palm{i}", {"Trunk": trunk, **leaves})
workspace["Palms"] = folder("Palms", palms)

# Low fence ring around the play area.
fence_parts = {}
for i in range(12):
    ang = math.radians(i * 30)
    fx, fz = 95 * math.sin(ang), 95 * math.cos(ang)
    fence_parts[f"Fence{i}"] = part(
        f"Fence{i}", (16, 2.5, 1), (200, 200, 205),
        cframe(fx, 1.25, fz, ry=math.degrees(ang) + 90), material="Slate",
    )
workspace["Fence"] = folder("Fence", fence_parts)

tree = {
    "$className": "DataModel",
    "Players": {"$properties": {"CharacterAutoLoads": True}},
    "ServerScriptService": {
        "Server": {"$path": "src/server"},
    },
    "StarterPlayer": {
        "StarterPlayerScripts": {
            "Client": {"$path": "src/client"},
        },
    },
    "ReplicatedStorage": {
        "Shared": {"$path": "src/shared"},
    },
    "Workspace": {
        "$properties": {"FilteringEnabled": True},
        **workspace,
    },
    "Lighting": {
        "$properties": {
            "Ambient": [0.25, 0.25, 0.25],
            "Brightness": 2,
            "ClockTime": 14,
            "GlobalShadows": True,
            "Outlines": False,
            "Technology": "Future",
            "FogEnd": 1200,
        },
    },
    "SoundService": {
        "$properties": {"RespectFilteringEnabled": True},
    },
}

project = {"name": "brainrot-egg-rush", "tree": tree}
with open(OUT, "w") as f:
    json.dump(project, f, indent=2)
print("wrote", OUT, len(json.dumps(project)), "bytes")
