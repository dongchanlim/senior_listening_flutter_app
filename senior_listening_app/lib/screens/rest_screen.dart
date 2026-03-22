import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RestScreen extends StatefulWidget {
  const RestScreen({super.key});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  final List<String> _messages = const [
    '오늘도 충분히 잘 버티셨습니다.',
    '조금 천천히 가도 괜찮습니다.',
    '말하지 못한 마음도 소중한 마음입니다.',
    '지금 여기까지 온 것만으로도 참 애쓰셨습니다.',
    '오늘 하루를 견뎌낸 당신을 응원합니다.',
    '누군가에게 털어놓지 못한 마음도 쉬어갈 자리가 필요합니다.',
    '당신의 하루는 가볍지 않았을 거예요. 그래서 더 소중합니다.',
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = _messages.first;
  }

  void _pickAnother() {
    final random = Random();
    setState(() {
      _selected = _messages[random.nextInt(_messages.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마음 쉬기'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      _selected,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickAnother,
              icon: const Icon(Icons.refresh_rounded, size: 28),
              label: const Text('다른 위로 받기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
