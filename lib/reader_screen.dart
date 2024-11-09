import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_manager/db_helper.dart';
import 'package:pdf_manager/file_opener.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ReaderScreen extends StatefulWidget {
  final String category;

  const ReaderScreen(this.category, {super.key});

  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<Map<String, dynamic>> files = [];
  List<Map<String, dynamic>> filteredFiles = [];
  final TextEditingController _searchController = TextEditingController();
  Set<int> selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _searchController.addListener(_filterFiles);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFiles);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    final dbHelper = DBHelper();
    final loadedFiles = await dbHelper.getFilesByLabel(widget.category);
    setState(() {
      files = loadedFiles;
      filteredFiles = loadedFiles;
    });
  }

  void _filterFiles() {
    setState(() {
      filteredFiles = files
          .where((file) => p
              .basename(file['filePath'])
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _pickFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      final files = result.files;
      files.forEach((file) async {
        if (file.path != null) {
          final dbHelper = DBHelper();
          await dbHelper.insertFile(widget.category, file.path!);
        }
        _loadFiles();
      });
    }
  }

  void _deleteFile(int id) async {
    final dbHelper = DBHelper();
    await dbHelper.deleteFile(id);
    _loadFiles();
  }

  void _showFileInfo(Map<String, dynamic> file) {
    final fileStat = File(file['filePath']).statSync();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('מידע על קובץ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('שם: ${p.basename(file['filePath'])}'),
              Text('גודל: ${fileStat.size} בייטים'),
              Text('מיקום: ${file['filePath']}'),
              Text('סוג: ${p.extension(file['filePath'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('סגור'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (selectedFiles.contains(id)) {
        selectedFiles.remove(id);
      } else {
        selectedFiles.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedFiles.clear();
    });
  }

  void _selectAll() {
    setState(() {
      selectedFiles = files.map<int>((file) => file['id'] as int).toSet();
    });
  }

  IconData _getIcon(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      case '.mp4':
        return Icons.movie;
      case '.mp3':
        return Icons.music_note;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          if (selectedFiles.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                if (selectedFiles.length == 1) {
                  final file = files
                      .firstWhere((file) => file['id'] == selectedFiles.first);
                  _showFileInfo(file);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                for (final id in selectedFiles) {
                  _deleteFile(id);
                }
                _clearSelection();
              },
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            ),
          ],
        ],
      ),
      body: GestureDetector(
        onTap: () {
          if (selectedFiles.isNotEmpty) {
            _clearSelection();
          }
        },
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'חיפוש',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredFiles.length,
                itemBuilder: (context, index) {
                  final file = filteredFiles[index];
                  final isSelected = selectedFiles.contains(file['id']);
                  return GestureDetector(
                    onTap: () {
                      if (selectedFiles.isNotEmpty) {
                        _toggleSelection(file['id']);
                      }
                    },
                    onLongPress: () => _toggleSelection(file['id']),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[200] : Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getIcon(file['filePath']),
                          color: theme.primaryColor,
                        ),
                        title: Text(p.basename(file['filePath'])),
                        selected: isSelected,
                        onTap: selectedFiles.isNotEmpty
                            ? () => _toggleSelection(file['id'])
                            : () {
                                openFile(file['filePath']);
                              },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.add),
            label: const Text('הוסף תיקייה'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              textStyle: const TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      ),
    );
  }
}
