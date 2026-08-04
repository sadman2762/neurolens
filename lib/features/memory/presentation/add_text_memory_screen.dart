import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';

class AddTextMemoryScreen extends ConsumerStatefulWidget {
  const AddTextMemoryScreen({super.key});

  @override
  ConsumerState<AddTextMemoryScreen> createState() =>
      _AddTextMemoryScreenState();
}

class _AddTextMemoryScreenState extends ConsumerState<AddTextMemoryScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveMemory() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text first.')),
      );
      return;
    }

    final memory = Memory(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      type: 'note',
      title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
      content: text,
      originalPath: null,
      createdAt: DateTime.now(),
    );

    final repository = ref.read(memoryRepositoryProvider);
    await repository.saveMemory(memory);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New text memory'),
        actions: [
          TextButton(onPressed: _saveMemory, child: const Text('Save')),
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
