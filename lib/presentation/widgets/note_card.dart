import 'package:flutter/material.dart';
import '../../domain/models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({Key? key, required this.note, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text(
          'Note ${note.id}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          note.rawText.length > 100 ? note.rawText.substring(0, 100) + '...' : note.rawText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
} 