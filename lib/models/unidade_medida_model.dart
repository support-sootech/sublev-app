class UnidadeMedidaModel {
  final int? id;
  final String? descricao;
  final String? sigla;

  UnidadeMedidaModel({this.id, this.descricao, this.sigla});

  factory UnidadeMedidaModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return UnidadeMedidaModel(
      id: parseId(json['id'] ?? json['id_unidades_medidas']),
      descricao: json['descricao']?.toString() ??
          json['ds_unidade']?.toString() ??
          json['nome']?.toString(),
      sigla: json['sigla']?.toString(),
    );
  }
}
