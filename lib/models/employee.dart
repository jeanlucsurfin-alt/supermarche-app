enum EmployeeRole { caissier, gerant, admin }

extension EmployeeRoleLabel on EmployeeRole {
  String get label {
    switch (this) {
      case EmployeeRole.caissier:
        return 'Caissier';
      case EmployeeRole.gerant:
        return 'Gérant';
      case EmployeeRole.admin:
        return 'Admin';
    }
  }
}

class Employee {
  final int? id;
  final String name;
  final EmployeeRole role;
  final String pin;

  Employee({
    this.id,
    required this.name,
    required this.role,
    required this.pin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'pin': pin,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      role: EmployeeRole.values.firstWhere((r) => r.name == map['role'],
          orElse: () => EmployeeRole.caissier),
      pin: map['pin'],
    );
  }
}
