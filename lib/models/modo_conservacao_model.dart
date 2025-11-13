class ModoConservacaoModel {
  final int? id;
  final String? descricao;
  final String? status;

  ModoConservacaoModel({this.id, this.descricao, this.status});

  factory ModoConservacaoModel.fromJson(Map<String, dynamic> j) => ModoConservacaoModel(
    id: j['id'] is int ? j['id'] : int.tryParse('${j['id'] ?? ''}'),
    descricao: j['descricao'],
    status: j['status'],
  );
}