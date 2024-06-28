import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rigby Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const TimerHomePage(),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  _TimerHomePageState createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> {
  final TextEditingController _nomeTimerController = TextEditingController();
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _timerDisplay = "00:00:00";
  DateTime? _startTime;
  DateTime? _endTime;
  bool timerStarted = false;

  void _startTimer() {
    if (_stopwatch.isRunning) return;

    setState(() {
      timerStarted = true;
      _stopwatch.start();
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerDisplay = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  void _pauseTimer() {
    if (!_stopwatch.isRunning) return;

    setState(() {
      _stopwatch.stop();
      _timer.cancel();
    });
  }

  Future<void> _stopTimer() async {
    if (!_stopwatch.isRunning && _stopwatch.elapsed.inSeconds == 0) return;

    String finalTime = _timerDisplay;
    _endTime = DateTime.now();

    _pauseTimer();
    await _saveTimer(finalTime, _startTime!, _endTime!);

    setState(() {
      timerStarted = false;
      _timerDisplay = "00:00:00";
      _stopwatch.reset();
      _nomeTimerController.clear();
      _startTime = null;
      _endTime = null;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatTimeOfDay(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  Future<void> _saveTimer(
      String finalTime, DateTime startTime, DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    final dateTime = DateTime.now();
    final dayOfWeek = dateTime.weekday.toString();
    final storedTimers = prefs.getStringList(dayOfWeek) ?? [];

    final formattedStartTime = _formatTimeOfDay(startTime);
    final formattedEndTime = _formatTimeOfDay(endTime);
    final formattedTimer =
        "${_nomeTimerController.text} : $finalTime, começou às $formattedStartTime e terminou às $formattedEndTime";
    storedTimers.add(formattedTimer);
    prefs.setStringList(dayOfWeek, storedTimers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rigby Timer",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimerHistoryPage(),
                    ));
              },
              icon: const Icon(
                Icons.history,
                color: Colors.white,
              ))
        ],
      ),
      backgroundColor: Colors.deepPurple,
      body: Center(
          child: Container(
        padding: const EdgeInsets.all(15),
        width: 450,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _nomeTimerController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.timer,
                  color: Colors.white,
                ),
                labelText: "Nome do timer",
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const Divider(
              height: 15,
              color: Colors.transparent,
            ),
            Text(
              _timerDisplay,
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.play_arrow,
                    color: _stopwatch.isRunning ? Colors.red : Colors.white,
                  ),
                  onPressed: _startTimer,
                  iconSize: 50.0,
                ),
                IconButton(
                  icon: Icon(
                    Icons.pause,
                    color: !_stopwatch.isRunning && timerStarted
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: _pauseTimer,
                  iconSize: 50.0,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.stop,
                    color: Colors.white,
                  ),
                  onPressed: _stopTimer,
                  iconSize: 50.0,
                ),
              ],
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      )),
    );
  }
}

class TimerHistoryPage extends StatefulWidget {
  const TimerHistoryPage({super.key});

  @override
  _TimerHistoryPageState createState() => _TimerHistoryPageState();
}

class _TimerHistoryPageState extends State<TimerHistoryPage> {
  Future<Map<String, List<String>>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<String>> history = {};

    for (int i = 1; i <= 7; i++) {
      final dayTimers = prefs.getStringList(i.toString()) ?? [];
      history[i.toString()] = dayTimers;
    }

    return history;
  }

  void _deleteTimer(String dayOfWeek, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final dayTimers = prefs.getStringList(dayOfWeek) ?? [];

    if (index >= 0 && index < dayTimers.length) {
      dayTimers.removeAt(index);
      prefs.setStringList(dayOfWeek, dayTimers);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Timer deletado com sucesso!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Histórico de Timers",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.deepPurple,
      body: FutureBuilder<Map<String, List<String>>>(
        future: _loadHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar histórico"));
          }
          final history = snapshot.data ?? {};
          return ListView.builder(
            itemCount: history.keys.length,
            itemBuilder: (context, index) {
              final day = history.keys.elementAt(index);
              String nomeDia = "Segunda";
              switch (day) {
                case "1":
                  nomeDia = "Segunda";
                  break;
                case "2":
                  nomeDia = "Terça";
                  break;
                case "3":
                  nomeDia = "Quarta";
                  break;
                case "4":
                  nomeDia = "Quinta";
                  break;
                case "5":
                  nomeDia = "Sexta";
                  break;
                case "6":
                  nomeDia = "Sábado";
                  break;
                case "7":
                  nomeDia = "Domingo";
                  break;
                default:
              }
              final timers = history[day] ?? [];
              return ExpansionTile(
                title: Text(
                  nomeDia,
                  style: const TextStyle(color: Colors.white),
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                children: timers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String timer = entry.value;
                  return ListTile(
                    title: Text(
                      timer,
                      style: const TextStyle(color: Colors.white),
                    ),
                    leading: const Icon(
                      Icons.timer,
                      color: Colors.white,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _deleteTimer(day, idx);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
