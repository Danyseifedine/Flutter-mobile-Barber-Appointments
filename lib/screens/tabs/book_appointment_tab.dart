import 'package:flutter/material.dart';
import 'package:sys/models/appointment.dart';
import 'package:sys/services/appointment_service.dart';
import 'package:sys/services/service_service.dart';
import 'package:sys/utils/app_theme.dart';
import 'package:intl/intl.dart';

class BusinessHour {
  final String day;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  BusinessHour({
    required this.day,
    this.openTime,
    this.closeTime,
    required this.isClosed,
  });

  factory BusinessHour.fromJson(Map<String, dynamic> json) {
    return BusinessHour(
      day: json['day_of_week'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
      isClosed: json['is_closed'] == 1,
    );
  }

  String get formattedHours {
    if (isClosed) return 'Closed';
    if (openTime == null || closeTime == null) return 'Not available';
    return '${openTime!.substring(0, 5)} - ${closeTime!.substring(0, 5)}';
  }
}

class BookAppointmentTab extends StatefulWidget {
  const BookAppointmentTab({super.key});

  @override
  State<BookAppointmentTab> createState() => _BookAppointmentTabState();
}

class _BookAppointmentTabState extends State<BookAppointmentTab> {
  final ServiceService _serviceService = ServiceService();
  final AppointmentService _appointmentService = AppointmentService();

  List<Service> _availableServices = [];
  List<Service> _selectedServices = [];
  List<BusinessHour> _businessHours = [];
  bool _isBusinessHoursLoaded = false;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _testTokenController = TextEditingController();

