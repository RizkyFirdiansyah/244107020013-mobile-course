import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: note.id == null ? null : () => context.go('/note/${note.id}'),
      leading: Icon(
        note.dirty ? Icons.cloud_upload : Icons.cloud_done,
        color: note.dirty ? Colors.orange : Colors.green,
      ),
      title: Text(note.title),
      subtitle: Text(note.dirty ? 'Menunggu sinkronisasi' : 'Tersinkron'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty)
            const Chip(
              label: Text('Belum tersinkron'),
              avatar: Icon(Icons.sync_problem, size: 16),
            ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Hapus catatan',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
