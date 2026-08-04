import 'package:neurolens/features/memory/data/pdf_picker_service.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';

class PdfImportService {
  PdfImportService({
    required PdfPickerService pickerService,
    required MemoryRepositoryImpl memoryRepository,
  })  : _pickerService = pickerService,
        _memoryRepository = memoryRepository;

  final PdfPickerService _pickerService;
  final MemoryRepositoryImpl _memoryRepository;

  Future<bool> importPdf() async {
    final file = await _pickerService.pickPdf();

    if (file == null || file.path == null) {
      return false;
    }

    final memory = Memory(
      id: 'pdf_${DateTime.now().microsecondsSinceEpoch}',
      type: 'pdf',
      title: file.name,
      originalPath: file.path,
      createdAt: DateTime.now(),
    );

    await _memoryRepository.saveMemory(memory);

    return true;
  }
}