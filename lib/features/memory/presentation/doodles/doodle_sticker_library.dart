class DoodleStickerAsset {
  const DoodleStickerAsset({
    required this.id,
    required this.assetPath,
    required this.category,
    required this.label,
  });

  final String id;
  final String assetPath;
  final String category;
  final String label;
}

class DoodleStickerLibrary {
  static const List<String> categories = [
    'Cute',
    'Love',
  ];

  static const List<DoodleStickerAsset> stickers = [
    // =========================================================================
    // CUTE
    // =========================================================================

    DoodleStickerAsset(
      id: 'cute_gift_bag',
      assetPath: 'assets/doodles/cute/gift-bag.png',
      category: 'Cute',
      label: 'Gift Bag',
    ),

    DoodleStickerAsset(
      id: 'cute_hand_heart',
      assetPath: 'assets/doodles/cute/hand-heart.png',
      category: 'Cute',
      label: 'Hand Heart',
    ),

    DoodleStickerAsset(
      id: 'cute_heart_2',
      assetPath: 'assets/doodles/cute/heart_2.png',
      category: 'Cute',
      label: 'Heart',
    ),

    DoodleStickerAsset(
      id: 'cute_heart_shape',
      assetPath: 'assets/doodles/cute/heart-shape.png',
      category: 'Cute',
      label: 'Heart Shape',
    ),

    DoodleStickerAsset(
      id: 'cute_heart',
      assetPath: 'assets/doodles/cute/heart.png',
      category: 'Cute',
      label: 'Heart',
    ),

    DoodleStickerAsset(
      id: 'cute_love_letter',
      assetPath: 'assets/doodles/cute/love-letter.png',
      category: 'Cute',
      label: 'Love Letter',
    ),

    DoodleStickerAsset(
      id: 'cute_love',
      assetPath: 'assets/doodles/cute/love.png',
      category: 'Cute',
      label: 'Love',
    ),

    DoodleStickerAsset(
      id: 'cute_panda',
      assetPath: 'assets/doodles/cute/panda.png',
      category: 'Cute',
      label: 'Panda',
    ),

    DoodleStickerAsset(
      id: 'cute_romantic_music',
      assetPath: 'assets/doodles/cute/romantic-music.png',
      category: 'Cute',
      label: 'Romantic Music',
    ),

    DoodleStickerAsset(
      id: 'cute_rose',
      assetPath: 'assets/doodles/cute/rose.png',
      category: 'Cute',
      label: 'Rose',
    ),

    // =========================================================================
    // LOVE
    // =========================================================================

    DoodleStickerAsset(
      id: 'love_balloon',
      assetPath: 'assets/doodles/love/balloon.png',
      category: 'Love',
      label: 'Balloon',
    ),

    DoodleStickerAsset(
      id: 'love_chat_bubble',
      assetPath: 'assets/doodles/love/chat-bubble.png',
      category: 'Love',
      label: 'Chat Bubble',
    ),

    DoodleStickerAsset(
      id: 'love_duck',
      assetPath: 'assets/doodles/love/duck.png',
      category: 'Love',
      label: 'Duck',
    ),

    DoodleStickerAsset(
      id: 'love_heart',
      assetPath: 'assets/doodles/love/heart.png',
      category: 'Love',
      label: 'Heart',
    ),

    DoodleStickerAsset(
      id: 'love_kissing',
      assetPath: 'assets/doodles/love/kissing.png',
      category: 'Love',
      label: 'Kissing',
    ),

    DoodleStickerAsset(
      id: 'love_love_2',
      assetPath: 'assets/doodles/love/love_2.png',
      category: 'Love',
      label: 'Love',
    ),

    DoodleStickerAsset(
      id: 'love_love_you',
      assetPath: 'assets/doodles/love/love-you.png',
      category: 'Love',
      label: 'Love You',
    ),

    DoodleStickerAsset(
      id: 'love_love',
      assetPath: 'assets/doodles/love/love.png',
      category: 'Love',
      label: 'Love',
    ),

    DoodleStickerAsset(
      id: 'love_panda',
      assetPath: 'assets/doodles/love/panda.png',
      category: 'Love',
      label: 'Panda',
    ),

    DoodleStickerAsset(
      id: 'love_smile',
      assetPath: 'assets/doodles/love/smile.png',
      category: 'Love',
      label: 'Smile',
    ),

    DoodleStickerAsset(
      id: 'love_xoxo',
      assetPath: 'assets/doodles/love/xoxo.png',
      category: 'Love',
      label: 'XOXO',
    ),
  ];

  static List<DoodleStickerAsset> byCategory(
    String category,
  ) {
    return stickers
        .where(
          (sticker) => sticker.category == category,
        )
        .toList();
  }
}