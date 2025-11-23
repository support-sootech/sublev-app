class ModoConservacaoModel {
  final int? id;
  final String? descricao;

  ModoConservacaoModel({this.id, this.descricao});

  factory ModoConservacaoModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return ModoConservacaoModel(
      id: parseId(json['id'] ?? json['id_modo_conservacao']),
      descricao: json['descricao']?.toString() ??
          json['ds_descricao']?.toString() ??
          json['nome']?.toString(),
    );
  }
}
