import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/ingredient_analysis.dart';
import 'analysis_result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<FoodAnalysisResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final dbService = DatabaseService();
      final history = await dbService.getAnalysisHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(FoodAnalysisResult result) async {
    // 先立即从UI中移除项目
    final int originalIndex = _history.indexOf(result);
    if (originalIndex == -1) return;
    
    setState(() {
      _history.remove(result);
    });
    
    try {
      final dbService = DatabaseService();
      // 使用数据库记录的ID删除（查找对应的ID）
      final history = await dbService.getAnalysisHistory();
      final int dbIndex = history.indexWhere((item) => 
          item.analysisTime == result.analysisTime && 
          item.foodName == result.foodName);
      
      if (dbIndex != -1) {
        await dbService.deleteAnalysisResult(dbIndex + 1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除成功')),
        );
      } else {
        throw Exception('未找到对应的数据库记录');
      }
    } catch (e) {
      // 删除失败，恢复项目
      setState(() {
        if (!_history.contains(result)) {
          _history.insert(originalIndex, result);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  Widget _buildHistoryItem(FoodAnalysisResult result, int index) {
    return Dismissible(
      key: Key(result.analysisTime.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteItem(result),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getScoreColor(result.healthScore),
            child: Text(
              result.healthScore.toStringAsFixed(0),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            result.foodName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('分析时间: ${_formatDateTime(result.analysisTime)}'),
              Text('配料数量: ${result.ingredients.length}种'),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalysisResultPage(analysisResult: result, isFromHistory: true),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    if (score >= 4) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '暂无历史记录',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '开始分析食品配料来查看历史记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(_history[index], index);
                    },
                  ),
                ),
    );
  }
}