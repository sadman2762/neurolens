import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MemoryFilter { all, images, notes, pdfs }

final memoryFilterProvider = StateProvider<MemoryFilter>(
  (ref) => MemoryFilter.all,
);
