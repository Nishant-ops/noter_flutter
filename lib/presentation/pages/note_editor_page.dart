import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../domain/models/note.dart';
import '../../data/remote/note_remote_data_source.dart';
import '../../data/services/auth_service.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  final Function(Note)? onSave;
  final Function()? onDelete;

  const NoteEditorPage({
    super.key,
    this.note,
    this.onSave,
    this.onDelete,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late QuillController _controller;
  late final NoteRemoteDataSource _dataSource;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dataSource = NoteRemoteDataSource(AuthService());
    _controller = QuillController.basic();
    if (widget.note != null) {
      _controller.document.insert(0, widget.note!.rawText);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedText = _controller.document.toPlainText();
      if (widget.note != null) {
        await _dataSource.updateNote(widget.note!.id, updatedText);
        if (mounted && widget.onSave != null) {
          widget.onSave!(widget.note!.copyWith(rawText: updatedText));
        }
      } else {
        // Assume createNote returns a Note object or ID if needed, for now just call
        await _dataSource.createNote(updatedText);
        if (mounted && widget.onSave != null) {
          // For a new note, we might not have a Note object with ID from createNote.
          // You might need to update createNote to return the full Note object.
          // For simplicity, we'll just trigger a general refresh in NotesPage for now.
          widget.onSave!(Note(id: DateTime.now().millisecondsSinceEpoch.toString(), rawText: updatedText));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Note saved successfully'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true); // Pop with true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to save note: $e'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return; // Cannot delete a non-existent note
    setState(() {
      _isSaving = true; // Use _isSaving to indicate ongoing operation
    });
    try {
      await _dataSource.deleteNote(widget.note!.id);
      if (mounted && widget.onDelete != null) {
        widget.onDelete!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Note deleted successfully'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true); // Pop with true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to delete note: $e'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildFormatButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (widget.note != null) // Only show delete for existing notes
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteNote,
            ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFormatButton(
                    icon: Icons.format_bold,
                    onPressed: () => _controller.formatSelection(Attribute.bold),
                  ),
                  _buildFormatButton(
                    icon: Icons.format_italic,
                    onPressed: () => _controller.formatSelection(Attribute.italic),
                  ),
                  _buildFormatButton(
                    icon: Icons.format_underline,
                    onPressed: () => _controller.formatSelection(Attribute.underline),
                  ),
                  const SizedBox(width: 8),
                  _buildFormatButton(
                    icon: Icons.format_list_bulleted,
                    onPressed: () => _controller.formatSelection(Attribute.ul),
                  ),
                  _buildFormatButton(
                    icon: Icons.format_list_numbered,
                    onPressed: () => _controller.formatSelection(Attribute.ol),
                  ),
                  const SizedBox(width: 8),
                  _buildFormatButton(
                    icon: Icons.format_align_left,
                    onPressed: () => _controller.formatSelection(Attribute.leftAlignment),
                  ),
                  _buildFormatButton(
                    icon: Icons.format_align_center,
                    onPressed: () => _controller.formatSelection(Attribute.centerAlignment),
                  ),
                  _buildFormatButton(
                    icon: Icons.format_align_right,
                    onPressed: () => _controller.formatSelection(Attribute.rightAlignment),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QuillEditor.basic(
                  controller: _controller,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 