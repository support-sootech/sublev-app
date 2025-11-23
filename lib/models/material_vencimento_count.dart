class MaterialVencimentoCount {
  final int vencemHoje;
  final int vencemAmanha;
  final int vencemSemana;
  final int vencemMaisUmaSemana;

  MaterialVencimentoCount({
    required this.vencemHoje,
    required this.vencemAmanha,
    required this.vencemSemana,
    required this.vencemMaisUmaSemana,
  });

  factory MaterialVencimentoCount.fromJson(Map<String, dynamic> json) {
    int _parse(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }
    return MaterialVencimentoCount(
      vencemHoje: _parse(json['vencem_hoje']),
      vencemAmanha: _parse(json['vencem_amanha']),
      vencemSemana: _parse(json['vencem_semana']),
      vencemMaisUmaSemana: _parse(json['vencem_mais_1_semana']),
    );
  }
}
