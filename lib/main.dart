import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: const TextSearchDemo(),
    );
  }
}

class TextSearchDemo extends StatefulWidget {
  const TextSearchDemo({super.key});

  @override
  State<TextSearchDemo> createState() => _TextSearchDemoState();
}

class _TextSearchDemoState extends State<TextSearchDemo> {
  final _textKey = GlobalKey();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  // 示例长文本
  final String _content = '''
Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.

Flutter works with existing code, is used by developers and organizations around the world, and is free and open source.

Fast Development:
Paint your app to life in milliseconds with Stateful Hot Reload. Use a rich set of fully-customizable widgets to build native interfaces in minutes.

Expressive and Flexible UI:
Quickly ship features with a focus on native end-user experiences. Layered architecture allows for full customization, which results in incredibly fast rendering and expressive and flexible designs.

Native Performance:
Flutter's widgets incorporate all critical platform differences such as scrolling, navigation, icons and fonts to provide full native performance on both iOS and Android.

Learn more about Flutter at flutter.dev. You can find documentation, tutorials, and more resources to help you get started with Flutter development.

Flutter uses Dart programming language which is also developed by Google. Dart is optimized for building user interfaces with features such as sound null safety and hot reload.

The Flutter framework consists of two main parts: the Flutter engine and the Flutter framework. The engine is written in C++ and provides low-level rendering support using Skia graphics library.

Join the Flutter community today and start building amazing applications!
''';

  List<Rect> _highlightRects = [];
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _highlightRects = [];
        _currentMatchIndex = 0;
        _totalMatches = 0;
      });
      return;
    }

    // 获取 RenderParagraph
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is! RenderParagraph) return;

    final List<Rect> rects = [];
    final lowerContent = _content.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int index = 0;
    while ((index = lowerContent.indexOf(lowerQuery, index)) != -1) {
      // 使用 RenderParagraph.getBoxesForSelection 获取文本位置
      final boxes = renderObject.getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + query.length),
      );

      for (final box in boxes) {
        rects.add(box.toRect());
      }
      index++;
    }

    setState(() {
      _highlightRects = rects;
      _totalMatches = rects.length;
      _currentMatchIndex = rects.isNotEmpty ? 0 : -1;
    });

    if (rects.isNotEmpty) {
      _scrollToMatch(0);
    }
  }

  void _scrollToMatch(int matchIndex) {
    if (_highlightRects.isEmpty || matchIndex < 0) return;

    setState(() {
      _currentMatchIndex = matchIndex;
    });

    final rect = _highlightRects[matchIndex];

    // 获取 RenderParagraph 在 ScrollView 中的位置
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject == null) return;

    final renderBox = renderObject as RenderBox;
    final textOffset = renderBox.localToGlobal(Offset.zero);

    // 计算需要滚动到的位置
    // rect.top 是相对于 RenderParagraph 的，需要加上当前滚动偏移
    final targetOffset =
        _scrollController.offset +
        rect.top +
        textOffset.dy -
        MediaQuery.of(context).size.height / 3;

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMatch() {
    if (_highlightRects.isEmpty) return;
    final next = (_currentMatchIndex + 1) % _highlightRects.length;
    _scrollToMatch(next);
  }

  void _previousMatch() {
    if (_highlightRects.isEmpty) return;
    final prev =
        (_currentMatchIndex - 1 + _highlightRects.length) %
        _highlightRects.length;
    _scrollToMatch(prev);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Search Demo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.none,
                    onSubmitted: (_) => _nextMatch(),
                    decoration: InputDecoration(
                      hintText: '搜索文本...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _search,
                  ),
                ),
                if (_totalMatches > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${_currentMatchIndex + 1}/$_totalMatches',
                    style: const TextStyle(fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: _previousMatch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: _nextMatch,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: CustomPaint(
          foregroundPainter: HighlightPainter(
            rects: _highlightRects,
            currentIndex: _currentMatchIndex,
          ),
          child: RichText(
            key: _textKey,
            text: TextSpan(
              text: _content,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// 高亮绘制器
class HighlightPainter extends CustomPainter {
  final List<Rect> rects;
  final int currentIndex;

  HighlightPainter({required this.rects, required this.currentIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final normalPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final currentPaint = Paint()
      ..color = Colors.orange.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < rects.length; i++) {
      final paint = i == currentIndex ? currentPaint : normalPaint;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i], const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(HighlightPainter oldDelegate) {
    return oldDelegate.rects != rects ||
        oldDelegate.currentIndex != currentIndex;
  }
}
