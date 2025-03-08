class Service {
  final int id;
  final String serviceName;
  final String description;
  final int durationMinutes;
  final double price;
  final String status;

  Service({
    required this.id,
    required this.serviceName,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.status,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      serviceName: json['service_name'],
      description: json['description'],
      durationMinutes: json['duration_minutes'],
      price: double.parse(json['price'].toString()),
      status: json['status'],
    );
  }
}

class Payment {
  final int id;
  final int appointmentId;
  final double amount;

  Payment({
    required this.id,
    required this.appointmentId,
    required this.amount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      appointmentId: json['appointment_id'],
      amount: double.parse(json['amount'].toString()),
    );
  }
}

class Appointment {
  final int id;
  final int userId;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;
  final double totalPrice;
  final int totalDuration;
  final List<Service> services;
  final Payment? payment;

  Appointment({
    required this.id,
    required this.userId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.totalPrice,
    required this.totalDuration,
    required this.services,
    this.payment,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    List<Service> servicesList = [];
    if (json['services'] != null) {
      servicesList = List<Service>.from(
        json['services'].map((service) => Service.fromJson(service)),
      );
    }

    Payment? paymentObj;
    if (json['payment'] != null) {
      paymentObj = Payment.fromJson(json['payment']);
    }

    return Appointment(
      id: json['id'],
      userId: json['user_id'],
      appointmentDate: json['appointment_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      notes: json['notes'],
      totalPrice: double.parse(json['total_price'].toString()),
      totalDuration: json['total_duration'],
      services: servicesList,
      payment: paymentObj,
    );
  }

  String get formattedDate {
    final parts = appointmentDate.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return appointmentDate;
  }

  String get formattedTime {
    return '${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}';
  }

  String get serviceNames {
    return services.map((service) => service.serviceName).join(', ');
  }
}
