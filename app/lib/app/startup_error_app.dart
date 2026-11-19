import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 준비(기기 DB 열기 등)에 실패했을 때 보여주는 화면.
/// 첫 화면에서 멈춘 채로 두지 않고, 오류 내용을 복사해 알려줄 수 있게 한다.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = '$error';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('😵', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  '앱을 준비하지 못했어요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('앱을 완전히 닫았다가 다시 열어 주세요. 계속되면 아래 내용을 개발자에게 보내 주세요.'),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) => OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('오류 내용을 복사했어요')),
                      );
                    },
                    child: const Text('오류 내용 복사'),
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
