import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'package:hkinfo/BusNotifierApp/pickStop.dart';
import 'package:hkinfo/BusNotifierApp/stopClass.dart';
import 'package:hkinfo/BusNotifierApp/ReminderClass.dart';
import 'package:hkinfo/BusNotifierApp/stops.dart' as allStops;
import 'package:http/http.dart' as http;

class BusNotifierPage extends StatefulWidget {
  @override
  _BusNotifierPageState createState() => _BusNotifierPageState();
}

class _BusNotifierPageState extends State<BusNotifierPage> {
  bool loading = true;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<Reminder> reminders = [];

  Future<File> get _remindersFile async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/reminders.json');
    bool fileExists = await file.exists();
    if (!fileExists) {
      await file.create();
      // await file.writeAsString(json.encode({"reminders": []}));
    }
    return file;
  }

  Future<List<Reminder>> readReminders() async {
    final file = await _remindersFile;
    String contents = await file.readAsString();
    if (contents == '') return [];
    return json.decode(contents).map<Reminder>((mapReminder) {
      return Reminder.fromMap(mapReminder);
    }).toList();
  }

  List<Map> remindersToMaps(List<Reminder> reminders) {
    return reminders.map((Reminder listReminder) => listReminder.toMap()).toList();
  }

  Future<void> writeReminder(Reminder reminder) async {
    scheduleNotification(reminder);
    print('Reminder Id ${reminder.notificationId}');
    List<Reminder> reminders = await readReminders();
    reminders.add(reminder);
    reminders.sort((Reminder reminder1, Reminder reminder2) {
      if (reminder1.time == reminder2.time)
        return 0;
      else if (reminder1.time.isAfter(reminder2.time))
        return 1;
      else if (reminder1.time.isBefore(reminder2.time)) return -1;
      return null;
    });
    List<Map> mapReminders = remindersToMaps(reminders);
    final file = await _remindersFile;
    file.writeAsString(json.encode(mapReminders));
  }

  Future<void> deleteReminder(int index) async {
    final file = await _remindersFile;
    reminders = await readReminders();
    try {
      await flutterLocalNotificationsPlugin.cancel(reminders.elementAt(index).notificationId);
    } catch (_) {
      print('No notification scheduled');
    }
    reminders.removeAt(index);
    file.writeAsString(json.encode(remindersToMaps(reminders)));
  }

  void createReminder(BuildContext context) {
    DateTime now = DateTime.now();

    DateTime dayPick = now;
    TimeOfDay timePick = TimeOfDay(hour: 16, minute: 30);
    List<Stop> stops = [];

    String message = '';

    showDialog(
        context: context,
        // can tap outside to dismiss
        barrierDismissible: true,
        builder: (BuildContext context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 2),
              title: Text('Add a reminder'),
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              RaisedButton(
                                elevation: 0,
                                child: Text('Pick Date'),
                                onPressed: () async {
                                  var result = await showDatePicker(
                                      context: context,
                                      initialDate: now,
                                      firstDate: now,
                                      lastDate: now.add(Duration(days: 30 * 6)));
                                  if (result != null) {
                                    setState(() {
                                      dayPick = result;
                                    });
                                  }
                                },
                              ),
                              Text(
                                DateFormat('EEEE dd').format(dayPick),
                                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              RaisedButton(
                                elevation: 0,
                                child: Text('Pick Time'),
                                onPressed: () async {
                                  var result =
                                      await showTimePicker(context: context, initialTime: timePick);
                                  if (result != null) {
                                    setState(() {
                                      timePick = result;
                                    });
                                  }
                                },
                              ),
                              Text('${timePick.hour}:${timePick.minute}',
                                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14))
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      RaisedButton(
                        padding: EdgeInsets.all(0),
                        elevation: 0,
                        onPressed: () async {
                          var result = await showSearch(
                              context: context, delegate: StopsSearch(allStops.stops));
                          if (result != null) {
                            setState(() {
                              stops.add(result);
                              message = '';
                            });
                          }
                        },
                        child: Text('Add stop'),
                      ),
                      (stops.isNotEmpty)
                          ? Center(
                              child: Text(
                                stops
                                    .map(
                                      (Stop stop) =>
                                          stop.route +
                                          ' ' +
                                          ((stop.inbound) ? 'Inbound' : 'Outbound') +
                                          ': ' +
                                          stop.name,
                                    )
                                    .toList()
                                    .join('\n'),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                              ),
                            )
                          : Container(),
                      // (stop != null)
                      //     ? Text(
                      //         stop.route +
                      //             ' ' +
                      //             ((stop.inbound) ? 'Inbound' : 'Outbound') +
                      //             ': ' +
                      //             stop.name,
                      //         overflow: TextOverflow.ellipsis,
                      //         maxLines: 1,
                      //         style: TextStyle(
                      //             fontStyle: FontStyle.italic, fontSize: 14))
                      //     : Text('No stop selected',
                      //         style: TextStyle(
                      //             fontStyle: FontStyle.italic, fontSize: 14)),
                      (message != '')
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(Icons.warning, color: Colors.red),
                                Text(
                                  message,
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Container(),
                      SizedBox(
                        height: 3,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          FlatButton(
                            onPressed: Navigator.of(context).pop,
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          FlatButton(
                            onPressed: () async {
                              DateTime returnDate = DateTime(dayPick.year, dayPick.month,
                                  dayPick.day, timePick.hour, timePick.minute);
                              if (stops == null || stops.length <= 0) {
                                setState(() {
                                  message = 'Select a stop';
                                });
                              } else if (returnDate.isBefore(now)) {
                                setState(() {
                                  message = 'Invalid Date time';
                                });
                              } else {
                                Navigator.of(context).pop();
                                writeReminder(
                                        Reminder(returnDate, stops, Random().nextInt(pow(10, 6))))
                                    .then((_) => updateReminders());
                              }
                            },
                            child: Text('Add',
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ],
                  );
                },
              ),
            ));
  }

  void updateReminders() {
    if (mounted)
      setState(() {
        loading = true;
      });
    readReminders().then((List<Reminder> readReminders) {
      if (mounted)
        setState(() {
          reminders = readReminders;
          loading = false;
        });
    });
  }

  Future<void> refreshReminders() async {
    List<Reminder> nReminders = await readReminders();
    setState(() {
      reminders = nReminders;
    });
  }

  void scheduleNotification(Reminder reminder) async {
    var android = AndroidNotificationDetails(
      '43210',
      'Bus Scheduled Notifications',
      'Notifies the user at each reminder',
      priority: Priority.High,
      importance: Importance.Max,
    );
    var iOS = IOSNotificationDetails();
    await flutterLocalNotificationsPlugin.schedule(
        reminder.notificationId,
        'Bus Time Notifier',
        'For ${DateFormat("EEEE MMMM dd 'at' hh:mm a").format(reminder.time)}',
        reminder.time,
        NotificationDetails(android, iOS),
        androidAllowWhileIdle: false,
        payload: json.encode(reminder.toMap()));
  }

  Future<List<TimeOfDay>> getTimes(Stop stop) async {
    String url =
        'https://rt.data.gov.hk/v1/transport/citybus-nwfb/eta/CTB/${stop.id}/${stop.route}';

    http.Response response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load time data from API');
    }

    List data = json.decode(response.body)['data'];

    List<TimeOfDay> returnList = [];

    for (var map in data) {
      String dir = (stop.inbound) ? 'I' : 'O';
      if (map['dir'] == dir) {
        print(map['eta']);
        returnList.add(TimeOfDay.fromDateTime(
            DateTime.parse(map['eta'].substring(0, map['eta'].indexOf('+')))));
      }
    }
    return returnList;
  }

  Future<void> second(String payload) async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Bus Time Notifier'),
            contentPadding: EdgeInsets.symmetric(horizontal: 24),
            content: FutureBuilder(
                builder:
                    (BuildContext context, AsyncSnapshot<Map<String, List<dynamic>>> snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Icon(Icons.warning, color: Colors.red));
                  else if ((snapshot.connectionState == ConnectionState.done ||
                          snapshot.connectionState == ConnectionState.active) &&
                      snapshot.hasData)
                    return snapshot.data.isNotEmpty
                        ? Table(
                            children: List.generate(4, (i) => i - 1).map((int i) {
                              if (i == -1) {
                                return TableRow(
                                    children: Reminder.fromMap(json.decode(payload))
                                        .stops
                                        .map<Widget>((Stop stop) =>
                                            Text(stop.route + ', ' + stop.name, maxLines: 2))
                                        .toList());
                              }
                              return TableRow(
                                  children: snapshot.data.keys.map((String stopName) {
                                TimeOfDay time;
                                try {
                                  time = snapshot.data[stopName][i];
                                  return Text(time.format(context));
                                } catch (_) {
                                  return Text('.');
                                }
                              }).toList());
                            }).toList(),
                          )
                        : Text('Invalid ');
                  else
                    return Center(child: CircularProgressIndicator());
                },
                future: getStopTimes(Reminder.fromMap(json.decode(payload)))),
            actions: <Widget>[
              FlatButton(child: Text('Ok'), onPressed: () => Navigator.of(context).pop())
            ],
          );
        });
  }

  Future<Map<String, List>> getStopTimes(Reminder reminder) async {
    Map<String, List> times = Map();
    for (Stop stop in reminder.stops) {
      times[stop.name] = await getTimes(stop);
    }
    return times;
  }

  Future<void> onSelectNotification(String payload) async {
    Reminder reminder = Reminder.fromMap(json.decode(payload));
    Map<String, List> times = await getStopTimes(reminder);
    bool isValid = times.isNotEmpty;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Bus Time Notifier'),
            contentPadding: EdgeInsets.symmetric(horizontal: 24),
            content: isValid
                ? Table(
                    children: List.generate(4, (i) => i - 1).map((int i) {
                      if (i == -1) {
                        return TableRow(
                            children: reminder.stops
                                .map<Widget>(
                                    (Stop stop) => Text(stop.route + ', ' + stop.name, maxLines: 2))
                                .toList());
                      }
                      return TableRow(
                          children: times.keys.map((String stopName) {
                        TimeOfDay time;
                        try {
                          time = times[stopName][i];
                          return Text(time.format(context));
                        } catch (_) {
                          return Text('.');
                        }
                      }).toList());
                    }).toList(),
                  )
                : Text('Invalid '),

            // content: (isValid)
            //     ? Column(
            //         mainAxisSize: MainAxisSize.min,
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: times.map((TimeOfDay time) {
            //           return Text(time.format(context));
            //         }).toList(),
            //       )
            //     : Text('Invalid reminder'),
            actions: <Widget>[
              FlatButton(child: Text('Ok'), onPressed: () => Navigator.of(context).pop())
            ],
          );
        });
  }

  Future onDidReceiveLocalNotification(int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('Ok'), onPressed: null)],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Reminder Functionality
    updateReminders();
    print(reminders);

    // Notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = IOSInitializationSettings();

    var initSettings = InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bus Notifier',
          style: TextStyle(fontFamily: 'Rubik'),
        ),
        elevation: 0,
        // actions: <Widget>[Icon(Icons.directions_bus)],
        // centerTitle: true,
      ),
      //  ***************************************
      // backgroundColor: Colors.grey[100],
      body: (loading)
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshReminders,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight,
                    child: (reminders.isNotEmpty)
                        ? ListView(
                            children: List.generate(
                              reminders.length,
                              (index) => Dismissible(
                                key: UniqueKey(),
                                background: Container(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                          colors: (reminders[index].time.isBefore(DateTime.now()))
                                              ? [Colors.red, Colors.white]
                                              : [Colors.deepOrangeAccent, Colors.orange])
                                      // color: (reminders[index].time.isBefore(DateTime.now()))
                                      // ? Colors.red[200]
                                      // : Colors.white,
                                      ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        Text(
                                            DateFormat(
                                                    "EEEE MMMM dd 'at' hh:mm a '(${reminders[index].stops.length})'")
                                                .format(reminders[index].time),
                                            style: TextStyle(color: Colors.white)),
                                        reminders[index].stops.length == 1
                                            ? Text(
                                                reminders[index].stops[0].name,
                                                style: TextStyle(
                                                    color: Colors.grey[200], fontSize: 13),
                                              )
                                            : Container(),
                                        Text(
                                            reminders[index].stops.length == 1
                                                ? reminders[index].stops[0].route +
                                                    ' towards ' +
                                                    reminders[index].stops[0].destination
                                                : reminders[index]
                                                    .stops
                                                    .map((Stop stop) {
                                                      return '${stop.route} ${stop.inbound ? 'Inbound' : 'Outbound'} - ${stop.name}';
                                                    })
                                                    .toList()
                                                    .join('\n'),
                                            // maxLines:
                                            //     reminders[index].stops.length,
                                            style: TextStyle(color: Colors.grey[200], fontSize: 13))
                                      ],
                                    ),
                                  ),
                                ),
                                //
                                direction: DismissDirection.startToEnd,
                                onDismissed: (DismissDirection direction) async {
                                  await deleteReminder(index);
                                  print('Reminder removed');
                                  updateReminders();
                                },
                              ),
                            ),
                          )
                        : Center(child: Text('No reminders set')),
                  ),
                ],
              ),
            ),
      // ****************************************
      floatingActionButton:
          FloatingActionButton(onPressed: () => createReminder(context), child: Icon(Icons.add)),
    );
  }
}
