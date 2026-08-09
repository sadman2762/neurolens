import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_text.dart';

class DoodleTextEditorSheet extends StatefulWidget {
  const DoodleTextEditorSheet({
    this.initialText,
    super.key,
  });

  final DoodleText? initialText;

  @override
  State<DoodleTextEditorSheet> createState() =>
      _DoodleTextEditorSheetState();
}

class _DoodleTextEditorSheetState
    extends State<DoodleTextEditorSheet> {
  static const Color _background =
      Color(0xFF0D1321);

  static const Color _surface =
      Color(0xFF141B2D);

  static const Color _purple =
      Color(0xFF8B5CF6);

  late final TextEditingController
      _controller;

  late Color _color;

  late double _fontSize;

  late double _curveAmount;

  late bool _bold;

  late bool _shadow;

  late bool _outline;

  late DoodleTextAlign _alignment;

  String? _fontFamily;

  late DoodleTextBubble _bubble;

  late Color _bubbleColor;

  late double _bubbleOpacity;

  static const List<Color> _colors = [
    Colors.white,
    Color(0xFFFFE082),
    Color(0xFFFFB4C8),
    Color(0xFFF8BBD0),
    Color(0xFFC4B5FD),
    Color(0xFFA5B4FC),
    Color(0xFF93C5FD),
    Color(0xFF67E8F9),
    Color(0xFF86EFAC),
    Color(0xFFFDE68A),
    Color(0xFFFCA5A5),
  ];

  static const List<Color> _bubbleColors = [
    Colors.white,
    Colors.black,
    Color(0xFFFFE082),
    Color(0xFFFFB4C8),
    Color(0xFFC4B5FD),
    Color(0xFF93C5FD),
    Color(0xFF67E8F9),
    Color(0xFF86EFAC),
    Color(0xFFFCA5A5),
  ];

  static const List<_DoodleFontOption>
      _fontOptions = [
    _DoodleFontOption(
      label:
          'Default',
      family:
          null,
      preview:
          'Aa',
    ),
    _DoodleFontOption(
      label:
          'Caveat',
      family:
          'Caveat',
      preview:
          'Aa',
    ),
    _DoodleFontOption(
      label:
          'Patrick',
      family:
          'PatrickHand',
      preview:
          'Aa',
    ),
    _DoodleFontOption(
      label:
          'Marker',
      family:
          'PermanentMarker',
      preview:
          'Aa',
    ),
    _DoodleFontOption(
      label:
          'Script',
      family:
          'DancingScript',
      preview:
          'Aa',
    ),
    _DoodleFontOption(
      label:
          'School',
      family:
          'Schoolbell',
      preview:
          'Aa',
    ),
  ];

  @override
  void initState() {
    super.initState();

    final initial =
        widget.initialText;

    _controller =
        TextEditingController(
      text:
          initial?.text ??
          '',
    );

    _color =
        initial?.color ??
        Colors.white;

    _fontSize =
        initial?.fontSize ??
        34;

    _curveAmount =
        initial?.curveAmount ??
        0;

    _bold =
        initial?.bold ??
        false;

    _shadow =
        initial?.shadowEnabled ??
        true;

    _outline =
        initial?.outlineEnabled ??
        false;

    _alignment =
        initial?.alignment ??
        DoodleTextAlign.center;

    _fontFamily =
        initial?.fontFamily;

    _bubble =
        initial?.bubble ??
        DoodleTextBubble.none;

    _bubbleColor =
        initial?.bubbleColor ??
        Colors.white;

    _bubbleOpacity =
        initial?.bubbleOpacity ??
        0.9;
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _done() {
    final text =
        _controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    final existing =
        widget.initialText;

    final result =
        DoodleText(
      id:
          existing?.id ??
          'text_${DateTime.now().microsecondsSinceEpoch}',
      text:
          text,
      position:
          existing?.position ??
          const Offset(
            80,
            120,
          ),
      color:
          _color,
      fontSize:
          _fontSize,
      scale:
          existing?.scale ??
          1,
      rotation:
          existing?.rotation ??
          0,
      zIndex:
          existing?.zIndex ??
          0,
      alignment:
          _alignment,
      fontFamily:
          _fontFamily,
      bold:
          _bold,
      shadowEnabled:
          _shadow,
      outlineEnabled:
          _outline,
      outlineColor:
          existing?.outlineColor ??
          Colors.black,
      curveAmount:
          _curveAmount,
      bubble:
          _bubble,
      bubbleColor:
          _bubbleColor,
      bubbleOpacity:
          _bubbleOpacity,
    );

    Navigator.of(context)
        .pop<DoodleText>(
      result,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: Container(
        decoration:
            const BoxDecoration(
          color:
              _background,
          borderRadius:
              BorderRadius.vertical(
            top:
                Radius.circular(
              28,
            ),
          ),
        ),
        padding:
            EdgeInsets.fromLTRB(
          18,
          8,
          18,
          18 +
              MediaQuery
                  .viewInsetsOf(
                    context,
                  )
                  .bottom,
        ),
        child:
            SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child:
                    Container(
                  width:
                      38,
                  height:
                      4,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white24,
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),

              Text(
                widget.initialText ==
                        null
                    ? 'Add Text'
                    : 'Edit Text',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height:
                    6,
              ),

              Text(
                'Create handwritten captions, curved text and outline bubbles.',
                style:
                    TextStyle(
                  color:
                      Colors.white.withValues(
                    alpha:
                        0.42,
                  ),
                  fontSize:
                      11,
                ),
              ),

              const SizedBox(
                height:
                    16,
              ),

              // =============================================================
              // PREVIEW
              // =============================================================

              Container(
                width:
                    double.infinity,
                height:
                    190,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black.withValues(
                    alpha:
                        0.32,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.white.withValues(
                      alpha:
                          0.05,
                    ),
                  ),
                ),
                child:
                    Center(
                  child:
                      _TextPreview(
                    text:
                        _controller.text
                                .trim()
                                .isEmpty
                            ? 'Your text'
                            : _controller.text,
                    color:
                        _color,
                    fontSize:
                        _fontSize.clamp(
                      20,
                      44,
                    ),
                    fontFamily:
                        _fontFamily,
                    bold:
                        _bold,
                    shadow:
                        _shadow,
                    alignment:
                        _alignment,
                    curveAmount:
                        _curveAmount,
                    bubble:
                        _bubble,
                    bubbleColor:
                        _bubbleColor,
                    bubbleOpacity:
                        _bubbleOpacity,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    14,
              ),

              TextField(
                controller:
                    _controller,
                autofocus:
                    true,
                minLines:
                    2,
                maxLines:
                    5,
                onChanged:
                    (_) {
                  setState(
                    () {},
                  );
                },
                style:
                    TextStyle(
                  color:
                      _color,
                  fontSize:
                      18,
                  fontFamily:
                      _fontFamily,
                  fontWeight:
                      _bold
                          ? FontWeight.w700
                          : FontWeight.w500,
                ),
                decoration:
                    InputDecoration(
                  hintText:
                      'Write something...',
                  hintStyle:
                      TextStyle(
                    color:
                        Colors.white30,
                    fontFamily:
                        _fontFamily,
                  ),
                  filled:
                      true,
                  fillColor:
                      _surface,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          _purple.withValues(
                        alpha:
                            0.65,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),

              const _SectionLabel(
                text:
                    'Font',
              ),

              const SizedBox(
                height:
                    10,
              ),

              SizedBox(
                height:
                    82,
                child:
                    ListView.separated(
                  scrollDirection:
                      Axis.horizontal,
                  itemCount:
                      _fontOptions.length,
                  separatorBuilder:
                      (
                    context,
                    index,
                  ) =>
                          const SizedBox(
                    width:
                        9,
                  ),
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final option =
                        _fontOptions[index];

                    final selected =
                        option.family ==
                        _fontFamily;

                    return _FontPickerItem(
                      option:
                          option,
                      selected:
                          selected,
                      onTap:
                          () {
                        setState(
                          () {
                            _fontFamily =
                                option.family;
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),

              const _SectionLabel(
                text:
                    'Text Color',
              ),

              const SizedBox(
                height:
                    10,
              ),

              _ColorPicker(
                colors:
                    _colors,
                selectedColor:
                    _color,
                onSelected:
                    (
                  color,
                ) {
                  setState(
                    () {
                      _color =
                          color;
                    },
                  );
                },
              ),

              const SizedBox(
                height:
                    18,
              ),

              _SliderControl(
                label:
                    'Size',
                value:
                    _fontSize,
                min:
                    18,
                max:
                    72,
                displayValue:
                    _fontSize
                        .round()
                        .toString(),
                onChanged:
                    (
                  value,
                ) {
                  setState(
                    () {
                      _fontSize =
                          value;
                    },
                  );
                },
              ),

              const SizedBox(
                height:
                    14,
              ),

              // =============================================================
              // CURVE
              // =============================================================

              Row(
                children: [
                  const _SectionLabel(
                    text:
                        'Curve',
                  ),

                  const Spacer(),

                  if (_curveAmount
                          .abs() >
                      0.01)
                    TextButton(
                      onPressed:
                          () {
                        setState(
                          () {
                            _curveAmount =
                                0;
                          },
                        );
                      },
                      child:
                          const Text(
                        'Reset',
                      ),
                    ),
                ],
              ),

              Slider(
                value:
                    _curveAmount,
                min:
                    -1,
                max:
                    1,
                divisions:
                    40,
                activeColor:
                    _purple,
                inactiveColor:
                    Colors.white12,
                onChanged:
                    (
                  value,
                ) {
                  setState(
                    () {
                      _curveAmount =
                          value;
                    },
                  );
                },
              ),

              const SizedBox(
                height:
                    18,
              ),

              // =============================================================
              // OUTLINE BUBBLES
              // =============================================================

              const _SectionLabel(
                text:
                    'Bubble Outline',
              ),

              const SizedBox(
                height:
                    10,
              ),

              SizedBox(
                height:
                    82,
                child:
                    ListView(
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    _BubblePickerItem(
                      label:
                          'None',
                      icon:
                          Icons.block_rounded,
                      bubble:
                          DoodleTextBubble.none,
                      selected:
                          _bubble ==
                          DoodleTextBubble.none,
                      onTap:
                          _setBubble,
                    ),
                    _BubblePickerItem(
                      label:
                          'Pill',
                      icon:
                          Icons.horizontal_rule_rounded,
                      bubble:
                          DoodleTextBubble.pill,
                      selected:
                          _bubble ==
                          DoodleTextBubble.pill,
                      onTap:
                          _setBubble,
                    ),
                    _BubblePickerItem(
                      label:
                          'Speech',
                      icon:
                          Icons.chat_bubble_outline_rounded,
                      bubble:
                          DoodleTextBubble.speech,
                      selected:
                          _bubble ==
                          DoodleTextBubble.speech,
                      onTap:
                          _setBubble,
                    ),
                    _BubblePickerItem(
                      label:
                          'Cloud',
                      icon:
                          Icons.cloud_outlined,
                      bubble:
                          DoodleTextBubble.cloud,
                      selected:
                          _bubble ==
                          DoodleTextBubble.cloud,
                      onTap:
                          _setBubble,
                    ),
                    _BubblePickerItem(
                      label:
                          'Highlight',
                      icon:
                          Icons.crop_16_9_rounded,
                      bubble:
                          DoodleTextBubble.highlight,
                      selected:
                          _bubble ==
                          DoodleTextBubble.highlight,
                      onTap:
                          _setBubble,
                    ),
                    _BubblePickerItem(
                      label:
                          'Badge',
                      icon:
                          Icons.crop_square_rounded,
                      bubble:
                          DoodleTextBubble.badge,
                      selected:
                          _bubble ==
                          DoodleTextBubble.badge,
                      onTap:
                          _setBubble,
                    ),
                    _BubblePickerItem(
                      label:
                          'Card',
                      icon:
                          Icons.rounded_corner_rounded,
                      bubble:
                          DoodleTextBubble.softCard,
                      selected:
                          _bubble ==
                          DoodleTextBubble.softCard,
                      onTap:
                          _setBubble,
                    ),
                  ],
                ),
              ),

              if (_bubble !=
                  DoodleTextBubble.none) ...[
                const SizedBox(
                  height:
                      16,
                ),

                const _SectionLabel(
                  text:
                      'Outline Color',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _ColorPicker(
                  colors:
                      _bubbleColors,
                  selectedColor:
                      _bubbleColor,
                  onSelected:
                      (
                    color,
                  ) {
                    setState(
                      () {
                        _bubbleColor =
                            color;
                      },
                    );
                  },
                ),

                const SizedBox(
                  height:
                      12,
                ),

                _SliderControl(
                  label:
                      'Opacity',
                  value:
                      _bubbleOpacity,
                  min:
                      0.2,
                  max:
                      1,
                  displayValue:
                      '${(_bubbleOpacity * 100).round()}%',
                  onChanged:
                      (
                    value,
                  ) {
                    setState(
                      () {
                        _bubbleOpacity =
                            value;
                      },
                    );
                  },
                ),
              ],

              const SizedBox(
                height:
                    18,
              ),

              const _SectionLabel(
                text:
                    'Alignment',
              ),

              const SizedBox(
                height:
                    9,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _OptionButton(
                      icon:
                          Icons.format_align_left_rounded,
                      selected:
                          _alignment ==
                          DoodleTextAlign.left,
                      onTap:
                          () {
                        setState(
                          () {
                            _alignment =
                                DoodleTextAlign.left;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  Expanded(
                    child:
                        _OptionButton(
                      icon:
                          Icons.format_align_center_rounded,
                      selected:
                          _alignment ==
                          DoodleTextAlign.center,
                      onTap:
                          () {
                        setState(
                          () {
                            _alignment =
                                DoodleTextAlign.center;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  Expanded(
                    child:
                        _OptionButton(
                      icon:
                          Icons.format_align_right_rounded,
                      selected:
                          _alignment ==
                          DoodleTextAlign.right,
                      onTap:
                          () {
                        setState(
                          () {
                            _alignment =
                                DoodleTextAlign.right;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    16,
              ),

              const _SectionLabel(
                text:
                    'Style',
              ),

              const SizedBox(
                height:
                    9,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _StyleButton(
                      icon:
                          Icons.format_bold_rounded,
                      label:
                          'Bold',
                      selected:
                          _bold,
                      onTap:
                          () {
                        setState(
                          () {
                            _bold =
                                !_bold;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  Expanded(
                    child:
                        _StyleButton(
                      icon:
                          Icons.blur_on_rounded,
                      label:
                          'Shadow',
                      selected:
                          _shadow,
                      onTap:
                          () {
                        setState(
                          () {
                            _shadow =
                                !_shadow;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  Expanded(
                    child:
                        _StyleButton(
                      icon:
                          Icons.border_outer_rounded,
                      label:
                          'Text Outline',
                      selected:
                          _outline,
                      onTap:
                          () {
                        setState(
                          () {
                            _outline =
                                !_outline;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    20,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.icon(
                  onPressed:
                      _controller.text
                              .trim()
                              .isEmpty
                          ? null
                          : _done,
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        _purple,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical:
                          14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  icon:
                      const Icon(
                    Icons.check_rounded,
                  ),
                  label:
                      Text(
                    widget.initialText ==
                            null
                        ? 'Add Text'
                        : 'Apply Changes',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setBubble(
    DoodleTextBubble bubble,
  ) {
    setState(() {
      _bubble =
          bubble;
    });
  }
}

// =============================================================================
// FONT OPTION
// =============================================================================

class _DoodleFontOption {
  const _DoodleFontOption({
    required this.label,
    required this.family,
    required this.preview,
  });

  final String label;
  final String? family;
  final String preview;
}

// =============================================================================
// FONT PICKER
// =============================================================================

class _FontPickerItem extends StatelessWidget {
  const _FontPickerItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _DoodleFontOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          selected
              ? const Color(
                  0xFF8B5CF6,
                ).withValues(
                  alpha:
                      0.17,
                )
              : const Color(
                  0xFF141B2D,
                ),
      borderRadius:
          BorderRadius.circular(
        15,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        child:
            SizedBox(
          width:
              88,
          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                option.preview,
                style:
                    TextStyle(
                  color:
                      selected
                          ? const Color(
                              0xFFC4B5FD,
                            )
                          : Colors.white,
                  fontFamily:
                      option.family,
                  fontSize:
                      27,
                ),
              ),
              const SizedBox(
                height:
                    4,
              ),
              Text(
                option.label,
                style:
                    TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : Colors.white54,
                  fontSize:
                      9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BUBBLE PICKER
// =============================================================================

class _BubblePickerItem extends StatelessWidget {
  const _BubblePickerItem({
    required this.label,
    required this.icon,
    required this.bubble,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DoodleTextBubble bubble;
  final bool selected;
  final ValueChanged<DoodleTextBubble> onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right:
            9,
      ),
      child:
          Material(
        color:
            selected
                ? const Color(
                    0xFF8B5CF6,
                  ).withValues(
                    alpha:
                        0.17,
                  )
                : const Color(
                    0xFF141B2D,
                  ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        child:
            InkWell(
          onTap:
              () {
            onTap(
              bubble,
            );
          },
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          child:
              SizedBox(
            width:
                80,
            child:
                Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      selected
                          ? const Color(
                              0xFFC4B5FD,
                            )
                          : Colors.white54,
                  size:
                      25,
                ),
                const SizedBox(
                  height:
                      6,
                ),
                Text(
                  label,
                  style:
                      TextStyle(
                    color:
                        selected
                            ? Colors.white
                            : Colors.white54,
                    fontSize:
                        9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COLOR PICKER
// =============================================================================

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height:
          38,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            colors.length,
        separatorBuilder:
            (
          context,
          index,
        ) =>
                const SizedBox(
          width:
              9,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final color =
              colors[index];

          final selected =
              color ==
              selectedColor;

          return GestureDetector(
            onTap:
                () {
              onSelected(
                color,
              );
            },
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds:
                    150,
              ),
              width:
                  34,
              height:
                  34,
              decoration:
                  BoxDecoration(
                color:
                    color,
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      selected
                          ? const Color(
                              0xFFC4B5FD,
                            )
                          : Colors.white24,
                  width:
                      selected
                          ? 3
                          : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// PREVIEW
// =============================================================================

class _TextPreview extends StatelessWidget {
  const _TextPreview({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.bold,
    required this.shadow,
    required this.alignment,
    required this.curveAmount,
    required this.bubble,
    required this.bubbleColor,
    required this.bubbleOpacity,
  });

  final String text;
  final Color color;
  final double fontSize;
  final String? fontFamily;
  final bool bold;
  final bool shadow;
  final DoodleTextAlign alignment;
  final double curveAmount;
  final DoodleTextBubble bubble;
  final Color bubbleColor;
  final double bubbleOpacity;

  @override
  Widget build(
    BuildContext context,
  ) {
    final textAlign =
        switch (alignment) {
      DoodleTextAlign.left =>
        TextAlign.left,
      DoodleTextAlign.center =>
        TextAlign.center,
      DoodleTextAlign.right =>
        TextAlign.right,
    };

    Widget textWidget;

    if (curveAmount.abs() <
        0.01) {
      textWidget =
          Text(
        text,
        textAlign:
            textAlign,
        style:
            TextStyle(
          color:
              color,
          fontSize:
              fontSize,
          fontFamily:
              fontFamily,
          fontWeight:
              bold
                  ? FontWeight.w800
                  : FontWeight.w500,
          shadows:
              shadow
                  ? [
                      Shadow(
                        color:
                            Colors.black.withValues(
                          alpha:
                              0.6,
                        ),
                        blurRadius:
                            8,
                      ),
                    ]
                  : null,
        ),
      );
    } else {
      textWidget =
          SizedBox(
        width:
            290,
        height:
            110,
        child:
            CustomPaint(
          painter:
              _PreviewCurvedTextPainter(
            text:
                text,
            color:
                color,
            fontSize:
                fontSize,
            fontFamily:
                fontFamily,
            bold:
                bold,
            curveAmount:
                curveAmount,
          ),
        ),
      );
    }

    return _PreviewOutlineBubble(
      bubble:
          bubble,
      color:
          bubbleColor.withValues(
        alpha:
            bubbleOpacity,
      ),
      child:
          textWidget,
    );
  }
}

// =============================================================================
// PREVIEW OUTLINE BUBBLE
// =============================================================================

class _PreviewOutlineBubble extends StatelessWidget {
  const _PreviewOutlineBubble({
    required this.bubble,
    required this.color,
    required this.child,
  });

  final DoodleTextBubble bubble;
  final Color color;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) {
    const width =
        3.0;

    switch (bubble) {
      case DoodleTextBubble.none:
        return child;

      case DoodleTextBubble.pill:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                18,
            vertical:
                10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              999,
            ),
            border:
                Border.all(
              color:
                  color,
              width:
                  width,
            ),
          ),
          child:
              child,
        );

      case DoodleTextBubble.highlight:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                14,
            vertical:
                7,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              4,
            ),
            border:
                Border.all(
              color:
                  color,
              width:
                  width,
            ),
          ),
          child:
              child,
        );

      case DoodleTextBubble.badge:
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                16,
            vertical:
                10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border:
                Border.all(
              color:
                  color,
              width:
                  width,
            ),
          ),
          child:
              child,
        );

      case DoodleTextBubble.softCard:
        return Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  color,
              width:
                  width,
            ),
          ),
          child:
              child,
        );

      case DoodleTextBubble.speech:
        return CustomPaint(
          painter:
              _PreviewSpeechPainter(
            color:
                color,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              24,
            ),
            child:
                child,
          ),
        );

      case DoodleTextBubble.cloud:
        return CustomPaint(
          painter:
              _PreviewCloudPainter(
            color:
                color,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  24,
              vertical:
                  18,
            ),
            child:
                child,
          ),
        );
    }
  }
}

// =============================================================================
// PREVIEW SPEECH
// =============================================================================

class _PreviewSpeechPainter extends CustomPainter {
  const _PreviewSpeechPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color =
              color
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              3
          ..strokeJoin =
              StrokeJoin.round
          ..strokeCap =
              StrokeCap.round;

    final bodyBottom =
        size.height - 13;

    final path =
        Path()
          ..moveTo(
            20,
            1.5,
          )
          ..lineTo(
            size.width - 20,
            1.5,
          )
          ..quadraticBezierTo(
            size.width - 1.5,
            1.5,
            size.width - 1.5,
            20,
          )
          ..lineTo(
            size.width - 1.5,
            bodyBottom - 18,
          )
          ..quadraticBezierTo(
            size.width - 1.5,
            bodyBottom,
            size.width - 20,
            bodyBottom,
          )
          ..lineTo(
            size.width * 0.44,
            bodyBottom,
          )
          ..lineTo(
            size.width * 0.31,
            size.height - 1.5,
          )
          ..lineTo(
            size.width * 0.33,
            bodyBottom,
          )
          ..lineTo(
            20,
            bodyBottom,
          )
          ..quadraticBezierTo(
            1.5,
            bodyBottom,
            1.5,
            bodyBottom - 18,
          )
          ..lineTo(
            1.5,
            20,
          )
          ..quadraticBezierTo(
            1.5,
            1.5,
            20,
            1.5,
          )
          ..close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PreviewSpeechPainter oldDelegate,
  ) {
    return oldDelegate.color !=
        color;
  }
}

// =============================================================================
// PREVIEW CLOUD
// =============================================================================

class _PreviewCloudPainter extends CustomPainter {
  const _PreviewCloudPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color =
              color
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              3
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

    final w =
        size.width;

    final h =
        size.height;

    final path =
        Path()
          ..moveTo(
            w * 0.16,
            h * 0.76,
          )
          ..cubicTo(
            w * 0.04,
            h * 0.73,
            w * 0.02,
            h * 0.58,
            w * 0.08,
            h * 0.48,
          )
          ..cubicTo(
            w * 0.10,
            h * 0.36,
            w * 0.18,
            h * 0.31,
            w * 0.27,
            h * 0.34,
          )
          ..cubicTo(
            w * 0.27,
            h * 0.17,
            w * 0.40,
            h * 0.08,
            w * 0.51,
            h * 0.20,
          )
          ..cubicTo(
            w * 0.61,
            h * 0.04,
            w * 0.79,
            h * 0.13,
            w * 0.79,
            h * 0.31,
          )
          ..cubicTo(
            w * 0.93,
            h * 0.29,
            w * 0.99,
            h * 0.43,
            w * 0.94,
            h * 0.55,
          )
          ..cubicTo(
            w * 0.98,
            h * 0.69,
            w * 0.86,
            h * 0.80,
            w * 0.75,
            h * 0.77,
          )
          ..cubicTo(
            w * 0.68,
            h * 0.91,
            w * 0.51,
            h * 0.92,
            w * 0.43,
            h * 0.80,
          )
          ..cubicTo(
            w * 0.34,
            h * 0.88,
            w * 0.21,
            h * 0.86,
            w * 0.16,
            h * 0.76,
          )
          ..close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PreviewCloudPainter oldDelegate,
  ) {
    return oldDelegate.color !=
        color;
  }
}

// =============================================================================
// CURVED PREVIEW
// =============================================================================

class _PreviewCurvedTextPainter extends CustomPainter {
  const _PreviewCurvedTextPainter({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.bold,
    required this.curveAmount,
  });

  final String text;
  final Color color;
  final double fontSize;
  final String? fontFamily;
  final bool bold;
  final double curveAmount;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final clean =
        text.replaceAll(
      '\n',
      ' ',
    );

    final characters =
        clean.characters.toList();

    if (characters.isEmpty) {
      return;
    }

    final style =
        TextStyle(
      color:
          color,
      fontSize:
          fontSize,
      fontFamily:
          fontFamily,
      fontWeight:
          bold
              ? FontWeight.w800
              : FontWeight.w500,
    );

    final painters =
        <TextPainter>[];

    var width =
        0.0;

    for (final char
        in characters) {
      final painter =
          TextPainter(
        text:
            TextSpan(
          text:
              char,
          style:
              style,
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painters.add(
        painter,
      );

      width +=
          painter.width + 1;
    }

    final scale =
        width >
                size.width -
                    12
            ? (
                    size.width -
                        12) /
                width
            : 1.0;

    final effectiveWidth =
        width * scale;

    var x =
        (
                size.width -
                    effectiveWidth) /
            2;

    final center =
        size.width / 2;

    final bend =
        curveAmount * 40;

    for (final painter
        in painters) {
      final charWidth =
          painter.width * scale;

      final charCenter =
          x +
          charWidth / 2;

      final normalized =
          (
                  charCenter -
                      center) /
              math.max(
                effectiveWidth / 2,
                1,
              );

      final yOffset =
          bend *
          normalized *
          normalized;

      final slope =
          -2 *
          bend *
          normalized /
          math.max(
            effectiveWidth / 2,
            1,
          );

      canvas.save();

      canvas.translate(
        charCenter,
        size.height / 2 -
            yOffset,
      );

      canvas.rotate(
        math.atan(
          slope,
        ),
      );

      canvas.scale(
        scale,
      );

      painter.paint(
        canvas,
        Offset(
          -painter.width / 2,
          -painter.height / 2,
        ),
      );

      canvas.restore();

      x +=
          charWidth + 1;
    }
  }

  @override
  bool shouldRepaint(
    covariant _PreviewCurvedTextPainter oldDelegate,
  ) {
    return true;
  }
}

// =============================================================================
// SLIDER
// =============================================================================

class _SliderControl extends StatelessWidget {
  const _SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        _SectionLabel(
          text:
              label,
        ),
        Expanded(
          child:
              Slider(
            value:
                value,
            min:
                min,
            max:
                max,
            activeColor:
                const Color(
              0xFF8B5CF6,
            ),
            inactiveColor:
                Colors.white12,
            onChanged:
                onChanged,
          ),
        ),
        SizedBox(
          width:
              46,
          child:
              Text(
            displayValue,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white60,
              fontSize:
                  10,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        color:
            Colors.white70,
        fontSize:
            11,
        fontWeight:
            FontWeight.w700,
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          selected
              ? const Color(
                  0xFF8B5CF6,
                ).withValues(
                  alpha:
                      0.18,
                )
              : const Color(
                  0xFF141B2D,
                ),
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                11,
          ),
          child:
              Icon(
            icon,
            color:
                selected
                    ? const Color(
                        0xFFC4B5FD,
                      )
                    : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _StyleButton extends StatelessWidget {
  const _StyleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          selected
              ? const Color(
                  0xFF8B5CF6,
                ).withValues(
                  alpha:
                      0.18,
                )
              : const Color(
                  0xFF141B2D,
                ),
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                9,
          ),
          child:
              Column(
            children: [
              Icon(
                icon,
                size:
                    18,
                color:
                    selected
                        ? const Color(
                            0xFFC4B5FD,
                          )
                        : Colors.white54,
              ),
              const SizedBox(
                height:
                    4,
              ),
              Text(
                label,
                style:
                    TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : Colors.white54,
                  fontSize:
                      9,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}