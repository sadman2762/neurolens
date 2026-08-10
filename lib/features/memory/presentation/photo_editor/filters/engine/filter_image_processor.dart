import 'dart:typed_data';
import 'dart:ui' as ui;

import 'filter_engine.dart';
import 'filter_pixel_pipeline.dart';
import 'filter_recipe.dart';
import 'grain_processor.dart';
import 'halation_processor.dart';
import 'sharpen_processor.dart';
import 'spatial_effects_processor.dart';

class FilterImageProcessor {
  const FilterImageProcessor._();

  static Future<Uint8List> apply({
    required Uint8List imageBytes,
    required FilterRecipe recipe,
    required double intensity,
  }) async {
    final resolved = FilterEngine.resolve(
      recipe: recipe,
      intensity: intensity,
    );

    if (resolved.intensity <= 0.001) {
      return imageBytes;
    }

    final codec = await ui.instantiateImageCodec(
      imageBytes,
    );

    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );

        if (byteData == null) {
          throw StateError(
            'Could not decode image pixels.',
          );
        }

        final source = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        final output = Uint8List(
          source.length,
        );

        final width = image.width;
        final height = image.height;

        // =====================================================================
        // PROCESS EVERY PIXEL
        // =====================================================================

        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final index =
                ((y * width) + x) * 4;

            final r =
                source[index] / 255.0;

            final g =
                source[index + 1] / 255.0;

            final b =
                source[index + 2] / 255.0;

            final a =
                source[index + 3];

            // =================================================================
            // 1. COLOR PIPELINE
            // =================================================================
            //
            // Light
            // Color / white balance
            // Tone curve
            // Selective HSL
            // Shadow / midtone / highlight grading
            // =================================================================

            final colorResult =
                FilterPixelPipeline.apply(
              r: r,
              g: g,
              b: b,
              recipe: resolved.recipe,
            );

            // =================================================================
            // 2. SPATIAL EFFECTS
            // =================================================================
            //
            // Center glow
            // Vignette
            // =================================================================

            final spatialResult =
                SpatialEffectsProcessor.apply(
              r: colorResult[0],
              g: colorResult[1],
              b: colorResult[2],
              x: x,
              y: y,
              width: width,
              height: height,
              effects:
                  resolved.recipe.effects,
            );

            // =================================================================
            // 3. GRAIN
            // =================================================================

            final grainResult =
                GrainProcessor.apply(
              r: spatialResult[0],
              g: spatialResult[1],
              b: spatialResult[2],
              x: x,
              y: y,
              grain:
                  resolved
                      .recipe
                      .effects
                      .grain,
            );

            // =================================================================
            // WRITE FIRST-PASS OUTPUT
            // =================================================================

            output[index] =
                _toChannel(
              grainResult[0],
            );

            output[index + 1] =
                _toChannel(
              grainResult[1],
            );

            output[index + 2] =
                _toChannel(
              grainResult[2],
            );

            // Preserve original alpha.
            output[index + 3] =
                a;
          }
        }

        // =====================================================================
        // 4. SHARPEN
        // =====================================================================
        //
        // Sharpening needs neighbouring pixels, so it runs after the
        // per-pixel processing has completed for the whole image.
        // =====================================================================

        final sharpenedOutput =
            SharpenProcessor.apply(
          pixels: output,
          width: width,
          height: height,
          sharpen:
              resolved
                  .recipe
                  .effects
                  .sharpen,
        );

        // =====================================================================
        // 5. HALATION / HIGHLIGHT BLOOM
        // =====================================================================
        //
        // This adds a subtle warm reddish/orange glow around bright areas.
        // It runs after sharpening so the bloom remains soft and photographic.
        // =====================================================================

        final finalOutput =
            HalationProcessor.apply(
          pixels: sharpenedOutput,
          width: width,
          height: height,
          halation:
              resolved
                  .recipe
                  .effects
                  .halation,
        );

        // =====================================================================
        // CREATE NEW IMAGE
        // =====================================================================

        final buffer =
            await ui.ImmutableBuffer.fromUint8List(
          finalOutput,
        );

        try {
          final descriptor =
              ui.ImageDescriptor.raw(
            buffer,
            width: width,
            height: height,
            pixelFormat:
                ui.PixelFormat.rgba8888,
          );

          try {
            final processedCodec =
                await descriptor.instantiateCodec();

            try {
              final processedFrame =
                  await processedCodec.getNextFrame();

              final processedImage =
                  processedFrame.image;

              try {
                final pngData =
                    await processedImage.toByteData(
                  format:
                      ui.ImageByteFormat.png,
                );

                if (pngData == null) {
                  throw StateError(
                    'Could not encode processed image.',
                  );
                }

                return pngData.buffer.asUint8List(
                  pngData.offsetInBytes,
                  pngData.lengthInBytes,
                );
              } finally {
                processedImage.dispose();
              }
            } finally {
              processedCodec.dispose();
            }
          } finally {
            descriptor.dispose();
          }
        } finally {
          buffer.dispose();
        }
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  // ===========================================================================
  // CHANNEL CONVERSION
  // ===========================================================================

  static int _toChannel(
    double value,
  ) {
    return (
      value.clamp(
            0.0,
            1.0,
          ) *
          255.0
    )
        .round()
        .clamp(
          0,
          255,
        );
  }
}