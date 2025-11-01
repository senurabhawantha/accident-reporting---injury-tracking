import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cm/services/injury_tracker_service.dart';
import 'package:cm/theme/app_theme.dart';
import 'package:intl/intl.dart';

class InjuryHistoryPage extends StatefulWidget {
  const InjuryHistoryPage({super.key});

  @override
  State<InjuryHistoryPage> createState() => _InjuryHistoryPageState();
}

class _InjuryHistoryPageState extends State<InjuryHistoryPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late InjuryTrackerService _service;
  
  bool _isLoading = true;
  List<dynamic> _injuries = [];
  Map<String, dynamic>? _statistics;
  
  @override
  void initState() {
    super.initState();
    _service = InjuryTrackerService(userId: user?.uid ?? '');
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final injuries = await _service.getInjuries();
      final stats = await _service.getStatistics();
      
      setState(() {
        _injuries = injuries;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading data: $e');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _showInjuryDetails(Map<String, dynamic> injury) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(injury['severity']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      injury['severity'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(injury['confidence'] * 100).toStringAsFixed(1)}% confidence',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Date: ${_formatDate(injury['createdAt'])}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Divider(height: 32),
              
              // Recommendations
              if (injury['recommendations'] != null) ...[
                const Text(
                  'First Aid Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Immediate Actions
                if (injury['recommendations']['immediate_actions'] != null) ...[
                  const Text(
                    'Immediate Actions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(injury['recommendations']['immediate_actions']),
                  const SizedBox(height: 12),
                ],
                
                // First Aid Steps
                if (injury['recommendations']['first_aid_steps'] != null) ...[
                  const Text(
                    'First Aid Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    (injury['recommendations']['first_aid_steps'] as List).length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${index + 1}. '),
                          Expanded(
                            child: Text(
                              injury['recommendations']['first_aid_steps'][index],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _updateStatus(injury['id']);
                      },
                      icon: const Icon(Icons.update),
                      label: const Text('Update Status'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteInjury(injury['id']);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _updateStatus(String injuryId) async {
    final statusOptions = ['healing', 'recovered', 'worsening', 'active'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((status) {
            return ListTile(
              title: Text(status.toUpperCase()),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _service.updateInjuryStatus(injuryId, status);
                  _showSuccess('Status updated');
                  _loadData();
                } catch (e) {
                  _showError('Error updating status: $e');
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Future<void> _deleteInjury(String injuryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Injury Record'),
        content: const Text('Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _service.deleteInjury(injuryId);
        _showSuccess('Record deleted');
        _loadData();
      } catch (e) {
        _showError('Error deleting record: $e');
      }
    }
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _buildStatisticsCard() {
    if (_statistics == null) return const SizedBox.shrink();
    
    final severityBreakdown = _statistics!['severity_breakdown'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _statistics!['total_injuries'].toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  'Mild',
                  severityBreakdown['mild'].toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  'Moderate',
                  severityBreakdown['moderate'].toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  'Severe',
                  severityBreakdown['severe'].toString(),
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Injury History'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatisticsCard(),
                    const SizedBox(height: 20),
                    if (_injuries.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            SizedBox(height: 40),
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No injury records yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _injuries.length,
                        itemBuilder: (context, index) {
                          final injury = _injuries[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(injury['severity'])
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  color: _getSeverityColor(injury['severity']),
                                ),
                              ),
                              title: Text(
                                injury['severity'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(injury['severity']),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(_formatDate(injury['createdAt'])),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Confidence: ${(injury['confidence'] * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showInjuryDetails(injury),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
