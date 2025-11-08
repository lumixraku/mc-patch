Simple Minecraft Shader (OptiFine/Iris)

Features
- Water: soft translucent green, gentle waves, Fresnel reflections
- Rain: subtle puddle gloss and screen-space reflections on flat ground
- Sky: warm morning/evening glow near the horizon

Install
- Copy the `mc-shader` directory (or zip its contents) into your shaderpacks folder.
- Select it in OptiFine or Iris.

Notes
- This pack uses a lightweight composite pass for reflections and sky tint.
- Reflections are approximate (simple SSR), tuned for clarity over realism.



太好了！你这个截图非常有帮助 👍
从显示的现象来看（蓝色场景、无法看到方块纹理），问题是出在我们传错了渲染输入纹理：colortex0 其实在新版 Iris / OptiFine 1.21+ 中表示的是天空或第一层纹理，而游戏真正的颜色缓冲在 composite 阶段（不是 final）。

我们要的“什么都不改 shader”其实应该写在
composite.fsh 和 composite.vsh（而不是 final.fsh/vsh）中。


final.fsh 是最终决定效果  
fragColor = vec4(1.0, 1.0, 0.0, 1.0); 设置为 yellow 界面就是 yellow  composite.fsh 不是最后一步


## Why does a white-stained glass pane look the same color as the water surface?


Short answer: because our earlier water‑tint lived in the translucent pass, and glass renders in that same pass. So the shader was tinting any translucent surface (glass, ice, etc.) to the same turquoise as water.