import 'package:ootech/models/etiqueta_model.dart';

class VencimentoCounts {
  final int hoje;
  final int amanha;
  final int ate7;
  final int mais7;
  VencimentoCounts({required this.hoje, required this.amanha, required this.ate7, required this.mais7});
  factory VencimentoCounts.fromJson(Map<String,dynamic> json){
    int _p(dynamic v)=> v is int? v : int.tryParse(v.toString())??0;
    return VencimentoCounts(
      hoje: _p(json['vencem_hoje']),
      amanha: _p(json['vencem_amanha']),
      ate7: _p(json['vencem_semana']),
      mais7: _p(json['vencem_mais_1_semana']),
    );
  }
}

class VencimentoDetalhe {
  final VencimentoCounts counts;
  final String scope; // hoje|amanha|ate7|mais7|all
  final List<EtiquetaModel> lista; // lista opcional do escopo
  VencimentoDetalhe({required this.counts, required this.scope, required this.lista});
}
