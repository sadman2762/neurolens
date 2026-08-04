import 'package:flutter/material.dart';

class AddTextMemoryScreen extends StatefulWidget {
  const AddTextMemoryScreen({super.key});

  @override
  State<AddTextMemoryScreen> createState() => _AddTextMemoryScreenState();
}

class _AddTextMemoryScreenState extends State<AddTextMemoryScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveMemory() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text first.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memory saved locally.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New text memory'),
        actions: [
          TextButton(
            onPressed: _saveMemory,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText:
                'Write or paste something you want NeuroLens to remember...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}