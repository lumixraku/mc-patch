# Progress

## Sky / sunset (gbuffers_skybasic)

Goal: improve the weak dusk/sunset sky, referencing the procedural sky in
`web-minecraft/src/sky.js`.

- Ported a multi-band dusk wash: ember below horizon → bright amber at the
  horizon → coral → magenta → deep violet zenith, driven by sun elevation
  (`duskF = 1 - |sunUp| / 0.3`), filling the whole sky and stronger toward the
  sun, plus a warm horizon glow hugging the sun.
- Fixed a hard horizontal seam at the horizon: the old shader based its color
  on the vanilla per-vertex `gl_Color`, but Minecraft renders the sky as two
  separate meshes (upper dome + lower void/fog plane) with different vertex
  colors, leaving a sharp line. Now the base day/night vertical gradient is
  computed analytically from the view-ray altitude `h`, so the seam is gone.
- Removed the old `worldTime`-based azure window and the unused `vColor`
  varying (sky is now driven purely by sun elevation, like the reference).

### Tuning knobs
- Day base color: `dayTop` / `dayHor` (currently the reference azure palette).
- Sunset band colors: `duskEmber/Amb/Coral/Mag/Zen` and their `smoothstep`
  ranges (wider/overlapping = softer transitions).
- Dusk extent: the `/ 0.30` divisor in `duskF` (larger = lingers higher).

### Possible next steps
- Sync the dusk color into water reflection / fog tint so lakes and distant
  terrain pick up the sunset warmth (see `out.reflectCol` / `out.fogColor` in
  the reference `sky.js`).

## Water — Fresnel reflection (gbuffers_water + composite)

Goal: Fresnel water — transparent looking straight down (near), reflective at
grazing angles (far). Two stages:

1. **Analytic sky reflection** (`gbuffers_water.fsh`): reflect the procedural
   sky off the surface and blend water tint ↔ sky by a Schlick Fresnel term
   (F0 = 0.02). Near/steep → transparent turquoise; grazing/far → sky mirror.
   The sky color reuses the same gradient as `gbuffers_skybasic` so water
   tracks day/night/sunset. Plus a restrained mirrored sun glint.
2. **Screen-space reflection of geometry** (`composite.fsh`): reflect on-screen
   trees / terrain / entities, which only exist after the whole scene is drawn.
   View-space ray-march through the depth buffer; on a hit, blend the reflected
   scene color over the base by Fresnel; on a miss, keep the sky reflection.

Water detection in composite uses `depthtex0` (with translucents) vs
`depthtex1` (without): water = surface sits in front of opaque geometry behind
it. No aux buffer / color heuristic needed. Surface treated as a flat mirror
(normal = world up).

### Tuning knobs
- Transparency range: `mix(0.55, 0.93, fres)` alpha in `gbuffers_water.fsh`.
- SSR reach/precision: `SSR_STEPS` / `SSR_STEP0` / `SSR_GROW` in `composite.fsh`.
- Hit tolerance: `SSR_THICKNESS` floor + the `lastStep * 1.6` scaling.
- Edge fade & Fresnel strength of the geometry reflection.

### Known limits
- SSR only reflects what is currently on screen (off-screen / occluded objects
  don't appear; reflections fade near screen edges). Inherent to SSR.
- Deep water with no visible bottom (lakebed beyond render distance) is not
  detected as water (the `d1 < 1.0` clouds-exclusion test also drops it).
- Flat mirror only — no ripple distortion yet.
