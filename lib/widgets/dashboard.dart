import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';
import '../messages/multi.dart';
import 'avatar.dart';

class PersonalDashboard extends StatefulWidget {
  final BiliCredential? cred;

  const PersonalDashboard({super.key, this.cred});

  @override
  State<StatefulWidget> createState() => _PersonalDashboardState();
}

class _PersonalDashboardState extends State<PersonalDashboard>
    with SingleTickerProviderStateMixin {
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PersonalInfoAppBar(uid: widget.cred?.uid),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          // Change medal (purple)
          _buildActionButton(
            'Change medal',
            Icons.assignment_ind,
            Colors.purple.shade600,
            () {},
          ),
          const Divider(height: 1),
          // Battery reward (orange)
          _buildActionButton(
            'Battery reward',
            Icons.battery_charging_full,
            Colors.orange.shade600,
            () async {
              var cred = widget.cred;
              if (cred == null) {
                await _showResultDialog(context, 'Error',
                    'Not signed in yet, cannot get battery rewards');
                return;
              }

              setState(() {
                _locked = true;
              });

              try {
                var result = await getBatteryRewardProgress(Global.i.dio, cred);
                int? numEarned;
                if (result.status == BatteryRewardStatus.rewardAvailable &&
                    !result.outOfStock) {
                  numEarned = await receiveBatteryReward(Global.i.dio, cred);
                }

                if (!mounted) {
                  Global.i.logger
                      .w('Drawer is closed, cannot show AlertDialog');
                  return;
                }
                await _showResultDialog(
                  context,
                  'Status',
                  '${result.outOfStock ? 'Battery rewards out of stock :(' : result.status.toStatusText()}\n'
                      '${numEarned != null ? 'You earned $numEarned battery today.\n' : ''}\n'
                      'Progress: ${result.progress} / ${result.target}',
                );
              } on BiliApiException catch (e) {
                await _showResultDialog(context, 'Error',
                    'Failed to check for battery rewards: $e');
              } catch (e) {
                Global.i.logger.e(e);
                await _showResultDialog(context, 'Error',
                    'Failed to check for battery rewards: unknown error');
              } finally {
                setState(() {
                  _locked = false;
                });
              }
            },
          ),
          const Divider(height: 1),
          // Daily check in (blue)
          _buildActionButton(
            'Daily check in',
            Icons.event_available,
            Colors.blue.shade600,
            () async {
              var cred = widget.cred;
              if (cred == null) {
                await _showResultDialog(
                    context, 'Error', 'Not signed in yet, cannot check in');
                return;
              }

              setState(() {
                _locked = true;
              });

              try {
                var result = await dailyCheckIn(Global.i.dio, cred);

                if (!mounted) {
                  Global.i.logger
                      .w('Drawer is closed, cannot show AlertDialog');
                  return;
                }
                await _showResultDialog(
                  context,
                  'Result',
                  'Check in successful!\nYou earned: ${result.earned}\n'
                      '${result.bonusDay ? 'You earned special bonus today!\n' : ''}'
                      'Tip: ${result.tips}\n\n'
                      'Note: you\'ve checked in ${result.consecutiveCheckIns} '
                      'day(s) in a row. Keep going.',
                );
              } on BiliApiException catch (e) {
                await _showResultDialog(
                    context, 'Error', 'Failed to perform check in: $e');
              } catch (e) {
                Global.i.logger.e(e);
                await _showResultDialog(context, 'Error',
                    'Failed to perform check in: unknown error');
              } finally {
                setState(() {
                  _locked = false;
                });
              }
            },
          ),
          const Divider(height: 1),
          // Current video (pink)
          _buildActionButton(
            'Current video',
            Icons.ondemand_video,
            Colors.pink.shade600,
            () async {
              setState(() {
                _locked = true;
              });

              try {
                var result = await getCurrentVideo(
                  Global.i.dio,
                  Provider.of<MultiRoomProvider>(context, listen: false)
                      .current,
                );

                if (!mounted) {
                  Global.i.logger
                      .w('Drawer is closed, cannot show AlertDialog');
                  return;
                }
                if (result != null) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Result'),
                      content: SelectableText.rich(TextSpan(
                        text:
                            'Now playing: "${result.title}"\n(Current position at '
                            '${result.getCurrentTimeAsString()}; av${result.avid})\n\n',
                        children: [
                          TextSpan(
                            text: result.url,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(Uri.parse(result.url),
                                  mode: LaunchMode.externalApplication),
                          ),
                          TextSpan(
                            text: '\n\nNote: this is video '
                                '#${result.positionInSequence} in the replay sequence',
                          ),
                        ],
                      )),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  await _showResultDialog(
                    context,
                    'Result',
                    'Currently, no video is playing in this room.\nEither a '
                        'live streaming is ongoing, or the live host did not '
                        'enable video playback.',
                  );
                }
              } catch (e) {
                Global.i.logger.e(e);
                await _showResultDialog(
                    context, 'Error', 'Failed to get current video');
              } finally {
                setState(() {
                  _locked = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  InkWell _buildActionButton(
    String text,
    IconData icon,
    Color color,
    void Function()? onPressed,
  ) {
    const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    var realColor = _locked ? Colors.grey : color;

    return InkWell(
      onTap: (_locked || widget.cred == null) ? null : onPressed,
      child: Padding(
        padding: buttonPadding,
        child: Row(children: [
          Icon(icon, size: 20, color: realColor),
          const SizedBox(width: 6),
          Text(
            _locked ? 'Working... Do not close' : text,
            style: TextStyle(color: realColor),
          ),
        ]),
      ),
    );
  }

  Future<void> _showResultDialog(
      BuildContext context, String title, String message) async {
    if (!mounted) {
      Global.i.logger.w('Drawer is closed, cannot show AlertDialog');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class PersonalInfoAppBar extends StatelessWidget {
  final int? uid;

  const PersonalInfoAppBar({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    var uid_ = uid;
    if (uid_ == null) {
      return AppBar(
        title: Row(
          children: const [
            // TODO: somehow reuse AvatarWidget here?
            CircleAvatar(
              radius: 16,
              // Prevent a strange "border" from appearing around the image
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/noface.gif'),
            ),
            SizedBox(width: 12),
            Text('Not logged in'),
          ],
        ),
      );
    }

    var future = getUserInfo(
      Global.i.dio,
      uid_,
      options: buildCacheOptions(const Duration(days: 3)),
    );
    return AppBar(
      title: Row(
        children: [
          // Avatar
          // TODO: feed UserInfo to AvatarWidget
          AvatarWidget(uid: uid_),
          const SizedBox(width: 12),
          // Nickname
          FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              var data = snapshot.data;
              if (data != null) return _buildNicknameText(data.nickname);

              if (snapshot.hasError) {
                Global.i.logger.e(snapshot.error);
                return _buildNicknameText('Error loading nickname :(');
              }

              return _buildNicknameText('Loading...');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameText(String text) =>
      Text(text, overflow: TextOverflow.ellipsis);
}

extension BatteryRewardStatusDisplay on BatteryRewardStatus {
  String toStatusText() {
    switch (this) {
      case BatteryRewardStatus.notStarted:
        return 'Send messages to get daily battery rewards!';
      case BatteryRewardStatus.inProgress:
        return 'Rewards in progress, please continue sending more messages.';
      case BatteryRewardStatus.rewardAvailable:
        return 'Congratulations, daily battery rewards awarded!';
      case BatteryRewardStatus.awarded:
        return 'Battery rewards already awarded';
      case BatteryRewardStatus.unknown:
        return 'Battery rewards status unknown :(';
    }
  }
}
