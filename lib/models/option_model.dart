class OptionModel {
  final int id;
  final String descricao;
  final int? idEmpresa; // usado para filtrar fabricantes vinculados à empresa
  final int? idTiposPessoas; // permite identificar se é fornecedor (3), fabricante (2), etc.

  const OptionModel({
    required this.id,
    required this.descricao,
    this.idEmpresa,
    this.idTiposPessoas,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final descricao = json['descricao'] ??
        json['nome'] ??
        json['nm_pessoa'] ??
        json['title'] ??
        '';

    return OptionModel(
      id: parseId(
        json['id'] ??
            json['id_pessoas'] ??
            json['id_materiais_categorias'] ??
            json['id_materiais_marcas'],
      ),
      descricao: descricao.toString(),
      idEmpresa: json['id_empresas'] == null ? null : parseId(json['id_empresas']),
      idTiposPessoas: json['id_tipos_pessoas'] == null ? null : parseId(json['id_tipos_pessoas']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OptionModel(id=$id, descricao=$descricao)';
}
