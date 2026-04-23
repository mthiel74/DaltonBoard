# PhysicsModelLink Demos

Nine stand-alone physics demonstrations built on top of Arnoud Buzing's
[`PhysicsModelLink`](https://www.wolframcloud.com/obj/arnoudbuzing/DeployedResources/Paclet/ArnoudBuzing/PhysicsModelLink/)
paclet (Rapier-based rigid-body dynamics for Wolfram).  Each script is
self-contained and writes its output to `output/demos/`.

| # | Demo | What it shows |
|---|---|---|
| 1 | [`01_hourglass.wls`](01_hourglass.wls) | Granular flow through a narrow aperture — jamming, arching, avalanche |
| 2 | [`02_sandpile.wls`](02_sandpile.wls)   | Angle of repose as a function of friction |
| 3 | [`03_domino_cascade.wls`](03_domino_cascade.wls) | Chain-reaction of thousands of dominos in a spiral |
| 4 | [`04_dam_break.wls`](04_dam_break.wls) | Granular dam break — wall removed at t = 0 |
| 5 | [`05_sphere_packing.wls`](05_sphere_packing.wls) | Random close-packing of 5 000 spheres in a cylinder |
| 6 | [`06_brazil_nut.wls`](06_brazil_nut.wls) | Size segregation under vertical shaking |
| 7 | [`07_superballs.wls`](07_superballs.wls) | Elastic chaos — 200 high-restitution spheres in a cube |
| 8 | [`08_tower_collapse.wls`](08_tower_collapse.wls) | Projectile vs a Jenga-style block tower |
| 9 | [`09_breaking_wave.wls`](09_breaking_wave.wls) | A curling wave of blocks cresting down a ramp |

All demos share a handful of helpers (video export, non-overlapping
point sampling, GIF conversion via `ffmpeg`) that live in
[`_common.wl`](_common.wl).

## Running

Each demo is a stand-alone `wolframscript` file:

```bash
wolframscript -file demos/01_hourglass.wls
```

Output lands in `output/demos/` (MP4 + GIF + final-frame PNG).
