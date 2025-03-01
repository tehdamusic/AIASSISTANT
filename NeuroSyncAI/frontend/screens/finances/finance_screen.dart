import 'package:flutter/material.dart';
import 'package:your_project/services/api/finance_api.dart';

class FinanceScreen extends StatefulWidget {
  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _financeData = [];

  @override
  void initState() {
    super.initState();
    _fetchFinanceData();
  }

  Future<void> _fetchFinanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await FinanceApi.getFinanceData();
      setState(() {
        _financeData = data;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = "Failed to load finance data. Please try again.";
        _isLoading = false;
      });

      _showErrorDialog(_errorMessage!);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _fetchFinanceData();
            },
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Finance Overview")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Something went wrong.",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchFinanceData,
                        child: Text("Retry"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _financeData.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text("Transaction ${index + 1}"),
                      subtitle: Text(_financeData[index].toString()),
                    );
                  },
                ),
    );
  }
}
