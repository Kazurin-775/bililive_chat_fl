import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'global.dart';
import 'messages/multi.dart';

void main() async {
  await Global.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Microsoft YaHei UI',
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
        create: (context) =>
            MultiRoomProvider(Global.i.prefs.getInt('room_id') ?? 0),
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();

  Future<void> _showRoomIdInputDialog(
      BuildContext context, MultiRoomProvider provider) async {
    var inputValue = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set live room ID'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Room ID'),
          onChanged: (value) => inputValue = value,
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () async {
              Navigator.pop(context);
              var roomId = int.parse(inputValue);
              await Global.i.prefs.setInt('room_id', roomId);
              provider.setCurrent(roomId);
            },
          ),
        ],
      ),
    );
  }
}

class _HomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo Home Page'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0, // dummy value to ensure that onSelected() is called
                child: Text('Set room ID'),
              ),
            ],
            onSelected: (value) => widget._showRoomIdInputDialog(
                context, Provider.of(context, listen: false)),
          ),
        ],
      ),
      body: Consumer<MultiRoomProvider>(
        builder: (context, provider, child) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) => provider.messages[index].asWidget(),
          separatorBuilder: (context, index) => const Divider(indent: 2),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // If no room ID is configured, ask for one at startup
    if ((Global.i.prefs.getInt('room_id') ?? 0) == 0) {
      Future.delayed(
        Duration.zero,
        () => widget._showRoomIdInputDialog(
            context, Provider.of(context, listen: false)),
      );
    }
  }
}
