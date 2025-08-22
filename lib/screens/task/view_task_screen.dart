import 'package:flutter/material.dart';
import 'package:tasknest/models/task_model.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:logger/logger.dart';

class ViewTaskScreen extends StatelessWidget {
  final TaskModel task;
  final Logger _logger = Logger(); // Logger added

  ViewTaskScreen({required this.task, super.key});

  @override
  Widget build(BuildContext context) {
    final fileName = task.fileUrl != null ? path.basename(task.fileUrl!) : null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Task Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description.isNotEmpty
                        ? task.description
                        : 'No description available',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // File Download Section
            if (task.fileUrl != null && task.fileUrl!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file,
                            color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName ?? 'File',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download, size: 20),
                          label: const Text('Download',
                              style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            elevation: 3,
                          ),
                          onPressed: () async {
                            try {
                              final fullFileUrl = getFullImageUrl(task.fileUrl!);
                              _logger.i("🔽 Downloading file from: $fullFileUrl");

                              final response = await http.get(Uri.parse(fullFileUrl));
                              _logger.i("📡 Response status: ${response.statusCode}");

                              if (response.statusCode == 200) {
                                final dir = await getTemporaryDirectory();
                                final filePath =
                                    '${dir.path}/${path.basename(fullFileUrl)}';

                                final file = File(filePath);
                                await file.writeAsBytes(response.bodyBytes);

                                _logger.i("✅ File downloaded to: $filePath");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                      Text('File downloaded to: $filePath')),
                                );
                              } else {
                                _logger.e(
                                    "❌ Failed to download file, status: ${response.statusCode}");
                                throw 'Failed (status: ${response.statusCode})';
                              }
                            } catch (e, s) {
                              _logger.e("❌ Exception during file download", error: e, stackTrace: s);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not download: $e')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String getFullImageUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return '';



  if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
    return photoUrl;
  }

  return 'https://cscollaborators.online$photoUrl';
}
