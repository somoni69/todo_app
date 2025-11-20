import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/local/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Задачи могут быть созданы и прочитаны', () async {
    final taskTitle = 'Test Task';
    final companion = TasksCompanion(
      title: Value(taskTitle),
      dueDate: Value(DateTime.now()),
    );

    final id = await database.insertTask(companion);

    final allTasks = await database.select(database.tasks).get();

    expect(allTasks.length, 1);
    expect(allTasks.first.id, id);
    expect(allTasks.first.title, taskTitle);
    expect(allTasks.first.isCompleted, false);
  });

  test('Задачу можно удалить', () async {
    await database.insertTask(const TasksCompanion(title: Value('To delete')));

    var tasks = await database.select(database.tasks).get();
    expect(tasks.length, 1);
    final taskToDelete = tasks.first;

    await database.deleteTask(taskToDelete);

    tasks = await database.select(database.tasks).get();
    expect(tasks.isEmpty, true);
  });
}
