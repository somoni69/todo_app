import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/local/database.dart';
import '../providers/todo_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSearchMode = false; // Показываем ли поле поиска

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Универсальный диалог: Если task == null -> Создаем, иначе -> Редактируем
  void _showTaskDialog(BuildContext context, {Task? taskToEdit}) {
    final isEditing = taskToEdit != null;
    
    // Если редактируем, подставляем старый текст
    _textController.text = isEditing ? taskToEdit.title : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Редактировать' : 'Новая задача'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Что нужно сделать?',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                final provider = Provider.of<TodoProvider>(context, listen: false);
                
                if (isEditing) {
                  // Обновляем
                  provider.updateTaskTitle(taskToEdit, _textController.text);
                } else {
                  // Создаем
                  provider.addTask(_textController.text);
                }
                
                _textController.clear();
                Navigator.pop(ctx);
              }
            },
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // Если режим поиска - показываем поле ввода, иначе - заголовок
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  todoProvider.search(value);
                },
              )
            : const Text('Менеджер задач'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearchMode) {
                  // Если закрываем поиск - очищаем всё
                  _isSearchMode = false;
                  _searchController.clear();
                  todoProvider.clearSearch();
                } else {
                  _isSearchMode = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры показываем, только если мы НЕ ищем сейчас
          if (!todoProvider.isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SegmentedButton<TaskFilter>(
                segments: const [
                  ButtonSegment(
                      value: TaskFilter.all,
                      label: Text('Все')),
                  ButtonSegment(
                      value: TaskFilter.active,
                      label: Text('В работе')),
                  ButtonSegment(
                      value: TaskFilter.completed,
                      label: Text('Готово')),
                ],
                selected: {todoProvider.filter},
                onSelectionChanged: (Set<TaskFilter> newSelection) {
                  todoProvider.setFilter(newSelection.first);
                },
              ),
            ),

          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: todoProvider.tasksStream,
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ничего не найдено',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key(task.id.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        todoProvider.deleteTask(task);
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Задача удалена'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          // При долгом нажатии - редактируем
                          onLongPress: () => _showTaskDialog(context, taskToEdit: task),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) {
                              todoProvider.toggleTask(task);
                            },
                          ),
                          trailing: IconButton(
                             icon: const Icon(Icons.edit, color: Colors.grey),
                             onPressed: () => _showTaskDialog(context, taskToEdit: task),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // При добавлении передаем null (создание новой)
        onPressed: () => _showTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}