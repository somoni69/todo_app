import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../data/local/database.dart';
import '../locator.dart';

enum TaskFilter { all, active, completed }

class TodoProvider extends ChangeNotifier {
  final AppDatabase _db = getIt<AppDatabase>();

  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = ''; // <-- 1. Новая переменная для поиска

  TaskFilter get filter => _filter;
  bool get isSearching => _searchQuery.isNotEmpty; // Показываем ли мы результаты поиска

  // --- ОБНОВЛЕННЫЙ СТРИМ ---
  Stream<List<Task>> get tasksStream {
    final query = _db.select(_db.tasks);

    // 1. Применяем фильтр по статусу
    switch (_filter) {
      case TaskFilter.all:
        break;
      case TaskFilter.active:
        query.where((tbl) => tbl.isCompleted.not());
        break;
      case TaskFilter.completed:
        query.where((tbl) => tbl.isCompleted);
        break;
    }

    // 2. Применяем поиск (если есть текст)
    if (_searchQuery.isNotEmpty) {
      // like('%текст%') ищет вхождение текста в любом месте
      query.where((tbl) => tbl.title.like('%$_searchQuery%'));
    }

    // Сортировка: сначала новые
    query.orderBy([(t) => drift.OrderingTerm.desc(t.id)]);

    return query.watch();
  }

  // --- ДЕЙСТВИЯ ---

  void setFilter(TaskFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  // Метод для обновления текста поиска
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> addTask(String title) {
    return _db.insertTask(
      TasksCompanion(
        title: drift.Value(title),
        dueDate: drift.Value(DateTime.now()),
      ),
    );
  }

  // Новый метод: Редактирование задачи
  Future<void> updateTaskTitle(Task task, String newTitle) {
    // copyWith создает копию объекта с измененным полем
    return _db.updateTask(task.copyWith(title: newTitle));
  }

  Future<void> toggleTask(Task task) {
    return _db.updateTask(
      task.copyWith(isCompleted: !task.isCompleted),
    );
  }

  Future<void> deleteTask(Task task) {
    return _db.deleteTask(task);
  }
}