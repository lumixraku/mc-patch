## 前置条件
首先你需要安装OptiFine模组，这是运行自定义shader的必要条件。OptiFine为Minecraft添加了shader支持和更多图形选项。

## Shader包的基本结构
一个标准的shader包通常包含以下文件结构：
```
shaderpack名称/
├── shaders/
│   ├── composite.fsh
│   ├── composite.vsh
│   ├── final.fsh
│   ├── final.vsh
│   ├── gbuffers_terrain.fsh
│   ├── gbuffers_terrain.vsh
│   └── 其他着色器文件...
└── shaders.properties
```

## 主要着色器文件类型
gbuffers阶段：处理基本几何体渲染，包括地形、实体、天空等。这里定义物体的基本外观和材质属性。
composite阶段：进行后处理效果，比如光照计算、阴影、反射、景深等高级视觉效果。
final阶段：最终的屏幕输出处理，通常用于色彩校正、色调映射等。


## 配置文件
shaders.properties文件用于定义shader的各种属性和设置选项：

```
# 基本信息
version=1.0
author=你的名字

# 渲染设置
shadowMapResolution=2048
shadowDistance=128.0

# 自定义选项
option.MOTION_BLUR=true
option.BLOOM=false
```


## 各阶段作用与影响范围

### gbuffers_basic.fsh（几何阶段）
作用：给场景物体渲染基础颜色/法线/深度等 G-Buffer。这里改颜色=改变“源素材”。
影响范围：仅世界几何（方块/实体）。不会直接覆盖 UI；但其输出会被后续阶段读取。如果后续阶段没正确采样，看到的就是这里的颜色被放大成整屏效果。
### composite.fsh（合成阶段）
作用：把前面的缓冲合成成一张“场景色”图（色调映射、SSR、水面等通常在这）。这里直通/调色会直接改变最终世界画面。
影响范围：世界画面为主。若写死红色，整屏会红（常见于我们之前的测试线）。
### final.fsh（最终阶段）
作用：对 composite 的结果做最后的全屏处理（色彩校正、UI 混合、FXAA 等）。
影响范围：最高优先级。这里若输出常量色，会覆盖世界与大多数 UI（你看到“UI 也变色”的典型表现）。


### block.properties
vBlockId = mc_Entity.x; 把编号放进去，片元阶段可读
通过映射让 mc_Entity.x 变为稳定值，比如 1000=water，1001=glass，避免不同版本原生ID不一致

### gbuffer_water gbuffer_translucent
你说得对：在你的运行环境里，gbuffers_water 这个程序确实会处理到“非水”的半透明几何（例如玻璃/玻璃板）。因此，一旦把非水的早退逻辑去掉，水里的上色就会同样作用到玻璃上。这正是我们现在在水的着色器里做 blockId 守卫和 return 的原因。

结论与做法

必须保留 gbuffers_water.fsh 的“非水早退”判断与 return（否则水的着色会影响玻璃）：
mc-shader/shaders/gbuffers_water.fsh:28
gbuffers_translucent 仍然有用，因为它负责“非水的所有半透明材质”（玻璃/玻璃板/冰/粘液等），并且我们已在这里统一用“仅纹理颜色”渲染，忽略 gl_Color 的绿色顶点色污染：
mc-shader/shaders/gbuffers_translucent.fsh:27
为什么会这样

Pass 名称不代表“只会处理某一类方块”。在某些版本/渲染管线下，部分半透明几何会被送进 gbuffers_water 程序。如果不在程序内部做 blockId 过滤，水的逻辑就会误作用到玻璃。