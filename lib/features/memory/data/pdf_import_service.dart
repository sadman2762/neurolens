import 'package:neurolens/features/memory/data/pdf_picker_service.dart';
import 'package:neurolens/features/memory/data/pdf_text_extractor_service.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';

class PdfImportService {
  PdfImportService({
    required PdfPickerService pickerService,
    required PdfTextExtractorService textExtractorService,
    required MemoryRepositoryImpl memoryRepository,
  })  : _pickerService = pickerService,
        _textExtractorService = textExtractorService,
        _memoryRepository = memoryRepository;

  final PdfPickerService _pickerService;
  final PdfTextExtractorService _textExtractorService;
  final MemoryRepositoryImpl _memoryRepository;

  Future<bool> importPdf() async {
    final file = await _pickerService.pickPdf();

    if (file == null || file.path == null) {
      return false;
    }

    final extractedText = await _textExtractorService.extractText(file.path!);

    final memory = Memory(
      id: 'pdf_${DateTime.now().microsecondsSinceEpoch}',
      type: 'pdf',
      title: file.name,
      content: extractedText.isEmpty ? null : extractedText,
      originalPath: file.path,
      createdAt: DateTime.now(),
    );

    await _memoryRepository.saveMemory(memory);

    return true;
  }
}