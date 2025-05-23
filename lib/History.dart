import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:united_code_scanner_generator/Generator.dart';
import 'package:united_code_scanner_generator/detail.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CodeHistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('code_history');
    if (historyJson != null) {
      setState(() {
        history = CodeHistoryItem.decodeList(historyJson);
      });
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('code_history');
    setState(() => history.clear());
  }

  Future<void> _removeSingleHistory(int index) async {
    history.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    final updatedJson = CodeHistoryItem.encodeList(history);
    await prefs.setString('code_history', updatedJson);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("History", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 5,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.white, size: 28),
            tooltip: "Clear all history",
            onPressed: _clearHistory,
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: history.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey.shade500),
              SizedBox(height: 12),
              Text(
                "No history yet",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.fromLTRB(12, 100, 12, 16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return Dismissible(
              key: Key(item.timestamp.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                padding: EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                color: Colors.red.shade400,
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _removeSingleHistory(index),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.indigo.shade50,
                    child: Icon(Icons.qr_code_2, color: Colors.grey.shade800),
                  ),
                  title: Text(
                    item.code,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${item.type} • ${item.timestamp}"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(historyItem: item),
                      ),
                    );
                  },
                ),

              ),
            );
          },
        ),
      ),
    );
  }
}
