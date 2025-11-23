class RelatorioRecebimentoItem {
  final Map<String, dynamic> _raw;
  String? dhCadastro; // dd/MM/yyyy HH:mm
  String? descricao;
  String? dtVencimento; // dd/MM/yyyy
  String? quantidade; // normalizada como string inteiro
  String? temperatura;
  String? sif;
  String? lote;
  String? nroNota;
  String? nmFornecedor;
  String? dsEmbalagemCondicoes;
  String? nmResponsavel;

  RelatorioRecebimentoItem.fromJson(Map<String, dynamic> json)
      : _raw = Map<String, dynamic>.from(json) {
    dhCadastro = _parseString(json['dh_cadastro']);
    descricao = _parseString(json['descricao']);
    dtVencimento = _parseString(json['dt_vencimento']);
    quantidade = _parseString(json['quantidade']);
    temperatura = _parseString(json['temperatura']);
    sif = _parseString(json['sif']);
    lote = _parseString(json['lote']);
    nroNota = _parseString(json['nro_nota']);
    nmFornecedor = _parseString(json['nm_fornecedor']);
    dsEmbalagemCondicoes = _parseString(json['ds_embalagem_condicoes']);
    nmResponsavel = _parseString(json['nm_responsavel']);
  }

  String? _parseString(dynamic v) => v == null ? null : v.toString();

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_raw);
}
