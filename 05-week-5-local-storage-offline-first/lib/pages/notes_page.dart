import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

final dirtyNotesCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
);

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah catatan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Judul'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    await ref.read(noteRepositoryProvider).addNote(title: title.trim());
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyNotesCountProvider);
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final synced = await syncNotes(ref.read(noteRepositoryProvider));
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyNotesCountProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced == 0
                ? 'Tidak ada catatan dirty.'
                : '$synced catatan berhasil disinkronkan.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteNote(BuildContext context, WidgetRef ref, Note note) async {
    if (note.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('Catatan "${note.title}" akan dihapus dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(noteRepositoryProvider).deleteNote(note.id!);
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyNotesCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyNotesCountProvider).value ?? 0;
    return Scaffold(
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Gagal membaca catatan: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada catatan.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final note = items[index];
                  return NoteTile(
                    note: note,
                    onDelete: () => _deleteNote(context, ref, note),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        tooltip: 'Tambah catatan',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Badge(
          isLabelVisible: dirtyCount > 0,
          label: Text('$dirtyCount'),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _sync(context, ref),
              icon: const Icon(Icons.sync),
              label: const Text('Sinkronkan catatan'),
            ),
          ),
        ),
      ),
    );
  }
}
