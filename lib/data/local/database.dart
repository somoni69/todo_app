import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Эта строка нужна для кодогенерации.
// Drift создаст файл database.g.dart, где будет вся магия.
part 'database.g.dart';

// 1. Описываем таблицу Tasks (Задачи)
class Tasks extends Table {
  // Автоинкрементный ID (1, 2, 3...)
  IntColumn get id => integer().autoIncrement()();
  
  // Название задачи (от 1 до 50 символов)
  TextColumn get title => text().withLength(min: 1, max: 50)();
  
  // Дата выполнения (может быть null)
  DateTimeColumn get dueDate => dateTime().nullable()();
  
  // Выполнена или нет (по умолчанию false)
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// 2. Описываем саму Базу Данных
@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  // Конструктор, который говорит, где открыть базу
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1; // Версия базы (для миграций в будущем)

  // --- CRUD ОПЕРАЦИИ (Create, Read, Update, Delete) ---

  // Получить все задачи (стрим обновляется сам при изменениях!)
  Stream<List<Task>> watchAllTasks() {
    return select(tasks).watch();
  }

  // Добавить задачу
  Future<int> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  // Обновить задачу
  Future<bool> updateTask(Task task) {
    return update(tasks).replace(task);
  }

  // Удалить задачу
  Future<int> deleteTask(Task task) {
    return delete(tasks).delete(task);
  }
}

// 3. Функция открытия подключения к файлу базы данных
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Находим папку документов приложения
    final dbFolder = await getApplicationDocumentsDirectory();
    // Создаем файл db.sqlite
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}