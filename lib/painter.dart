import 'package:flutter/material.dart';

/// 字符位置信息
class CharacterPosition {
  /// 字符在文本中的索引
  final int index;

  /// 行号（从 0 开始）
  final int lineNumber;

  /// 字符的精确位置和大小
  final Rect rect;

  const CharacterPosition({
    required this.index,
    required this.lineNumber,
    required this.rect,
  });

  /// 字符左上角坐标
  Offset get offset => rect.topLeft;

  /// 字符大小
  Size get size => rect.size;

  @override
  String toString() =>
      'CharacterPosition(index: $index, line: $lineNumber, offset: $offset, size: $size)';
}

/// 文本布局信息工具类
///
/// 用于分析文本布局并查找特定字符的位置信息
class TextLayoutInfo {
  final TextPainter textPainter;
  final String _text;

  /// 缓存的行度量信息
  late final List<LineMetrics> _lineMetrics;

  /// 每行的 y 坐标边界 [top, bottom]
  late final List<(double top, double bottom)> _lineBounds;

  TextLayoutInfo({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
  }) : _text = text,
       textPainter = TextPainter(
         text: TextSpan(text: text, style: style),
         textDirection: textDirection,
         textAlign: textAlign,
       ) {
    textPainter.layout(maxWidth: maxWidth);
    _initLineMetrics();
  }

  void _initLineMetrics() {
    _lineMetrics = textPainter.computeLineMetrics();
    _lineBounds = [];

    double top = 0;
    for (final line in _lineMetrics) {
      final bottom = top + line.height;
      _lineBounds.add((top, bottom));
      top = bottom;
    }
  }

  /// 文本内容
  String get text => _text;

  /// 总行数
  int get lineCount => _lineMetrics.length;

  /// 每行的详细信息
  List<LineMetrics> get lineMetrics => _lineMetrics;

  /// 文本总高度
  double get height => textPainter.height;

  /// 文本总宽度
  double get width => textPainter.width;

  /// 查找指定模式的所有位置信息
  ///
  /// [pattern] 要查找的字符或字符串
  /// [caseSensitive] 是否区分大小写，默认为 true
  List<CharacterPosition> findAllMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    if (pattern.isEmpty) return const [];

    final searchText = caseSensitive ? _text : _text.toLowerCase();
    final searchPattern = caseSensitive ? pattern : pattern.toLowerCase();
    final results = <CharacterPosition>[];

    int index = 0;
    while ((index = searchText.indexOf(searchPattern, index)) != -1) {
      final position = getCharacterPosition(index, pattern.length);
      if (position != null) {
        results.add(position);
      }
      index++;
    }

    return results;
  }

  /// 获取指定索引处字符的位置信息
  ///
  /// [index] 字符索引
  /// [length] 字符长度，默认为 1
  CharacterPosition? getCharacterPosition(int index, [int length = 1]) {
    if (index < 0 || index >= _text.length) return null;

    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: index, extentOffset: index + length),
    );

    if (boxes.isEmpty) return null;

    final rect = boxes.first.toRect();
    return CharacterPosition(
      index: index,
      lineNumber: _getLineNumber(rect.top),
      rect: rect,
    );
  }

  /// 根据 y 坐标获取行号
  int _getLineNumber(double y) {
    for (int i = 0; i < _lineBounds.length; i++) {
      final (top, bottom) = _lineBounds[i];
      if (y >= top && y < bottom) return i;
    }
    return _lineBounds.isEmpty ? 0 : _lineBounds.length - 1;
  }

  /// 按行分组返回匹配结果
  ///
  /// 返回 Map，key 为行号，value 为该行上所有匹配位置的列表
  Map<int, List<CharacterPosition>> findAllMatchesGroupedByLine(
    String pattern, {
    bool caseSensitive = true,
  }) {
    final positions = findAllMatches(pattern, caseSensitive: caseSensitive);
    final grouped = <int, List<CharacterPosition>>{};

    for (final pos in positions) {
      (grouped[pos.lineNumber] ??= []).add(pos);
    }

    return grouped;
  }

  /// 查找指定行上的所有匹配
  List<CharacterPosition> findMatchesInLine(
    String pattern,
    int lineNumber, {
    bool caseSensitive = true,
  }) {
    return findAllMatches(
      pattern,
      caseSensitive: caseSensitive,
    ).where((p) => p.lineNumber == lineNumber).toList();
  }

  /// 获取指定行的所有字符位置
  List<CharacterPosition> getLineCharacters(int lineNumber) {
    if (lineNumber < 0 || lineNumber >= lineCount) return const [];

    final results = <CharacterPosition>[];
    for (int i = 0; i < _text.length; i++) {
      final pos = getCharacterPosition(i);
      if (pos != null && pos.lineNumber == lineNumber) {
        results.add(pos);
      } else if (pos != null && pos.lineNumber > lineNumber) {
        break; // 已经超过目标行，提前退出
      }
    }
    return results;
  }
}
