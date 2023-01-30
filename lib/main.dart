import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'creds.dart';
import 'global.dart';
import 'messages/multi.dart';
import 'messages/provider.dart';
import 'platform_shim.dart' show getPlatformDefaultFont;
import 'widgets/input.dart';

void main() async {
  await Global.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              MultiRoomProvider(Global.i.prefs.getInt('room_id') ?? 0),
        ),
        ChangeNotifierProvider(create: (context) => BiliCredsProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          fontFamily: getPlatformDefaultFont(),
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ScrollController _scrollController = ScrollController();

  MyHomePage({super.key});

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
  bool _scrollLock = false;

  @override
  Widget build(BuildContext context) {
    var dividerThickness = DividerTheme.of(context).thickness ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo Home Page'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text('Set room ID'),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text('Set cookie JSON'),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    // Set onChanged = null to make the checkbox not clickable
                    Consumer<BiliCredsProvider>(
                      builder: (context, provider, child) => Checkbox(
                          value: provider.simulateSend, onChanged: null),
                    ),
                    const Text('[Debug] Simulate send'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 0:
                  widget._showRoomIdInputDialog(
                      context, Provider.of(context, listen: false));
                  break;
                case 1:
                  Provider.of<BiliCredsProvider>(context, listen: false)
                      .showEditDialog(context);
                  break;
                case 2:
                  Provider.of<BiliCredsProvider>(context, listen: false)
                      .toggleSimulateSend();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MultiRoomProvider>(
              builder: (context, provider, child) {
                // Scroll to bottom at the end of this frame
                if (!_scrollLock) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    widget._scrollController.animateTo(
                      widget._scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  });
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter >= 200) {
                      _scrollLock = true;
                    } else if (notification.metrics.extentAfter <= 10) {
                      _scrollLock = false;
                    }
                    return false;
                  },
                  child: ListView.separated(
                    controller: widget._scrollController,
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) =>
                        provider.messages[index].asWidget(),
                    separatorBuilder: (context, index) => Divider(
                      // Set vertical padding to 0 (i.e. let height == thickness),
                      // so that the InkWell's tap ripple effect could fill up the
                      // whole white space of the list item
                      height: dividerThickness,
                      indent: 2,
                      endIndent: 2,
                    ),
                  ),
                );
              },
            ),
          ),
          const MessageInputWidget(),
        ],
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

    // Listen to global events
    var eventBus = Global.i.eventBus;
    eventBus.on<RoomConnectionLossEvent>().listen((event) {
      if (event.roomId ==
          Provider.of<MultiRoomProvider>(context, listen: false).current) {
        // Connection to the current room has been lost, show a SnackBar
        // to notify the user
        // TODO: add reconnection strategy
        // TODO: don't let SnackBars cover up the input bar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade800,
          content: const Text('Connection lost! You won\'t be able to receive '
              'new messages.'),
          duration: const Duration(days: 365),
          action: SnackBarAction(
            label: 'Ignore',
            onPressed: () {},
          ),
        ));
      }
    });
  }
}
