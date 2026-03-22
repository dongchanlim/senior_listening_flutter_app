import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';
import '../widgets/large_action_button.dart';

Widget homePreviewWrapper(Widget child) =>
    MaterialApp(theme: AppTheme.build(), home: child);

@Preview(name: '홈 화면', wrapper: homePreviewWrapper)
Widget previewHomeScreen() => const HomeScreen();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                '오늘도 수고하셨습니다',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '천천히, 따뜻하게, 끝까지 들어드릴게요.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              LargeActionButton(
                label: '이야기 시작하기',
                icon: Icons.mic_rounded,
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                backgroundColor: AppTheme.primary,
                height: 88,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: LargeActionButton(
                      label: '내 이야기 보기',
                      icon: Icons.menu_book_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/history'),
                      backgroundColor: AppTheme.secondary,
                      height: 70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LargeActionButton(
                      label: '마음 쉬기',
                      icon: Icons.spa_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/rest'),
                      backgroundColor: AppTheme.primary,
                      height: 70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
