#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uIntensity;

uniform float uExposure;
uniform float uContrast;

uniform float uTemperature;
uniform float uTint;
uniform float uSaturation;
uniform float uVibrance;

uniform float uToneBlack;
uniform float uToneShadow;
uniform float uToneMid;
uniform float uToneHighlight;
uniform float uToneWhite;

uniform float uVignette;
uniform float uCenterGlow;

uniform sampler2D uTexture;

out vec4 fragColor;

// ============================================================================
// HELPERS
// ============================================================================

float smoothCurve(float t) {
    t = clamp(t, 0.0, 1.0);

    return t *
           t *
           (
               3.0 -
               2.0 * t
           );
}

float luminanceOf(vec3 rgb) {
    return dot(
        rgb,
        vec3(
            0.2126,
            0.7152,
            0.0722
        )
    );
}

// ============================================================================
// TONE CURVE
// ============================================================================

float toneCurveValue(float x) {
    x = clamp(
        x,
        0.0,
        1.0
    );

    const float x0 = 0.0;
    const float x1 = 0.20;
    const float x2 = 0.50;
    const float x3 = 0.80;
    const float x4 = 1.0;

    if (x <= x1) {
        float t =
            (
                x -
                x0
            ) /
            (
                x1 -
                x0
            );

        t = smoothCurve(t);

        return mix(
            uToneBlack,
            uToneShadow,
            t
        );
    }

    if (x <= x2) {
        float t =
            (
                x -
                x1
            ) /
            (
                x2 -
                x1
            );

        t = smoothCurve(t);

        return mix(
            uToneShadow,
            uToneMid,
            t
        );
    }

    if (x <= x3) {
        float t =
            (
                x -
                x2
            ) /
            (
                x3 -
                x2
            );

        t = smoothCurve(t);

        return mix(
            uToneMid,
            uToneHighlight,
            t
        );
    }

    float t =
        (
            x -
            x3
        ) /
        (
            x4 -
            x3
        );

    t = smoothCurve(t);

    return mix(
        uToneHighlight,
        uToneWhite,
        t
    );
}

vec3 applyToneCurve(
    vec3 rgb
) {
    float oldLum =
        luminanceOf(
            rgb
        );

    float newLum =
        toneCurveValue(
            oldLum
        );

    if (oldLum <= 0.00001) {
        return vec3(
            newLum
        );
    }

    float ratio =
        newLum /
        oldLum;

    return clamp(
        rgb *
        ratio,
        0.0,
        1.0
    );
}

// ============================================================================
// COLOR
// ============================================================================

