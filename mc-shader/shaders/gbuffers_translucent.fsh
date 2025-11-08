#version 120

// Debug: color all non-water translucent (e.g., glass) magenta to verify
// separation from water. Set to 1 to enable temporarily.
#ifndef DEBUG_TRANS_MAGENTA
#define DEBUG_TRANS_MAGENTA 0
#endif

varying vec2 texcoord;
varying vec4 color;
varying float vBlockId; // from vsh

uniform sampler2D texture;

void main() {
    // Translucent materials (glass, ice, etc.)
    // Water is handled explicitly in gbuffers_water.fsh.
    vec4 albedo = texture2D(texture, texcoord) * color;
    vec4 texOnly = texture2D(texture, texcoord);

    // Stable block IDs via shaders/block.properties
    const int BLOCK_WATER = 1000; // minecraft:water
    const int BLOCK_GLASS = 1001; // minecraft:glass, glass_pane, white_* variants

    int blockId = int(vBlockId + 0.5);
    // Fallback for environments where block.properties isn't picked up:
    // 8/9 are classic water IDs in old versions.
    bool isClassicWater = (blockId == 8 || blockId == 9);

    // Never treat water as glass in this pass (some versions may route water
    // through translucent). Leave it unchanged here; water coloring lives in
    // gbuffers_water.fsh so glass never inherits water color.
    if (blockId == BLOCK_WATER || isClassicWater) {
        gl_FragData[0] = albedo;
        return;
    }

    // For all other translucent blocks (glass, panes, ice, slime, etc.)
    // use the original texture color and ignore vertex tint.
    // This avoids unintended scene/biome tints (e.g., green) on clear glass.
    albedo = texOnly;

#if DEBUG_TRANS_MAGENTA
    albedo.rgb = vec3(1.0, 0.0, 1.0);
#endif

    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
