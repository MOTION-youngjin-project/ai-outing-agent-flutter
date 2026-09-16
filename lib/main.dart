import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _homeUrl = 'https://wa26bteam02.yjjob.kr';

// C:\Users\YJ\Desktop\MOTION_하단네비_아이콘4개\*.html(디자인팀 아이콘 스펙)에서 그대로 가져온 값.
const _navDefaultColor = Color(0xFF7E8899);
const _navSelectedColor = Color(0xFF11B5A8);
const _navPillColor = Color(0xFFE4F8F3);
const _navSparkColor = Color(0xFFFFD178);
const _navHairlineColor = Color(0xFFE8ECEF);

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

enum _NavShape { chat, map, saved, mypage }

class _Tab {
  const _Tab(this.key, this.label, this.shape);

  final String key;
  final String label;
  final _NavShape shape;
}

const _tabs = [
  _Tab('chat', '챗', _NavShape.chat),
  _Tab('map', '지도', _NavShape.map),
  _Tab('saved', '저장', _NavShape.saved),
  _Tab('mypage', '마이', _NavShape.mypage),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final WebViewController _controller;
  int _currentIndex = 0;
  // 챗 탭이 아닐 때 새 답변이 도착하면(웹의 NativeChatBridge.postMessage 신호) true —
  // 챗 탭으로 돌아오면 다시 false.
  bool _chatUnread = false;
  // 웹뷰가 서버에 도달 못 하면(오프라인 등) 흰 화면 대신 네이티브 안내를 덮어씀.
  // 이 앱의 모든 탭(챗/지도/저장/마이)이 백엔드 필수라 오프라인에서 의미 있게
  // 대체 표시할 콘텐츠가 없으므로, 네이티브로 만들 가치가 있는 건 이 폴백 화면뿐.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'NativeChatBridge',
        onMessageReceived: (message) {
          if (_currentIndex != 0) {
            setState(() => _chatUnread = true);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loadFailed = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() => _loadFailed = true);
            }
          },
        ),
      );
    _controller.getUserAgent().then((ua) {
      _controller
        ..setUserAgent('$ua NadeulPlanApp/1.0')
        ..loadRequest(Uri.parse(_homeUrl));
    });
  }

  void _retry() {
    setState(() => _loadFailed = false);
    _controller.loadRequest(Uri.parse(_homeUrl));
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) _chatUnread = false;
    });
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
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loadFailed) _OfflineFallback(onRetry: _retry),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _navHairlineColor)),
          ),
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavButton(
                    tab: _tabs[i],
                    selected: _currentIndex == i,
                    showBadge: i == 0 && _chatUnread,
                    onTap: () => _onTabTapped(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineFallback extends StatelessWidget {
  const _OfflineFallback({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: _navDefaultColor),
          const SizedBox(height: 16),
          const Text(
            '인터넷 연결을 확인해주세요',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: _navSelectedColor),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.tab,
    required this.selected,
    required this.showBadge,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.selected ? 1 : 0,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 160),
  );
  // ponytail: 원본 디자인엔 아이콘마다 고유한 회전/이동 키프레임(말풍선 팝, 핀 바운스 등)이
  // 있지만, easeOutBack 스케일 하나로 "통통 튀는" 느낌만 통일해서 재현함 — 4종 키프레임을
  // 전부 손으로 옮기는 건 이 화면 규모 대비 과함. 세밀한 모션이 필요해지면 그때 개별 추가.
  late final Animation<double> _bounce = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
    reverseCurve: const Interval(0, 1, curve: Curves.easeIn),
  );

  @override
  void didUpdateWidget(covariant _NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward(from: 0);
    } else if (!widget.selected && oldWidget.selected) {
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final color = Color.lerp(_navDefaultColor, _navSelectedColor, t)!;
          return SizedBox(
            height: 58,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  child: Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: 0.75 + 0.25 * _fade.value,
                      child: Container(
                        width: 44,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _navPillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    Transform.scale(
                      scale: 0.85 + 0.15 * _bounce.value,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CustomPaint(
                          painter: _NavIconPainter(
                            shape: widget.tab.shape,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tab.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.lerp(
                          FontWeight.w500,
                          FontWeight.w700,
                          t,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 2,
                  right: 18,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.showBadge ? 1 : 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _navSparkColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Opacity(
                    opacity: _fade.value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// C:\Users\YJ\Desktop\MOTION_하단네비_아이콘4개\*.html의 <svg viewBox="0 0 32 32"> path를
// 그대로 옮긴 것(테두리색은 currentColor→color, 흰 디테일은 white 그대로).
class _NavIconPainter extends CustomPainter {
  const _NavIconPainter({required this.shape, required this.color});

  final _NavShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final fill = Paint()..color = color;
    final white = Paint()..color = Colors.white;
    switch (shape) {
      case _NavShape.chat:
        canvas.drawPath(_chatOutline, fill);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(16, 14), width: 10, height: 12),
          white,
        );
        canvas.drawPath(_chatTail, white);
      case _NavShape.map:
        canvas.drawPath(_mapOutline, fill);
        canvas.drawCircle(const Offset(16, 13), 4.5, white);
      case _NavShape.saved:
        canvas.drawPath(_savedOutline, fill);
        canvas.drawPath(
          _savedCheck,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case _NavShape.mypage:
        canvas.drawCircle(const Offset(16, 16), 14, fill);
        canvas.drawCircle(const Offset(16, 11), 4, white);
        canvas.drawPath(_mypageBody, white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shape != shape;
}

final Path _chatOutline = Path()
  ..moveTo(10, 3)
  ..lineTo(22, 3)
  ..arcToPoint(const Offset(29, 10), radius: const Radius.circular(7), clockwise: true)
  ..lineTo(29, 21)
  ..arcToPoint(const Offset(23, 27), radius: const Radius.circular(6), clockwise: true)
  ..lineTo(21, 27)
  ..lineTo(16, 31)
  ..lineTo(16, 27)
  ..lineTo(10, 27)
  ..arcToPoint(const Offset(3, 20), radius: const Radius.circular(7), clockwise: true)
  ..lineTo(3, 10)
  ..arcToPoint(const Offset(10, 3), radius: const Radius.circular(7), clockwise: true)
  ..close();

final Path _chatTail = Path()
  ..moveTo(17, 18)
  ..lineTo(21, 23)
  ..lineTo(21, 15)
  ..close();

final Path _mapOutline = Path()
  ..moveTo(16, 2)
  ..cubicTo(8, 2, 3, 7, 3, 14)
  ..cubicTo(3, 22, 13, 30, 16, 32)
  ..cubicTo(19, 30, 29, 22, 29, 14)
  ..cubicTo(29, 7, 24, 2, 16, 2)
  ..close();

final Path _savedOutline = Path()
  ..moveTo(16, 2)
  ..lineTo(26, 6)
  ..arcToPoint(const Offset(28, 10), radius: const Radius.circular(4), clockwise: true)
  ..lineTo(28, 22)
  ..lineTo(16, 31)
  ..lineTo(4, 22)
  ..lineTo(4, 10)
  ..arcToPoint(const Offset(6, 6), radius: const Radius.circular(4), clockwise: true)
  ..close();

final Path _savedCheck = Path()
  ..moveTo(10, 15)
  ..lineTo(14, 19)
  ..lineTo(22, 10);

final Path _mypageBody = Path()
  ..moveTo(9, 25)
  ..lineTo(9, 22)
  ..arcToPoint(const Offset(23, 22), radius: const Radius.circular(7), clockwise: true)
  ..lineTo(23, 25)
  ..arcToPoint(const Offset(9, 25), radius: const Radius.circular(14), clockwise: true)
  ..close();
