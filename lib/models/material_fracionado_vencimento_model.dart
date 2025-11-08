class MaterialFracionadoVencimentoModel {
  int? vencemHoje = 0;
  int? vencemAmanha = 0;
  int? vencemSemana = 0;
  int? vencemMais1Semana = 0;

  MaterialFracionadoVencimentoModel({
    this.vencemHoje,
    this.vencemAmanha,
    this.vencemSemana,
    this.vencemMais1Semana,
  });

  MaterialFracionadoVencimentoModel.fromJson(Map<String, dynamic> json) {
    vencemHoje = json['vencem_hoje'];
    vencemAmanha = json['vencem_amanha'];
    vencemSemana = json['vencem_semana'];
    vencemMais1Semana = json['vencem_mais_1_semana'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['vencem_hoje'] = vencemHoje;
    data['vencem_amanha'] = vencemAmanha;
    data['vencem_semana'] = vencemSemana;
    data['vencem_mais_1_semana'] = vencemMais1Semana;
    return data;
  }
}