  bool _isLoadingServices = true;
  bool _isCheckingAvailability = false;
  bool _isBooking = false;
  String? _errorMessage;
  String? _availabilityMessage;
  bool? _isTimeSlotAvailable;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadBusinessHours().then((_) {
      _setValidInitialDate();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _testTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessHours() async {
    try {
      final result = await _appointmentService.getBusinessHours();

      if (result['success'] && result['data'] != null) {
        final List<dynamic> hoursData = result['data'];
        setState(() {
          _businessHours =
              hoursData.map((json) => BusinessHour.fromJson(json)).toList();
          _isBusinessHoursLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading business hours: $e');
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _errorMessage = null;
    });

    try {
      final services = await _serviceService.getServices();

      if (services.isEmpty) {
        setState(() {
          _isLoadingServices = false;
          _errorMessage = 'No services available. Please try again later.';
        });
        return;
      }

      setState(() {
        _availableServices =
            services.where((s) => s.status == 'available').toList();
        _isLoadingServices = false;

        if (_availableServices.isEmpty) {
          _errorMessage = 'No available services found at this time.';
        }
      });
    } catch (e) {
      print('Error in _loadServices: $e');
      setState(() {
        _isLoadingServices = false;
        _errorMessage = 'Failed to load services: ${e.toString()}';
      });
    }
  }

  // Check if the selected date is within business hours
  bool _isWithinBusinessHours() {
    if (_businessHours.isEmpty)
      return true; // Default to true if not loaded yet

    // Get the business hours for the selected day
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);
    final businessHour = _businessHours.firstWhere(
      (hour) => hour.day.toLowerCase() == dayOfWeek.toLowerCase(),
      orElse: () => BusinessHour(
        day: dayOfWeek,
        openTime: '09:00:00',
        closeTime: '17:00:00',
        isClosed: false,
      ),
    );

    // If the day is closed, it's not within business hours
    if (businessHour.isClosed) return false;

    // If no opening/closing time, assume standard hours
    if (businessHour.openTime == null || businessHour.closeTime == null)
      return true;

    // Parse the business hours
    final openTimeParts = businessHour.openTime!.split(':');
    final closeTimeParts = businessHour.closeTime!.split(':');

    final openTime = TimeOfDay(
      hour: int.parse(openTimeParts[0]),
      minute: int.parse(openTimeParts[1]),
    );

    final closeTime = TimeOfDay(
      hour: int.parse(closeTimeParts[0]),
      minute: int.parse(closeTimeParts[1]),
    );

    // Convert to minutes for easier comparison
    final selectedMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;

    return selectedMinutes >= openMinutes && selectedMinutes < closeMinutes;
  }

  Future<void> _checkAvailability() async {
    if (_selectedServices.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one service';
      });
      return;
    }

    if (!_isWithinBusinessHours()) {
      setState(() {
        _isTimeSlotAvailable = false;
        _availabilityMessage = 'Selected time is outside business hours.';
      });
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = null;
      _isTimeSlotAvailable = null;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      final result = await _appointmentService.checkAvailability(
        date: formattedDate,
        time: formattedTime,
        duration: _totalDuration,
      );

      setState(() {
        _isCheckingAvailability = false;

        if (result['success']) {
          _isTimeSlotAvailable = result['available'];
          if (_isTimeSlotAvailable == true) {
            _availabilityMessage = 'This time slot is available!';
          } else {
            _availabilityMessage =
                'This time slot is not available. Please select another time.';
          }
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingAvailability = false;
        _errorMessage = 'Error checking availability: ${e.toString()}';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Find a valid initial date (not on a closed day)
    DateTime validInitialDate = _selectedDate;

    // If business hours are loaded, make sure the initial date is on an open day
    if (_businessHours.isNotEmpty) {
      // Check if current selected date is valid
      final dayOfWeek = DateFormat('EEEE').format(validInitialDate);
      final isClosedDay = _businessHours.any((hour) =>
          hour.day.toLowerCase() == dayOfWeek.toLowerCase() && hour.isClosed);

      // If it's closed, find the next available day
      if (isClosedDay) {
        // Try the next 7 days to find an open day
        for (int i = 1; i <= 7; i++) {
          final nextDate = DateTime.now().add(Duration(days: i));
          final nextDayOfWeek = DateFormat('EEEE').format(nextDate);
          final nextDayClosed = _businessHours.any((hour) =>
              hour.day.toLowerCase() == nextDayOfWeek.toLowerCase() &&
              hour.isClosed);

          if (!nextDayClosed) {
            validInitialDate = nextDate;
            break;
          }
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) {
        // Check if the day of week is a closed day
        final dayOfWeek = DateFormat('EEEE').format(day);

        // Find the business hour for this day
        final businessHour = _businessHours.firstWhere(
          (hour) => hour.day.toLowerCase() == dayOfWeek.toLowerCase(),
          orElse: () => BusinessHour(
            day: dayOfWeek,
            isClosed: false,
          ),
        );

        // Return false for days that are closed (making them non-selectable)
        return !businessHour.isClosed;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Reset availability check when date changes
        _availabilityMessage = null;
        _isTimeSlotAvailable = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        // Reset availability check when time changes
        _availabilityMessage = null;
        _isTimeSlotAvailable = null;
      });
    }
  }

  void _toggleServiceSelection(Service service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
      // Reset availability check when services change
      _availabilityMessage = null;
      _isTimeSlotAvailable = null;
    });
  }

  int get _totalDuration {
    return _selectedServices.fold(
        0, (sum, service) => sum + service.durationMinutes);
  }

  double get _totalPrice {
    return _selectedServices.fold(0, (sum, service) => sum + service.price);
  }

  Future<void> _bookAppointment() async {
    // First check availability
    if (_isTimeSlotAvailable == null) {
      await _checkAvailability();

      // If slot is not available after check, don't proceed
      if (_isTimeSlotAvailable == false) {
        return;
      }
    } else if (_isTimeSlotAvailable == false) {
      // If we already know slot is not available, don't proceed
      return;
    }

    if (_selectedServices.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one service';
      });
      return;
    }

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      final serviceIds = _selectedServices.map((s) => s.id).toList();

      final result = await _appointmentService.bookAppointment(
        date: formattedDate,
        startTime: formattedTime,
        serviceIds: serviceIds,
        notes: _notesController.text,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Appointment booked successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Reset form
        setState(() {
          _selectedServices = [];
          _notesController.clear();
          _availabilityMessage = null;
          _isTimeSlotAvailable = null;
        });

        // Navigate to appointments tab (index 1)
        _navigateToTab(1);

        // Fallback navigation in case _navigateToTab doesn't work
        Future.delayed(const Duration(milliseconds: 300), () {
          final tabController = DefaultTabController.of(context);
          if (tabController != null) {
            tabController.animateTo(1);
            print('Navigated to appointments tab using DefaultTabController');
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to book appointment: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  // Set an initial date that is not on a closed day
  void _setValidInitialDate() {
    if (_businessHours.isEmpty) return;

    // Start with tomorrow
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));

    // Check if initial date is on a closed day
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().add(Duration(days: i + 1));
      final dayOfWeek = DateFormat('EEEE').format(date);

      // Check if this day is closed
      final isClosed = _businessHours.any((hour) =>
          hour.day.toLowerCase() == dayOfWeek.toLowerCase() && hour.isClosed);

      if (!isClosed) {
        initialDate = date;
        break;
      }
    }

    // Update the selected date if we found a valid one
    setState(() {
      _selectedDate = initialDate;
    });
  }

  Future<void> _debugTestAPI() async {
    // Show dialog to input token
    final String? token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test API with Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _testTokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token',
                hintText: 'Paste your token here',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(_testTokenController.text),
            child: const Text('Test'),
          ),
        ],
      ),
    );

    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Token is required for testing.';
      });
      return;
    }

    setState(() {
      _errorMessage = 'Testing API with provided token, check console logs...';
    });

    try {
      final result =
          await _appointmentService.debugTestAppointmentAPI(testToken: token);

      setState(() {
        if (result['success']) {
          _errorMessage = 'API Test SUCCESS! Check logs for details.';
        } else {
          _errorMessage =
              'API Test FAILED: Status: ${result['status_code']}. Check logs for details.';
        }
      });

      // After 5 seconds, clear the message
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Test error: ${e.toString()}';
      });
    }
  }

  // Method to navigate to different tabs
  void _navigateToTab(int index) {
    // Find the parent widget that can handle tab navigation
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold == null) return;

    // Get the parent Navigator
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator == null) return;

    // Find the parent HomeScreen and update its state
    final ancestorState = context.findAncestorStateOfType<State>();
    if (ancestorState != null) {
      // This is a simplified approach - in a real app, you'd use a more robust method
      // like Provider, Riverpod, or other state management solutions
      final setState = ancestorState.setState;
      if (setState != null) {
        setState(() {
          // This assumes the parent has a _selectedIndex field
          // In a real app, you'd use a proper state management solution
          try {
            ancestorState.widget.runtimeType.toString().contains('HomeScreen');
            // ignore: invalid_use_of_protected_member
            setState(() {
              // This is a hack and not recommended in production code
              // In a real app, use proper state management
              final field = ancestorState.runtimeType
                  .toString()
                  .contains('_selectedIndex');
              if (field) {
                // ignore: avoid_dynamic_calls
                (ancestorState as dynamic)._selectedIndex = index;
              }
            });
          } catch (e) {
            // Fallback to a simpler approach
            print('Navigation error: $e');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        actions: [
          // Debug button - remove in production
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugTestAPI,
            tooltip: 'Test API',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
            tooltip: 'Refresh services',
          ),
        ],
      ),
      body: _isLoadingServices
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Business Hours Display
                  if (_isBusinessHoursLoaded && _businessHours.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Business Hours',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _businessHours.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _businessHours[index].day.capitalize(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _businessHours[index].formattedHours,
                                      style: TextStyle(
                                        color: _businessHours[index].isClosed
                                            ? AppTheme.textSecondaryColor
                                            : AppTheme.successColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Date and Time Selection
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Date & Time',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Date',
                                      prefixIcon:
                                          const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat('EEE, MMM d, yyyy')
                                          .format(_selectedDate),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Time',
                                      prefixIcon: const Icon(Icons.access_time),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedTime.format(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Services Selection
                  const Text(
                    'Select Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_availableServices.isEmpty)
                    Center(
                      child: Text(
                        'No services available',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _availableServices.length,
                      itemBuilder: (context, index) {
                        final service = _availableServices[index];
                        final isSelected = _selectedServices.contains(service);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isSelected ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _toggleServiceSelection(service),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleServiceSelection(service),
                                    activeColor: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.serviceName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service.description,
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '\$${service.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: AppTheme.secondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              '${service.durationMinutes} min',
                                              style: TextStyle(
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Any special requests or information',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Summary
                  if (_selectedServices.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Duration:'),
                                Text(
                                  '$_totalDuration min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Price:'),
                                Text(
                                  '\$${_totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryColor,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            if (_availabilityMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isTimeSlotAvailable == true
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _availabilityMessage!,
                                  style: TextStyle(
                                    color: _isTimeSlotAvailable == true
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            if (_selectedServices.isNotEmpty &&
                                _availabilityMessage == null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isCheckingAvailability
                                      ? null
                                      : _checkAvailability,
                                  child: _isCheckingAvailability
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Check Availability'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isBooking ||
                              _selectedServices.isEmpty ||
                              (_isTimeSlotAvailable == false) ||
                              (_isTimeSlotAvailable == null)
                          ? null
                          : _bookAppointment,
                      child: _isBooking
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Book Appointment'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
