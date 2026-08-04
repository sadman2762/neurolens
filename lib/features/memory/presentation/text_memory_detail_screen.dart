import 'package:flutter/material.dart';

class TextMemoryDetailScreen extends StatelessWidget {
  const TextMemoryDetailScreen({
    required this.content,
    required this.createdAt,
    super.key,
  });

  final String content;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text memory'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              createdAt.toLocal().toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}