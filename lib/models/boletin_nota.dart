class BoletinNota {
  final String asignatura;
  final double nota;

  BoletinNota({required this.asignatura, required this.nota});

  factory BoletinNota.fromMap(Map<String, dynamic> map) {
    return BoletinNota(
      asignatura: map['asignatura'] ?? '',
      nota: double.tryParse(map['nota'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'asignatura': asignatura, 'nota': nota};
  }

  @override
  String toString() => '$asignatura: $nota';
}
