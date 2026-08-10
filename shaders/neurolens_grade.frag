#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;

uniform float uExposure;
uniform float uContrast;
uniform float uSaturation;

uniform float uTemperature;
uniform float uTint;

uniform float uFade;
uniform float uShadowLift;
uniform float uHighlightRollOff;

uniform float uVignette;
uniform float uIntensity;

uniform sampler2D uTexture;

out vec4 fragColor;

// =============================================================================
// HELPERS
// =============================================================================

float luminance(vec3 color) {
  return dot(
    color,
    vec3(
      0.2126,
      0.7152,
      0.0722
    )
  );
}

vec3 applyExposure(
  vec3 color,
  float exposure
) {
  float multiplier =
      pow(
        2.0,
        exposure
      );

  return color * multiplier;
}

vec3 applyContrast(
  vec3 color,
  float contrast
) {
  float factor =
      1.0 + contrast;

  return (
    color - 0.5
  ) *
  factor +
  0.5;
}

vec3 applySaturation(
  vec3 color,
  float saturation
) {
  float luma =
      luminance(
        color
      );

  vec3 gray =
      vec3(
        luma
      );

  return mix(
    gray,
    color,
    1.0 + saturation
  );
}

vec3 applyTemperature(
  vec3 color,
  float temperature
) {
  float warm =
      temperature;

  color.r +=
      warm *
      0.10;

  color.g +=
      warm *
      0.035;

  color.b -=
      warm *
      0.11;

  return color;
}

vec3 applyTint(
  vec3 color,
  float tint
) {
  color.r +=
      tint *
      0.035;

  color.g -=
      tint *
      0.050;

  color.b +=
      tint *
      0.030;

  return color;
}

vec3 applyShadowLift(
  vec3 color,
  float amount
) {
  float luma =
      luminance(
        color
      );

  float shadowMask =
      1.0 -
      smoothstep(
        0.0,
        0.55,
        luma
      );

  return color +
      vec3(
        amount *
        0.16 *
        shadowMask
      );
}

vec3 applyHighlightRollOff(
  vec3 color,
  float amount
) {
  float luma =
      luminance(
        color
      );

  float highlightMask =
      smoothstep(
        0.55,
        1.0,
        luma
      );

  vec3 compressed =
      color /
      (
        1.0 +
        color *
        amount *
        0.45
      );

  return mix(
    color,
    compressed,
    highlightMask
  );
}

vec3 applyFade(
  vec3 color,
  float fade
) {
  // Lift blacks.
  color =
      mix(
        color,
        color * 0.86 +
            vec3(
              0.11
            ),
        fade
      );

  // Slightly soften peak whites.
  color =
      mix(
        color,
        min(
          color,
          vec3(
            0.96
          )
        ),
        fade * 0.30
      );

  return color;
}

vec3 applyVignette(
  vec3 color,
  vec2 uv,
  float amount
) {
  vec2 centered =
      uv -
      vec2(
        0.5
      );

  float distanceFromCenter =
      length(
        centered
      );

  float vignette =
      smoothstep(
        0.30,
        0.74,
        distanceFromCenter
      );

  return color *
      (
        1.0 -
        vignette *
        amount *
        0.50
      );
}

// =============================================================================
// MAIN
// =============================================================================

void main() {
  vec2 pixel =
      FlutterFragCoord().xy;

  vec2 uv =
    pixel /
    uSize;

// ImageFilter input textures are vertically flipped
// when Flutter runs through Impeller OpenGLES.
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

vec4 source =
    texture(
      uTexture,
      uv
    );

  vec3 original =
      source.rgb;

  vec3 graded =
      original;

  graded =
      applyExposure(
        graded,
        uExposure
      );

  graded =
      applyContrast(
        graded,
        uContrast
      );

  graded =
      applySaturation(
        graded,
        uSaturation
      );

  graded =
      applyTemperature(
        graded,
        uTemperature
      );

  graded =
      applyTint(
        graded,
        uTint
      );

  graded =
      applyShadowLift(
        graded,
        uShadowLift
      );

  graded =
      applyHighlightRollOff(
        graded,
        uHighlightRollOff
      );

  graded =
      applyFade(
        graded,
        uFade
      );

  graded =
      applyVignette(
        graded,
        uv,
        uVignette
      );

  graded =
      clamp(
        graded,
        0.0,
        1.0
      );

  vec3 finalColor =
      mix(
        original,
        graded,
        clamp(
          uIntensity,
          0.0,
          1.0
        )
      );

  fragColor =
      vec4(
        finalColor,
        source.a
      );
}