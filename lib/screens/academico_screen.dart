import 'package:flutter/material.dart';
import '../widgets/academico/vista_notas.dart';
import '../widgets/academico/vista_examenes.dart';
import '../widgets/academico/vista_matricula.dart';
import '../widgets/academico/vista_mensajes.dart';
import '../widgets/academico/vista_actividades.dart';

class AcademicoScreen extends StatefulWidget {
  final String hijoID;
  const AcademicoScreen({required this.hijoID});

  @override
  _AcademicoScreenState createState() => _AcademicoScreenState();
}

class _AcademicoScreenState extends State<AcademicoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final offsetX = screenWidth < 400
        ? -30.0
        : screenWidth < 600
            ? -20.0
            : -8.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Académico',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Transform.translate(
            offset: Offset(offsetX, 0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.greenAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Notas'),
                Tab(text: 'Exámenes'),
                Tab(text: 'Matrícula'),
                Tab(text: 'Mensajes'),
                Tab(text: 'Excursiones y actividades'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          VistaNotas(hijoID: widget.hijoID),
          VistaExamenes(hijoID: widget.hijoID),
          VistaMatricula(hijoID: widget.hijoID),
          VistaMensajes(hijoID: widget.hijoID),
          VistaActividades(hijoID: widget.hijoID),
        ],
      ),
    );
  }
}