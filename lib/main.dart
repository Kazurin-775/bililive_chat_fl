import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
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
        home: const MyHomePage(),
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

class _HomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

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
                child: Text('Reword last message'),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text('Set room ID'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('Set cookie JSON'),
              ),
              PopupMenuItem(
                value: 3,
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
                  Global.i.eventBus.fire(MessageRewordEvent());
                  break;
                case 1:
                  widget._showRoomIdInputDialog(
                      context, Provider.of(context, listen: false));
                  break;
                case 2:
                  Provider.of<BiliCredsProvider>(context, listen: false)
                      .showEditDialog(context);
                  break;
                case 3:
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
                if (_autoScroll) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  });
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is UserScrollNotification &&
                        notification.direction != ScrollDirection.idle) {
                      // Disable auto scroll when user initiates scrolling
                      _autoScroll = false;
                    } else if (notification is ScrollEndNotification) {
                      // Re-enable auto scroll when the list view hits the
                      // bottom edge
                      _autoScroll = notification.metrics.extentAfter < 10;
                    }
                    return false;
                  },
                  child: ListView.separated(
                    controller: _scrollController,
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
    WidgetsBinding.instance.addObserver(this);

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
            label: 'Reconnect',
            onPressed: () {
              Provider.of<MultiRoomProvider>(context, listen: false)
                  .reconnect();
            },
          ),
        ));
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // When the viewport size changes while auto scroll is enabled, jump to the
    // end of list automatically
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _scrollController.dispose();
  }
}
