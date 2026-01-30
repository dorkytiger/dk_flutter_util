import 'dart:async';

import 'package:dk_util/dk_util.dart';
import 'package:dk_util/log/dk_log_view.dart';
import 'package:flutter/material.dart';

void main() async {
  if (!await DKLog.hasStoragePermission()) {
    await DKLog.requestStoragePermission();
  }
  await DKLog.initFileLog();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DK Util Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      // home: const MyHomePage(title: 'DK Util Home Page'),
      home: DKLogView(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final getMockDataState = ValueNotifier<DKStateQuery<List<String>>>(
    DkStateQueryIdle(),
  );

  final submitMockDataEvent = StreamController<DKStateEvent<void>>();
  late final StreamSubscription<DKStateEvent<void>> _subscription;

  void _getMockData() async {
    getMockDataState.query(
      query: () async {
        await Future.delayed(const Duration(seconds: 2));
        return ['Item 1', 'Item 2', 'Item 3'];
      },
    );
  }

  void submitMockData() {
    submitMockDataEvent.triggerEvent(() async {
      await Future.delayed(const Duration(seconds: 2));
    });
  }

  @override
  void initState() {
    super.initState();
    _subscription = submitMockDataEvent.listenEvent(
      onLoading: () {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Submitting...')));
        }
      },
      onSuccess: (data, message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Submit Success')));
        }
      },
      onError: (message, error, stackTrace) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Submit Error: $message')));
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    submitMockDataEvent.close();
    getMockDataState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.send), onPressed: submitMockData),
        ],
      ),
      body: getMockDataState.display(
        successBuilder: (data) {
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(data[index]));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getMockData,
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
