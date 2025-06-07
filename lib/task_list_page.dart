import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:sample_app/hive_ui.dart';
import 'dart:io';
import 'package:sample_app/task.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late Box<Task> taskBox;
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/'));

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncToServer(Task task) async {
    if (await checkInternetConnection()) {
      final data = {
        'title': task.title,
        'isDone': task.isDone,
      };
      final id = task.key.toString();

      try {
        await dio.put('/tasks/$id', data: data);
      } catch (_) {
        await dio.post('/tasks', data: {'id': id, ...data});
      }
    }
  }

  Future<void> syncAllTasksToServer() async {
    if (await checkInternetConnection()) {
      for (var task in taskBox.values) {
        await syncToServer(task);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All tasks synced to server')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
    }
  }

  Future<void> downloadTasksFromServer() async {
    if (await checkInternetConnection()) {
      try {
        final response = await dio.get('/tasks');
        final List tasks = response.data;

        for (var item in tasks) {
          final task = Task(
            title: item['title'] ?? '',
            isDone: item['isDone'] ?? false,
          );
          final id = int.tryParse(item['id'].toString());

          if (id != null && taskBox.containsKey(id)) {
            await taskBox.put(id, task);
          } else {
            await taskBox.add(task);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloaded tasks from server')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download from server')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
    }
  }

  void addTask(String title) async {
    final task = Task(title: title, isDone: false);
    final key = await taskBox.add(task);
    setState(() {});
    await syncToServer(taskBox.get(key)!);
  }

  void toggleTask(Task task) async {
    task.isDone = !task.isDone;
    await task.save();
    setState(() {});
    await syncToServer(task);
  }

  void editTask(Task task, String newTitle) async {
    task.title = newTitle;
    await task.save();
    setState(() {});
    await syncToServer(task);
  }

  void deleteTask(Task task) async {
    final id = task.key.toString();
    await task.delete();
    if (await checkInternetConnection()) {
      try {
        await dio.delete('/tasks/$id');
      } catch (_) {}
    }
    setState(() {});
  }

  void showTaskDialog({Task? task}) {
    final controller = TextEditingController(text: task?.title ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context);
                if (task == null) {
                  addTask(title);
                } else {
                  editTask(task, title);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = taskBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Offline Task Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Download from Server',
            onPressed: downloadTasksFromServer,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync to Server',
            onPressed: syncAllTasksToServer,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'View Synced Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HivePage()),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: GestureDetector(
                        onTap: () => toggleTask(task),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isDone
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            task.isDone ? Icons.check : Icons.circle_outlined,
                            color: task.isDone ? Colors.white : Colors.grey,
                            size: 28,
                          ),
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone ? Colors.grey : Colors.black87,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            tooltip: 'Edit Task',
                            onPressed: () => showTaskDialog(task: task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            tooltip: 'Delete Task',
                            onPressed: () => deleteTask(task),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskDialog(),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: Colors.blueAccent,
      ),
    );
  }
}
