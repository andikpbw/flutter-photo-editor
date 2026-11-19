import 'package:flutter/foundation.dart';

/// Curated category grouping for color-grading presets.
enum PhotoFilterCategory {
  /// Displays all available presets.
  all,

  /// High-vibrancy punchy color presets.
  vivid,

  /// Film-inspired teal, gold, and dramatic cinema looks.
  cinematic,

  /// Analog print, Kodak/Fuji, vintage, and matte fade looks.
  film,

  /// Clean monochrome, noir, silver-gelatin, and sepia looks.
  monochrome,

  /// Soft pastel, Nordic, dreamy, and neon cyber looks.
  moody,
}

/// A color-grading filter defined by a 4x5 RGBA transformation matrix.
///
/// The [matrix] contains 20 floating-point elements compatible with Flutter's
/// `ColorFilter.matrix`. The translation column (indices 4, 9, 14, and 19)
/// uses the 0–255 channel scale.
@immutable
class PhotoFilter {
  /// Creates a [PhotoFilter] with a unique [id], display [name], optional
  /// [category], and a 20-element 4x5 color transformation [matrix].
  const PhotoFilter({
    required this.id,
    required this.name,
    required this.matrix,
    this.category = PhotoFilterCategory.all,
  });

  /// Unique identifier used for equality and state serialization.
  final String id;

  /// Human-readable display label shown in the filter strip.
  final String name;

  /// Category grouping used by the filter browser.
  final PhotoFilterCategory category;

  /// 20-element 4x5 RGBA color matrix.
  final List<double> matrix;

  /// Returns `true` if this filter represents the unmodified original look.
  bool get isOriginal => id == PhotoFilters.original.id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PhotoFilter &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        listEquals(other.matrix, matrix);
  }

  @override
  int get hashCode => Object.hash(id, name, category, Object.hashAll(matrix));

  @override
  String toString() => 'PhotoFilter(id: $id, name: $name)';
}

