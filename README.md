# roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ridhofatahillah2004-byte/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ridhofatahillah2004-byte/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Egg Rush** — a 3D Roblox brainrot game: buy absurd meme eggs off the conveyor, hatch them into brainrots that follow you home, keep them on your base where each one earns coins every second, and climb the ladder of rarities, mutations and rebirths — while rival players try to steal your best brainrots and a tsunami wave sweeps the map every few minutes, forcing a dash home with the catch.

18 meme characters across 5 rarities (Common → Mythic, $2/s to $280/s), 5 egg tiers (Basic $100 → Rainbow $1M), 4 mutations (Normal, Golden ×2, Diamond ×4, Rainbow ×8), 10 base slots, stealing with a slap to fight back, rebirths at $1M for a permanent +25% income each, and a tsunami every 150 seconds. Built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty, $1,000 in USDC.

## Run it

```sh
rojo build default.project.json --output game.rbxl
```

Then open the place in Roblox Studio (Rojo plugin or `game.rbxl`), press Play, and publish it as a Public experience. The game needs no uploaded assets: every brainrot, egg and the whole world is built from code.

## Play it

1. Walk to the conveyor in the middle and hold **E** on an egg to buy it.
2. It hatches in 6 seconds into a random brainrot — run it home.
3. Step onto your base pad: it claims a free slot and starts earning coins every second.
4. Buy better eggs, unlock more slots (up to 10), chase mutations, and rebirth at $1M.
5. Hold **E** on a rival's brainrot to steal it — its owner can slap you with the Slap tool to cancel the steal.
6. When the tsunami warning sounds, run to your base or be swept away (and drop your egg).

## Files

- `src/server/` — game services: `PlayerData` (cash, rebirths, DataStore), `BaseService` (plots, slots, income tick), `EggService` (conveyor, hatching), `StealService` (stealing + slap), `WaveService` (tsunami), `RebirthService`, `Debug` (staging helpers for screenshots).
- `src/shared/` — `BrainrotConfig` (all numbers: cast, eggs, mutations, rebirth) and `BrainrotFactory` (builds the 3D character and egg models from parts).
- `src/client/Game.client.luau` — the HUD: cash, income, egg shop, base slots, rebirth, tsunami banner, help.
- `default.project.json` — the Rojo project and the 3D world (plaza, conveyor, 8 base plots, palms, beacon). Regenerate it with `python3 gen_project.py`.
- `main.ts` — the entrypoint: hands `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to make.fun.
- `screenshots/` — 3–4 captures of the game running in Studio (16:9, each ≤ 256 KiB). The first by name is the cover and must be the same picture as the game's first thumbnail on Roblox.
- `PLAY.json` — the published place's play link, place id and universe id (filled in after publishing).

---

<sub>Entered on [make.fun](https://make.fun/?ref=xbc8h78c&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
