import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'dart:io';

void main() {
  runApp(const HWConfigApp());
}

class HWConfigApp extends StatelessWidget {
  const HWConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HW Config Manager',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isRooted = false;
  String _cpuInfo = "Unknown";
  String _lastCommandResult = "";

  @override
  void initState() {
    super.initState();
    _checkRootStatus();
    _fetchCPUInfo();
  }

  Future<void> _checkRootStatus() async {
    try {
      var shell = Shell();
      var result = await shell.run('su -c id');
      setState(() {
        _isRooted = result.first.stdout.toString().contains("uid=0");
      });
    } catch (e) {
      setState(() {
        _isRooted = false;
      });
    }
  }

  Future<void> _fetchCPUInfo() async {
    try {
      var shell = Shell();
      var result = await shell.run('cat /proc/cpuinfo | grep "model name" | head -n 1');
      setState(() {
        _cpuInfo = result.first.stdout.toString().replaceAll("model name\t: ", "").trim();
      });
    } catch (e) {
      setState(() {
        _cpuInfo = "Error fetching CPU info";
      });
    }
  }

  Future<void> _executeRootCommand(String command) async {
    try {
      var shell = Shell();
      var result = await shell.run('su -c "$command"');
      setState(() {
        _lastCommandResult = result.first.stdout.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Command Executed Successfully")),
      );
    } catch (e) {
      setState(() {
        _lastCommandResult = "Error: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Execution Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hardware Config Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkRootStatus();
              _fetchCPUInfo();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _isRooted ? Icons.check_circle : Icons.error,
                  color: _isRooted ? Colors.green : Colors.red,
                ),
                title: const Text("Root Status"),
                subtitle: Text(_isRooted ? "Root Access Granted" : "Root Access Denied / Not Available"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.memory),
                title: const Text("CPU Info"),
                subtitle: Text(_cpuInfo),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isRooted ? () => _executeRootCommand("echo 1 > /sys/devices/system/cpu/cpu0/online") : null,
                  child: const Text("Enable CPU0"),
                ),
                ElevatedButton(
                  onPressed: _isRooted ? () => _executeRootCommand("reboot recovery") : null,
                  child: const Text("Reboot Recovery"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Last Output:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _lastCommandResult.isEmpty ? "No commands executed yet." : _lastCommandResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