/// Curated collection of 24 studio-grade color filters built into `photo_editor_studio`.
abstract final class PhotoFilters {
  /// Unmodified identity filter.
  static const PhotoFilter original = PhotoFilter(
    id: 'original',
    name: 'Original',
    matrix: <double>[
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Vibrant color boost with crisp midtone contrast.
  static const PhotoFilter vivid = PhotoFilter(
    id: 'vivid',
    name: 'Vivid',
    category: PhotoFilterCategory.vivid,
    matrix: <double>[
      1.26,
      -0.10,
      -0.04,
      0,
      -6,
      -0.06,
      1.24,
      -0.06,
      0,
      -6,
      -0.05,
      -0.09,
      1.28,
      0,
      -6,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Warm vibrant grading with rich golden highlights.
  static const PhotoFilter vividWarm = PhotoFilter(
    id: 'vivid_warm',
    name: 'Warm',
    category: PhotoFilterCategory.vivid,
    matrix: <double>[
      1.28,
      -0.06,
      -0.06,
      0,
      6,
      -0.04,
      1.18,
      -0.05,
      0,
      2,
      -0.06,
      -0.08,
      1.06,
      0,
      -8,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Crisp cool vibrancy with clear cyan and azure undertones.
  static const PhotoFilter vividCool = PhotoFilter(
    id: 'vivid_cool',
    name: 'Cool',
    category: PhotoFilterCategory.vivid,
    matrix: <double>[
      1.08,
      -0.06,
      -0.02,
      0,
      -6,
      -0.04,
      1.16,
      0.02,
      0,
      0,
      -0.04,
      -0.04,
      1.28,
      0,
      10,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Rich editorial slide-film emerald and sky pop.
  static const PhotoFilter velvia = PhotoFilter(
    id: 'velvia',
    name: 'Velvia',
    category: PhotoFilterCategory.vivid,
    matrix: <double>[
      1.32,
      -0.12,
      -0.04,
      0,
      -10,
      -0.06,
      1.30,
      -0.08,
      0,
      -8,
      -0.04,
      -0.08,
      1.30,
      0,
      -6,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Deep cinematic teal shadows and golden warm highlights.
  static const PhotoFilter cinematic = PhotoFilter(
    id: 'cinematic',
    name: 'Cinematic',
    category: PhotoFilterCategory.cinematic,
    matrix: <double>[
      1.18,
      -0.04,
      -0.08,
      0,
      -4,
      -0.02,
      1.08,
      0.02,
      0,
      -2,
      -0.08,
      0.08,
      1.14,
      0,
      6,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Hollywood teal-and-orange split-toned look.
  static const PhotoFilter tealOrange = PhotoFilter(
    id: 'teal_orange',
    name: 'Teal Gold',
    category: PhotoFilterCategory.cinematic,
    matrix: <double>[
      1.26,
      0.04,
      -0.14,
      0,
      -4,
      -0.02,
      1.06,
      0.04,
      0,
      -2,
      -0.14,
      0.14,
      1.18,
      0,
      8,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// High-impact dramatic grading with deep contrast and muted color.
  static const PhotoFilter dramatic = PhotoFilter(
    id: 'dramatic',
    name: 'Dramatic',
    category: PhotoFilterCategory.cinematic,
    matrix: <double>[
      1.32,
      -0.14,
      -0.06,
      0,
      -24,
      -0.12,
      1.26,
      -0.06,
      0,
      -22,
      -0.10,
      -0.10,
      1.22,
      0,
      -18,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Warm sunset glow with soft golden atmosphere.
  static const PhotoFilter goldenHour = PhotoFilter(
    id: 'golden_hour',
    name: 'Golden',
    category: PhotoFilterCategory.cinematic,
    matrix: <double>[
      1.22,
      0.06,
      -0.04,
      0,
      12,
      0.02,
      1.10,
      -0.04,
      0,
      4,
      -0.04,
      -0.04,
      0.88,
      0,
      -6,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Deep twilight cinema look with indigo shadows and crisp contrast.
  static const PhotoFilter blockbuster = PhotoFilter(
    id: 'blockbuster',
    name: 'Midnight',
    category: PhotoFilterCategory.cinematic,
    matrix: <double>[
      1.04,
      -0.06,
      -0.02,
      0,
      -14,
      -0.04,
      1.08,
      0.06,
      0,
      -10,
      -0.04,
      0.08,
      1.26,
      0,
      6,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Classic portrait film emulation with warm skin tones and soft shadows.
  static const PhotoFilter portra = PhotoFilter(
    id: 'portra',
    name: 'Portra',
    category: PhotoFilterCategory.film,
    matrix: <double>[
      1.06,
      0.06,
      0.02,
      0,
      8,
      0.02,
      1.02,
      0.02,
      0,
      6,
      0.02,
      0.04,
      0.94,
      0,
      10,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Classic 35mm golden consumer print film look.
  static const PhotoFilter kodak400 = PhotoFilter(
    id: 'kodak_400',
    name: 'Gold 400',
    category: PhotoFilterCategory.film,
    matrix: <double>[
      1.14,
      0.05,
      -0.02,
      0,
      6,
      0.02,
      1.06,
      -0.02,
      0,
      4,
      -0.02,
      0.04,
      0.90,
      0,
      4,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Matte lifted-blacks analog film fade.
  static const PhotoFilter fade = PhotoFilter(
    id: 'fade',
    name: 'Fade',
    category: PhotoFilterCategory.film,
    matrix: <double>[
      0.86,
      0.06,
      0.02,
      0,
      22,
      0.04,
      0.86,
      0.04,
      0,
      20,
      0.04,
      0.06,
      0.88,
      0,
      24,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Nostalgic warm analog print aesthetic.
  static const PhotoFilter vintage = PhotoFilter(
    id: 'vintage',
    name: 'Vintage',
    category: PhotoFilterCategory.film,
    matrix: <double>[
      0.94,
      0.16,
      0.04,
      0,
      10,
      0.06,
      0.88,
      0.06,
      0,
      6,
      0.04,
      0.10,
      0.72,
      0,
      14,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Sun-washed retro 1970s amber print cast.
  static const PhotoFilter retro70s = PhotoFilter(
    id: 'retro_70s',
    name: 'Retro 70s',
    category: PhotoFilterCategory.film,
    matrix: <double>[
      1.04,
      0.14,
      -0.04,
      0,
      14,
      0.04,
      0.94,
      0.02,
      0,
      8,
      0.02,
      0.08,
      0.76,
      0,
      12,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Editorial muted cool palette inspired by Scandinavian photography.
  static const PhotoFilter nordic = PhotoFilter(
    id: 'nordic',
    name: 'Nordic',
    category: PhotoFilterCategory.moody,
    matrix: <double>[
      0.88,
      0.06,
      0.04,
      0,
      4,
      0.04,
      0.94,
      0.04,
      0,
      6,
      0.02,
      0.08,
      1.04,
      0,
      10,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Airy pastel softness with gentle rose-cream highlights.
  static const PhotoFilter pastel = PhotoFilter(
    id: 'pastel',
    name: 'Pastel',
    category: PhotoFilterCategory.moody,
    matrix: <double>[
      0.92,
      0.08,
      0.04,
      0,
      18,
      0.05,
      0.90,
      0.06,
      0,
      14,
      0.06,
      0.06,
      0.94,
      0,
      18,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Dreamy soft blush haze with lifted shadows.
  static const PhotoFilter dreamy = PhotoFilter(
    id: 'dreamy',
    name: 'Dreamy',
    category: PhotoFilterCategory.moody,
    matrix: <double>[
      1.02,
      0.06,
      0.06,
      0,
      14,
      0.04,
      0.94,
      0.06,
      0,
      10,
      0.08,
      0.04,
      1.04,
      0,
      16,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Deep moody forest shadows with desaturated organic greens.
  static const PhotoFilter forest = PhotoFilter(
    id: 'forest',
    name: 'Forest',
    category: PhotoFilterCategory.moody,
    matrix: <double>[
      0.92,
      0.04,
      -0.02,
      0,
      -10,
      0.02,
      1.04,
      0.02,
      0,
      -4,
      0.00,
      0.06,
      0.90,
      0,
      -8,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Punchy neon cyberpunk contrast with magenta-cyan split.
  static const PhotoFilter cyber = PhotoFilter(
    id: 'cyber',
    name: 'Cyber',
    category: PhotoFilterCategory.moody,
    matrix: <double>[
      1.24,
      -0.10,
      0.08,
      0,
      -10,
      -0.08,
      1.02,
      0.14,
      0,
      -8,
      0.10,
      0.06,
      1.32,
      0,
      8,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Clean neutral black-and-white conversion using Rec.709 luminance weights.
  static const PhotoFilter mono = PhotoFilter(
    id: 'mono',
    name: 'Mono',
    category: PhotoFilterCategory.monochrome,
    matrix: <double>[
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// High-contrast classic film noir monochrome.
  static const PhotoFilter noir = PhotoFilter(
    id: 'noir',
    name: 'Noir',
    category: PhotoFilterCategory.monochrome,
    matrix: <double>[
      0.34,
      0.88,
      0.14,
      0,
      -44,
      0.34,
      0.88,
      0.14,
      0,
      -44,
      0.34,
      0.88,
      0.14,
      0,
      -44,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Soft luminous silver-gelatin monochrome.
  static const PhotoFilter silvertone = PhotoFilter(
    id: 'silvertone',
    name: 'Silver',
    category: PhotoFilterCategory.monochrome,
    matrix: <double>[
      0.26,
      0.68,
      0.12,
      0,
      8,
      0.26,
      0.68,
      0.12,
      0,
      8,
      0.26,
      0.68,
      0.12,
      0,
      12,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// Classic darkroom sepia toning.
  static const PhotoFilter sepia = PhotoFilter(
    id: 'sepia',
    name: 'Sepia',
    category: PhotoFilterCategory.monochrome,
    matrix: <double>[
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
  );

  /// All 24 built-in studio filters in recommended display order.
  static const List<PhotoFilter> presets = <PhotoFilter>[
    original,
    vivid,
    vividWarm,
    vividCool,
    velvia,
    cinematic,
    tealOrange,
    dramatic,
    goldenHour,
    blockbuster,
    portra,
    kodak400,
    fade,
    vintage,
    retro70s,
    nordic,
    pastel,
    dreamy,
    forest,
    cyber,
    mono,
    noir,
    silvertone,
    sepia,
  ];

  /// Returns filters matching [category] while keeping [original] first.
  static List<PhotoFilter> forCategory(
    List<PhotoFilter> source,
    PhotoFilterCategory category,
  ) {
    if (category == PhotoFilterCategory.all) {
      return source;
    }
    return source
        .where((f) => f.isOriginal || f.category == category)
        .toList(growable: false);
  }

  /// Looks up a built-in filter by [id], falling back to [original] if not found.
  static PhotoFilter byId(String id, {List<PhotoFilter>? extraFilters}) {
    for (final filter in presets) {
      if (filter.id == id) {
        return filter;
      }
    }
    if (extraFilters != null) {
      for (final filter in extraFilters) {
        if (filter.id == id) {
          return filter;
        }
      }
    }
    return original;
  }
}
