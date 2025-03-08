import 'package:flutter/material.dart';
import 'package:sys/models/appointment.dart';
import 'package:sys/services/appointment_service.dart';
import 'package:sys/utils/app_theme.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  late TabController _tabController;

  List<Appointment> _allAppointments = [];
  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _pastAppointments = [];
  List<Appointment> _cancelledAppointments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await _appointmentService.getAppointments();

      setState(() {
        _allAppointments = appointments;

        // Filter appointments by status
        _upcomingAppointments = appointments
            .where((appointment) =>
                appointment.status == 'scheduled' ||
                appointment.status == 'confirmed')
            .toList();

        _pastAppointments = appointments
            .where((appointment) => appointment.status == 'completed')
            .toList();

        _cancelledAppointments = appointments
            .where((appointment) => appointment.status == 'cancelled')
            .toList();

        // Sort by date and time
        _upcomingAppointments.sort((a, b) {
          int dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
          if (dateComparison != 0) return dateComparison;
          return a.startTime.compareTo(b.startTime);
        });

        _pastAppointments.sort((a, b) {
          int dateComparison = b.appointmentDate.compareTo(a.appointmentDate);
          if (dateComparison != 0) return dateComparison;
          return b.startTime.compareTo(a.startTime);
        });

        _cancelledAppointments.sort((a, b) {
          int dateComparison = b.appointmentDate.compareTo(a.appointmentDate);
          if (dateComparison != 0) return dateComparison;
          return b.startTime.compareTo(a.startTime);
        });

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Are you sure you want to cancel your appointment on ${appointment.formattedDate} at ${appointment.startTime.substring(0, 5)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response =
            await _appointmentService.cancelAppointment(appointment.id);

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadAppointments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel appointment. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh appointments',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList(_upcomingAppointments,
                      canCancel: true),
                  _buildAppointmentsList(_pastAppointments),
                  _buildAppointmentsList(_cancelledAppointments),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments,
      {bool canCancel = false}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppTheme.textLightColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, canCancel: canCancel);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment,
      {bool canCancel = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  appointment.formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ...appointment.services.map((service) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(service.serviceName),
                          ),
                          Text(
                            '\$${service.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$${appointment.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Duration: ${appointment.totalDuration} min',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    if (appointment.payment != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Paid',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (canCancel &&
                    (appointment.status == 'scheduled' ||
                        appointment.status == 'confirmed'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _cancelAppointment(appointment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel Appointment'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
