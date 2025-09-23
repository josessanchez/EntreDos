import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'document_list_screen.dart';
import 'hijos_screen.dart';
import 'calendario_screen.dart';
import 'academico_screen.dart';
import 'package:entredos/widgets/pagos/vista_pagos.dart';

class IndexScreen extends StatefulWidget {
  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  List<Map<String, dynamic>> hijos = [];
  String? hijoIdSeleccionado;
  String? hijoNombreSeleccionado;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarHijos();
  }

  Future<void> cargarHijos() async {
    final usuarioID = FirebaseAuth.instance.currentUser?.uid;
    if (usuarioID == null) {
      setState(() => cargando = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hijos')
          .where('progenitores', arrayContains: usuarioID)
          .get();

      final lista = snapshot.docs.map((doc) {
        final nombre = doc['nombre']?.toString() ?? 'Sin nombre';
        final fotoUrl = doc['fotoUrl']?.toString() ?? '';
        return {'id': doc.id, 'nombre': nombre, 'fotoUrl': fotoUrl};
      }).toList();

      if (hijoIdSeleccionado != null &&
          !lista.any((h) => h['id'] == hijoIdSeleccionado)) {
        hijoIdSeleccionado = lista.isNotEmpty ? lista.first['id'] : null;
        hijoNombreSeleccionado = lista.isNotEmpty
            ? lista.first['nombre']
            : null;
      }

      if (hijoIdSeleccionado == null && lista.isNotEmpty) {
        hijoIdSeleccionado = lista.first['id'];
        hijoNombreSeleccionado = lista.first['nombre'];
      }

      setState(() {
        hijos = lista;
        cargando = false;
      });
    } catch (e) {
      print('⚠️ Error al cargar hijos: $e');
      setState(() => cargando = false);
    }
  }

  void mostrarMensajeSeleccion(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❗ Añade un hijo antes de acceder a esta sección'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool sinHijos = hijos.isEmpty;
    final bool variosHijos = hijos.length > 1;

    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A), // Fondo general azul oscuro
      body: cargando
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    'Tu espacio seguro para gestionar la custodia',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 28),
                  if (sinHijos)
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 24),
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Color(0xFF3A86FF), Color(0xFFFF5E9D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.child_care,
                                size: 64,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '¡Bienvenido a EntreDos!\nAñade a tu primer hijo/a para empezar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Montserrat',
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HijosScreen(),
                                    ),
                                  );
                                  cargarHijos();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Añadir hijo/a',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!sinHijos)
                    Container(
                      margin: EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Color(0xFF3A86FF), Color(0xFFFF5E9D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...hijos.map((hijo) {
                                final nombre = hijo['nombre'] ?? 'Sin nombre';
                                final edad = hijo['edad'] ?? '';
                                final seleccionado =
                                    hijo['id'] == hijoIdSeleccionado;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      hijoIdSeleccionado = hijo['id'];
                                      hijoNombreSeleccionado = nombre;
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: seleccionado
                                              ? LinearGradient(
                                                  colors: [
                                                    Color(0xFF5C2D91),
                                                    Color(0xFFC76DFF),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: seleccionado
                                              ? null
                                              : Color(0xFF1B263B),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.12,
                                          backgroundImage: NetworkImage(
                                            hijo['fotoUrl'],
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        nombre,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Montserrat',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HijosScreen(),
                                    ),
                                  );
                                  cargarHijos();
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 28,
                                        color: Color(0xFF0D1B2A),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Añadir',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Montserrat',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'Accede rápidamente a tus secciones:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 1,
                    children: [
                      DashboardButton(
                        icon: Icons.folder,
                        label: 'Documentos',
                        description:
                            'Gestiona los archivos importantes del menor',
                        color: Colors.orange,
                        onPressed: () {
                          if (sinHijos) {
                            mostrarMensajeSeleccion(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DocumentListScreen(
                                hijoId: hijoIdSeleccionado!,
                                hijoNombre: hijoNombreSeleccionado ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                      DashboardButton(
                        icon: Icons.calendar_today,
                        label: 'Calendario',
                        description:
                            'Consulta los eventos importantes del menor',
                        color: Colors.blue,
                        onPressed: () {
                          if (sinHijos) {
                            mostrarMensajeSeleccion(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CalendarioScreen(
                                hijoId: hijoIdSeleccionado!,
                                hijoNombre: hijoNombreSeleccionado ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                      DashboardButton(
                        icon: Icons.attach_money,
                        label: 'Pagos',
                        description: 'Gestiona los gastos entre progenitores',
                        color: Colors.green,
                        onPressed: () {
                          if (sinHijos) {
                            mostrarMensajeSeleccion(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VistaPagos(hijoID: hijoIdSeleccionado!),
                            ),
                          );
                        },
                      ),
                      DashboardButton(
                        icon: Icons.school,
                        label: 'Académico',
                        description:
                            'Sigue el progreso escolar y notas del menor',
                        color: Colors.purple,
                        onPressed: () {
                          if (sinHijos) {
                            mostrarMensajeSeleccion(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AcademicoScreen(hijoID: hijoIdSeleccionado!),
                            ),
                          );
                        },
                      ),
                      DashboardButton(
                        icon: Icons.child_care,
                        label: 'Gestión de Hijos',
                        description:
                            'Añade hijos a tu app para empezar a gestionarlos',
                        color: Colors.teal,
                        highlight: sinHijos, // nuevo parámetro visual
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HijosScreen()),
                          );
                          cargarHijos();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class DashboardButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;
  final bool highlight;

  const DashboardButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
    this.highlight = false,
  });

  @override
  _DashboardButtonState createState() => _DashboardButtonState();
}

class _DashboardButtonState extends State<DashboardButton>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  late AnimationController _controller;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    _backgroundAnimation = ColorTween(
      begin: Colors.blue[200],
      end: Colors.white,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.highlight) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DashboardButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.highlight && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleExpanded() {
    setState(() => expanded = !expanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          width: MediaQuery.of(context).size.width / 2 - 26,
          margin: EdgeInsets.only(
            bottom: 16,
          ), // espacio inferior para evitar solapamiento
          padding: widget.highlight ? EdgeInsets.all(2) : EdgeInsets.zero,
          decoration: widget.highlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Color(0xFF3A86FF), Color(0xFFFF5E9D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: widget.highlight
                  ? _backgroundAnimation.value ?? Color(0xFF1B263B)
                  : Color(0xFF1B263B),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onPressed,
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 1), // para alinear el icono centrado
                        Icon(widget.icon, size: 38, color: widget.color),
                        GestureDetector(
                          onTap: toggleExpanded,
                          child: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        color: Colors.white70,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
