import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MemoryFilter {
  all,
  images,
  notes,
}

final memoryFilterProvider = StateProvider<MemoryFilter>(
  (ref) => MemoryFilter.all,
);