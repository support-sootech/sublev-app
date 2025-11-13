class UnidadeMedidaModel {
  int? idUnidadesMedidas;
  String? descricao;

  UnidadeMedidaModel({this.idUnidadesMedidas, this.descricao});

  UnidadeMedidaModel.fromJson(Map<String, dynamic> json) {
    idUnidadesMedidas = json['id_unidades_medidas'];
    descricao = json['descricao'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_unidades_medidas'] = idUnidadesMedidas;
    data['descricao'] = descricao;
    return data;
  }
}
