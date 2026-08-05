import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoPickerService {
  const PhotoPickerService();

  static const int maximumSelectionCount = 50;

  Future<List<AssetEntity>> pickPhotos({required BuildContext context}) async {
    final selectedAssets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: maximumSelectionCount,
        requestType: RequestType.image,
        specialPickerType: SpecialPickerType.noPreview,
        themeColor: Color(0xFF8B5CF6),
        textDelegate: EnglishAssetPickerTextDelegate(),
      ),
    );

    return selectedAssets ?? const <AssetEntity>[];
  }
}
