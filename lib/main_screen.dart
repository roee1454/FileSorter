import 'package:flutter/material.dart';
import 'package:pdf_manager/db_helper.dart';
import 'package:pdf_manager/reader_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _categoryController = TextEditingController();
  List<String> categories = [];
  Set<String> selectedCategories = {};
  bool isSelecting = false;
  bool isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final dbHelper = DBHelper();
    final loadedCategories = await dbHelper.getCategories();
    setState(() {
      categories = loadedCategories;
    });
  }

  void _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty) {
      final dbHelper = DBHelper();
      await dbHelper.insertCategory(categoryName);
      _categoryController.clear();
      _loadCategories();
    }
  }

  void _editCategory(String oldName) {
    setState(() {
      _categoryController.text = oldName;
    });
    _showAddCategoryDialog(oldName: oldName);
  }

  void _updateCategory(String oldName) async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty) {
      final dbHelper = DBHelper();
      await dbHelper.updateCategory(oldName, categoryName);
      _categoryController.clear();
      _loadCategories();
    }
  }

  void _deleteSelectedCategories() async {
    final dbHelper = DBHelper();
    for (final category in selectedCategories) {
      await dbHelper.deleteCategory(category);
    }
    setState(() {
      selectedCategories.clear();
      isSelecting = false;
    });
    _loadCategories();
  }

  void _toggleSelection(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
      isSelecting = selectedCategories.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      selectedCategories = categories.toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      selectedCategories.clear();
      isSelecting = false;
    });
  }

  void _showAddCategoryDialog({String? oldName}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(oldName != null ? 'ערוך קטגוריה' : 'הוסף קטגוריה'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'שם הקטגוריה'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _categoryController.clear();
              },
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (oldName != null) {
                  _updateCategory(oldName);
                } else {
                  _addCategory();
                }
                Navigator.pop(context);
              },
              child: const Text('שמור'),
            ),
          ],
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final String item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);

    setState(() {});
  }

  void _enterReorderMode() {
    setState(() {
      isSelecting = false;
      selectedCategories.clear();
      isReordering = true;
    });
  }

  void _exitReorderMode() async {
    setState(() {
      isReordering = false;
    });

    // Save the reordered categories to the database
    final dbHelper = DBHelper();
    await dbHelper.updateCategoryOrder(categories);
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('images/Hatal.png', height: 60.0),
              const SizedBox(height: 16.0),
              const Text(
                'פותח על ידי חט"ל',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text('פותח על ידי רואי חיילי מחט"ל'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('סגור'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isReordering ? Colors.purple : null,
        title: Row(
          children: [
            Image.asset(
              'images/Yahalom.png',
              height: 30.0,
            ),
            const SizedBox(width: 8.0),
            const Text(
              'המאגר',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8.0),
            Image.asset(
              'images/Hatal.png',
              height: 30.0,
            ),
          ],
        ),
        actions: [
          if (isSelecting) ...[
            if (selectedCategories.length == 1)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  if (selectedCategories.length == 1) {
                    _editCategory(selectedCategories.first);
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedCategories,
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
          if (!isSelecting && !isReordering) ...[
            IconButton(
              icon: const Icon(Icons.reorder),
              onPressed: _enterReorderMode,
            ),
          ],
          if (isReordering) ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _exitReorderMode,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          if (isSelecting) {
            _clearSelection();
          }
        },
        child: Column(
          children: [
            if (isReordering)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.purple.withOpacity(0.2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_vert, color: Colors.purple),
                    SizedBox(width: 8.0),
                    Text(
                      'מצב גרירה: ללחוץ ארוך על קטגוריה ולגרור',
                      style: TextStyle(color: Colors.purple, fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isReordering
                  ? ReorderableListView(
                      onReorder: _onReorder,
                      children: [
                        for (final category in categories)
                          Container(
                            key: ValueKey(category),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(fontSize: 18.0),
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected =
                            selectedCategories.contains(category);
                        return GestureDetector(
                          onTap: () {
                            if (isSelecting) {
                              _toggleSelection(category);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ReaderScreen(category),
                                ),
                              );
                            }
                          },
                          onLongPress: () => _toggleSelection(category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.grey[200] : Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(fontSize: 18.0),
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
            onPressed: () => _showAddCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('הוסף קטגוריה'),
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
