import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_1/painter.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TestBody());
  }
}

class TestBody extends StatefulWidget {
  const TestBody({super.key});

  @override
  State<TestBody> createState() => _TestBodyState();
}

class _TestBodyState extends State<TestBody> {
  final key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              final render = key.currentContext?.findRenderObject();
              if (render == null) {
                print('render is null');
                return;
              }
              if (render is! RenderParagraph) {
                print('render is not RenderParagraph');
                return;
              }
              print(render.getMaxIntrinsicWidth(100));

              final textStyle = DefaultTextStyle.of(context).style;
              final a = TextLayoutInfo(
                text: 'Hello World!',
                style: textStyle.copyWith(fontSize: 20),
                maxWidth: 80,
              );

              final b = a.findAllMatches('o');
              print(a.lineCount);
              print(b.join('\n'));
            },
            child: const Icon(Icons.add),
          );
        },
      ),
      body: Center(
        child: SizedBox(
          width: 80,
          child: RichText(
            key: key,
            text: TextSpan(
              text: 'Hello World!',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
