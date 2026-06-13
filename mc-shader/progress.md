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
