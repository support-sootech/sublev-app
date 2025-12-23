class TipoPessoaModel {
  final int? id;
  final String? descricao;
  final String? status;

  TipoPessoaModel({this.id, this.descricao, this.status});

  factory TipoPessoaModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return TipoPessoaModel(
      id: parseId(json['id'] ?? json['id_tipos_pessoas']),
      descricao: json['descricao']?.toString(),
      status: json['status']?.toString() ?? 'A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id_tipos_pessoas': id,
      'descricao': descricao,
      'status': status,
    };
  }

  TipoPessoaModel copyWith({
    int? id,
    String? descricao,
    String? status,
  }) {
    return TipoPessoaModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
    );
  }
}