vec3 applyColorAdjustment(
    vec3 rgb
) {
    float intensity =
        clamp(
            uIntensity,
            0.0,
            1.0
        );

    float temperature =
        uTemperature *
        intensity;

    float tint =
        uTint *
        intensity;

    float saturation =
        uSaturation *
        intensity;

    float vibrance =
        uVibrance *
        intensity;

    // ------------------------------------------------------------------------
    // TEMPERATURE
    // ------------------------------------------------------------------------

    rgb.r +=
        temperature *
        0.10;

    rgb.g +=
        temperature *
        0.025;

    rgb.b -=
        temperature *
        0.10;

    // ------------------------------------------------------------------------
    // TINT
    // ------------------------------------------------------------------------

    rgb.r +=
        tint *
        0.035;

    rgb.g -=
        tint *
        0.055;

    rgb.b +=
        tint *
        0.035;

    rgb = clamp(
        rgb,
        0.0,
        1.0
    );

    // ------------------------------------------------------------------------
    // SATURATION
    // ------------------------------------------------------------------------

    float lum =
        luminanceOf(
            rgb
        );

    float saturationFactor =
        1.0 +
        saturation;

    rgb =
        vec3(lum) +
        (
            rgb -
            vec3(lum)
        ) *
        saturationFactor;

    // ------------------------------------------------------------------------
    // VIBRANCE
    // ------------------------------------------------------------------------

    float maxChannel =
        max(
            rgb.r,
            max(
                rgb.g,
                rgb.b
            )
        );

    float minChannel =
        min(
            rgb.r,
            min(
                rgb.g,
                rgb.b
            )
        );

    float chroma =
        clamp(
            maxChannel -
            minChannel,
            0.0,
            1.0
        );

    float weakColorMask =
        1.0 -
        chroma;

    float vibranceFactor =
        1.0 +
        (
            vibrance *
            weakColorMask
        );

    rgb =
        vec3(lum) +
        (
            rgb -
            vec3(lum)
        ) *
        vibranceFactor;

    return clamp(
        rgb,
        0.0,
        1.0
    );
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
    vec2 fragCoord =
        FlutterFragCoord().xy;

    vec2 uv =
        fragCoord /
        uSize;

    vec4 color =
        texture(
            uTexture,
            uv
        );

    vec3 rgb =
        color.rgb;

    float intensity =
        clamp(
            uIntensity,
            0.0,
            1.0
        );

    // ========================================================================
    // BASE EXPOSURE
    // ========================================================================

    float exposureMultiplier =
        pow(
            2.0,
            uExposure *
            intensity
        );

    rgb *=
        exposureMultiplier;

    // ========================================================================
    // CONTRAST
    // ========================================================================

    float contrastAmount =
        uContrast *
        intensity;

    rgb =
        (
            rgb -
            0.5
        ) *
        (
            1.0 +
            contrastAmount
        ) +
        0.5;

    rgb = clamp(
        rgb,
        0.0,
        1.0
    );

    // ========================================================================
    // COLOR
    // ========================================================================

    rgb =
        applyColorAdjustment(
            rgb
        );

    // ========================================================================
    // TONE CURVE
    // ========================================================================

    rgb =
        applyToneCurve(
            rgb
        );

    // ========================================================================
    // RADIAL POSITION
    // ========================================================================

    vec2 centered =
        uv -
        vec2(
            0.5
        );

    float aspect =
        uSize.x /
        uSize.y;

    centered.x *=
        aspect;

    float maxRadius =
        length(
            vec2(
                0.5 *
                aspect,
                0.5
            )
        );

    float distanceFromCenter =
        length(
            centered
        ) /
        maxRadius;

    distanceFromCenter =
        clamp(
            distanceFromCenter,
            0.0,
            1.0
        );

    // ========================================================================
    // CENTER SUBJECT PROTECTION
    // ========================================================================
    //
    // Imagine a selfie:
    //
    // center      -> face / person remains alive
    // middle      -> gradual falloff
    // outer area  -> strong night darkness
    //
    // ========================================================================

    float centerProtection =
        1.0 -
        smoothstep(
            0.08,
            0.58,
            distanceFromCenter
        );

    // ========================================================================
    // CENTER GLOW
    // ========================================================================

    float glowMask =
        1.0 -
        smoothstep(
            0.05,
            0.58,
            distanceFromCenter
        );

    glowMask =
        smoothCurve(
            glowMask
        );

    // Stronger than before.
    float glowAmount =
        uCenterGlow *
        intensity *
        0.52 *
        glowMask;

    // Warm skin-friendly center glow.
    rgb.r +=
        glowAmount *
        1.08;

    rgb.g +=
        glowAmount *
        1.00;

    rgb.b +=
        glowAmount *
        0.88;

    // ========================================================================
    // CENTER MIDTONE LIFT
    // ========================================================================
    //
    // Keeps a selfie subject readable without making the whole image bright.
    // ========================================================================

    float centerLum =
        luminanceOf(
            rgb
        );

    float subjectLiftMask =
        centerProtection *
        (
            1.0 -
            smoothstep(
                0.72,
                0.96,
                centerLum
            )
        );

    float subjectLift =
        0.10 *
        intensity *
        subjectLiftMask;

    rgb +=
        vec3(
            subjectLift *
            1.03,
            subjectLift,
            subjectLift *
            0.94
        );

    // ========================================================================
    // NIGHT EDGE DARKNESS
    // ========================================================================
    //
    // This is stronger than a normal vignette.
    //
    // Darkness starts relatively early and becomes aggressive toward
    // the corners.
    // ========================================================================

    float edgeStart =
        0.24;

    float edgeMask =
        smoothstep(
            edgeStart,
            1.0,
            distanceFromCenter
        );

    // Non-linear:
    // mild near center,
    // very dark toward outer edges.
    edgeMask =
        pow(
            edgeMask,
            1.55
        );

    // User-controlled vignette plus an extra Midnight-specific night falloff.
    float nightDarkness =
        (
            0.18 +
            (
                uVignette *
                0.82
            )
        ) *
        intensity *
        edgeMask;

    nightDarkness =
        clamp(
            nightDarkness,
            0.0,
            0.82
        );

    rgb *=
        1.0 -
        nightDarkness;

    // ========================================================================
    // OUTER NIGHT EXPOSURE
    // ========================================================================
    //
    // This goes further than a normal vignette.
    // Darkens real scene content around the person.
    // ========================================================================

    float outerMask =
        smoothstep(
            0.46,
            1.0,
            distanceFromCenter
        );

    outerMask =
        pow(
            outerMask,
            1.30
        );

    float outerExposure =
        mix(
            1.0,
            0.64,
            outerMask *
            intensity
        );

    rgb *=
        outerExposure;

    // ========================================================================
    // DEEPEN OUTER BLACKS
    // ========================================================================

    float outerLuminance =
        luminanceOf(
            rgb
        );

    float shadowMask =
        1.0 -
        smoothstep(
            0.20,
            0.68,
            outerLuminance
        );

    float deepBlackAmount =
        outerMask *
        shadowMask *
        intensity *
        0.16;

    rgb -=
        vec3(
            deepBlackAmount
        );

    // ========================================================================
    // SUBTLE NIGHT COLOR CHARACTER
    // ========================================================================
    //
    // Outside gets slightly cooler/neutral while center stays warmer.
    // Very subtle — not the old strong blue Midnight.
    // ========================================================================

    float coolEdge =
        outerMask *
        intensity;

    rgb.r -=
        0.010 *
        coolEdge;

    rgb.g -=
        0.004 *
        coolEdge;

    rgb.b +=
        0.008 *
        coolEdge;

    // ========================================================================
    // HIGHLIGHT PRESERVATION IN CENTER
    // ========================================================================

    float highlightLum =
        luminanceOf(
            rgb
        );

    float centerHighlight =
        centerProtection *
        smoothstep(
            0.58,
            0.90,
            highlightLum
        );

    rgb +=
        vec3(
            0.025,
            0.018,
            0.010
        ) *
        centerHighlight *
        intensity;

    // ========================================================================
    // FINAL
    // ========================================================================

    rgb = clamp(
        rgb,
        0.0,
        1.0
    );

    fragColor =
        vec4(
            rgb,
            color.a
        );
}