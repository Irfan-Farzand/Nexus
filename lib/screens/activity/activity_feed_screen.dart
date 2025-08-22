import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/providers/activity_provider.dart';
import 'package:tasknest/models/activity_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityFeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Activity Feed')),
      body: StreamBuilder<List<ActivityModel>>(
        stream: Provider.of<ActivityProvider>(
          context,
        ).streamActivitiesForUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final activities = snapshot.data!;
          if (activities.isEmpty)
            return Center(child: Text('No activity yet.'));
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (ctx, idx) {
              final a = activities[idx];
              return ListTile(
                title: Text(a.description),
                subtitle: Text('${a.action} • ${a.timestamp}'),
              );
            },
          );
        },
      ),
    );
  }
}
