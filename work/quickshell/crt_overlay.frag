#version 440

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
} ubuf;

void main() {
    vec2 uv = texCoord;

    // Scanlines: one dark line every 3 rows (tuned for ~1080p)
    float scanline = mod(floor(uv.y * 1200.0), 3.0) == 0.0 ? 0.28 : 0.0;

    // Subtle rolling flicker — very slight, just enough to feel alive
    float flicker = 0.018 * sin(ubuf.time * 3.7 + uv.y * 80.0)
                  * sin(ubuf.time * 1.1);

    // Vignette: 0 at center, 1 at edges
    vec2 vig = uv * (1.0 - uv);
    float vignette = 1.0 - clamp(vig.x * vig.y * 11.0, 0.0, 1.0);

    float alpha = clamp(scanline + vignette * 0.62 + flicker, 0.0, 1.0) * ubuf.qt_Opacity;
    fragColor = vec4(0.0, 0.0, 0.0, alpha);
}
