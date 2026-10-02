enum EstadoPartido {
  programado,
  enCurso,
  terminado,
  cancelado,
  suspendido;

  static EstadoPartido fromString(String value) =>
      EstadoPartido.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => EstadoPartido.programado,
      );
}
