import 'package:flutter/material.dart';
import 'package:myapp/widgets/menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportListPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 21, 17, 37),
      appBar: AppBar(
        title: const Text(
          'Uploaded Reports',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 21, 17, 37),
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
      ),
      drawer: Drawer(
        child: SideMenuWidget(
          currentIndex: 4,
          onMenuSelect: (index) {
            print('Selected menu index: $index');
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No reports found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final reports = snapshot.data!;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final fileName = report['name'];
              final fileUrl = report['url'];

              return ListTile(
                title: Text(
                  fileName,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _openReport(context, fileUrl);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    try {
      final storage = Supabase.instance.client.storage.from(
        'reports',
      ); // Replace 'reports' with your bucket name.
      final response = await storage.list(path: 'reports');

      return response
          .where(
            (file) => file.name.endsWith('.pdf'),
          ) // Filter files with .pdf extension.
          .map((file) {
            return {
              'name': file.name,
              'url': storage.getPublicUrl(
                'reports/${file.name}',
              ), // Include the folder path in the public URL.
            };
          })
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch PDF reports: $e");
    }
  }

  Future<void> _openReport(BuildContext context, String fileUrl) async {
    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PDF report.')),
      );
    }
  }
}
