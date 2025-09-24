import 'package:entredos/models/nota_academica.dart';

class Trimestre {
  static final todos = [
    Trimestre('1º Trimestre', 9, 11),
    Trimestre('2º Trimestre', 12, 2),
    Trimestre('3º Trimestre', 3, 6),
  ];
  final String nombre;
  final int inicioMes;

  final int finMes;

  Trimestre(this.nombre, this.inicioMes, this.finMes);

  bool contiene(DateTime fecha) {
    if (inicioMes <= finMes) {
      return fecha.month >= inicioMes && fecha.month <= finMes;
    } else {
      // Trimestre que cruza el año (ej: diciembre a febrero)
      return fecha.month >= inicioMes || fecha.month <= finMes;
    }
  }

  List<NotaAcademica> filtrar(List<NotaAcademica> notas) {
    return notas.where((n) => contiene(n.fecha)).toList();
  }

  static Trimestre? desdeNombre(String nombre) {
    return todos.firstWhere(
      (t) => t.nombre == nombre,
      orElse: () => Trimestre('Todos', 1, 12),
    );
  }
}
