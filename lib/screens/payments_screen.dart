import 'package:flutter/material.dart';
import 'package:sys/models/appointment.dart';
import 'package:sys/services/appointment_service.dart';
import 'package:sys/utils/app_theme.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<Appointment> _paidAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await _appointmentService.getAppointments();

      setState(() {
        // Filter only appointments with payments
        _paidAppointments = appointments
            .where((appointment) => appointment.payment != null)
            .toList();

        // Sort by date (newest first)
        _paidAppointments.sort((a, b) {
          return b.appointmentDate.compareTo(a.appointmentDate);
        });

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: _paidAppointments.isEmpty
                  ? _buildEmptyPayments()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _paidAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _paidAppointments[index];
                        return _buildPaymentCard(appointment);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyPayments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No payment history found',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Appointment appointment) {
    final payment = appointment.payment!;
    final dateFormat = DateFormat('MMM d, yyyy');
    final date = DateTime.parse(appointment.appointmentDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Services:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.serviceNames,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment ID: #${payment.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
                Text(
                  'Appointment ID: #${appointment.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
