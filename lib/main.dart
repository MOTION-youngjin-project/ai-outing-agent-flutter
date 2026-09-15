import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _homeUrl = 'https://wa26bteam02.yjjob.kr';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나들플랜',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const HomeShell(),
    );
  }
}

class _Tab {
  const _Tab(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

const _tabs = [
  _Tab('chat', '챗', Icons.chat_bubble_outline),
  _Tab('map', '지도', Icons.map_outlined),
  _Tab('saved', '저장', Icons.bookmark_border),
  _Tab('mypage', '마이', Icons.person_outline),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final WebViewController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.getUserAgent().then((ua) {
      _controller
        ..setUserAgent('$ua NadeulPlanApp/1.0')
        ..loadRequest(Uri.parse(_homeUrl));
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    final tabKey = _tabs[index].key;
    _controller.runJavaScript(
      "window.dispatchEvent(new CustomEvent('native-tab', { detail: '$tabKey' }))",
    );
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('앱 종료'),
              content: const Text('나들플랜을 종료할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('종료'),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(child: WebViewWidget(controller: _controller)),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            for (final tab in _tabs)
              BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
      ),
    );
  }
}
