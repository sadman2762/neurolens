import 'package:file_picker/file_picker.dart';

class PdfPickerService {
  Future<PlatformFile?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first;
  }
}
