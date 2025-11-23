import 'package:ootech/config/functions_global.dart';

class EtiquetaAvulsaRequest {
  final String descricao;
  final DateTime? validade;
  final double peso;
  final int idUnidadesMedidas;
  final int idModoConservacao;
  final int quantidade;

  EtiquetaAvulsaRequest({
    required this.descricao,
    required this.validade,
    required this.peso,
    required this.idUnidadesMedidas,
    required this.idModoConservacao,
    required this.quantidade,
  });

  Map<String, dynamic> toJson() {
    String? validadeIso;
    if (validade != null) {
      validadeIso =
          '${validade!.year.toString().padLeft(4, '0')}-'
          '${validade!.month.toString().padLeft(2, '0')}-'
          '${validade!.day.toString().padLeft(2, '0')}';
    }

      // Serializa peso usando formato brasileiro (inteiro -> "100", decimal -> "3,5")
      final pesoStr = formatPesoForServer(peso);

    return {
      'descricao': descricao,
      'validade': validadeIso,
      'peso': pesoStr,
      'id_unidades_medidas': idUnidadesMedidas,
      'id_modo_conservacao': idModoConservacao,
      'quantidade': quantidade,
    };
  }
}
