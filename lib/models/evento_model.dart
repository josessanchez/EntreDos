import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Evento {
  final String id;
  final String titulo; // Título del evento
  final String tipo; // Ejemplo: 'Médico', 'Actividad', 'Cumpleaños'
  final DateTime fecha; // Fecha asignada al evento
  final String hijoId; // ID del hijo relacionado
  final String hijoNombre; // Nombre del hijo
  final String creadorUid; // UID del progenitor que lo creó
  final String? documentoUrl; // URL del adjunto si existe
  final String? documentoNombre; // Nombre del archivo adjunto
  final String? notas; // Notas del evento

  Evento({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.fecha,
    required this.hijoId,
    required this.hijoNombre,
    required this.creadorUid,
    this.documentoUrl,
    this.documentoNombre,
    this.notas,
  });

  factory Evento.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evento(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      tipo: data['tipo'] ?? '',
      fecha: (data['fecha'] is Timestamp)
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      hijoId: data['hijoId'] ?? '',
      hijoNombre: data['hijoNombre'] ?? '',
      creadorUid: data['creadorUid'] ?? '',
      documentoUrl: data['documentoUrl'],
      documentoNombre: data['documentoNombre'],
      notas: data['notas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'tipo': tipo,
      'fecha': Timestamp.fromDate(fecha),
      'hijoId': hijoId,
      'hijoNombre': hijoNombre,
      'creadorUid': creadorUid,
      'documentoUrl': documentoUrl,
      'documentoNombre': documentoNombre,
      'notas': notas,
    };
  }

  Evento copyWith({
    String? id,
    String? titulo,
    String? tipo,
    DateTime? fecha,
    String? hijoId,
    String? hijoNombre,
    String? creadorUid,
    String? documentoUrl,
    String? documentoNombre,
    String? notas,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      hijoId: hijoId ?? this.hijoId,
      hijoNombre: hijoNombre ?? this.hijoNombre,
      creadorUid: creadorUid ?? this.creadorUid,
      documentoUrl: documentoUrl ?? this.documentoUrl,
      documentoNombre: documentoNombre ?? this.documentoNombre,
      notas: notas ?? this.notas,
    );
  }
}