String removerAcentuacoes(String texto) {
  if (texto.isEmpty) {
    return texto;
  }

  // Mapeamento de caracteres acentuados para suas versões sem acento
  String comAcentos = "áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ";
  String semAcentos = "aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC";

  // Cria um RegExp para buscar todos os caracteres acentuados de uma vez
  // O '[${RegExp.escape(comAcentos)}]' cria uma classe de caracteres a partir da string comAcentos
  RegExp exp = RegExp('[${RegExp.escape(comAcentos)}]');

  // Usa replaceAllMapped para substituir cada caractere encontrado
  String textoSemAcentos = texto.replaceAllMapped(exp, (match) {
    // Encontra o índice do caractere acentuado na string comAcentos
    int index = comAcentos.indexOf(match.group(0)!);
    // Retorna o caractere correspondente da string semAcentos
    return (index != -1) ? semAcentos[index] : match.group(0)!;
  });

  return textoSemAcentos;
}

enum AcaoMateriaisFracionadoVencimento {
  vencem_hoje,
  vencem_amanha,
  vencem_semana,
  vencem_mais_1_semana,
}

extension acaoMateriaisFracionadoVencimentoExtension
    on AcaoMateriaisFracionadoVencimento {
  String get toStringAcao {
    switch (this) {
      case AcaoMateriaisFracionadoVencimento.vencem_hoje:
        return 'btn_vencem_hoje';
      case AcaoMateriaisFracionadoVencimento.vencem_amanha:
        return 'btn_vencem_amanha';
      case AcaoMateriaisFracionadoVencimento.vencem_semana:
        return 'btn_vencem_semana';
      case AcaoMateriaisFracionadoVencimento.vencem_mais_1_semana:
        return 'btn_vencem_mais_1_semana';
    }
  }
}

enum SizeLabelPrint { $50_x_30, $50_x_50 }

extension sizeLabelPrintExtension on SizeLabelPrint {
  Map<String, dynamic> get toSizeLabelPrintValues {
    switch (this) {
      case SizeLabelPrint.$50_x_30:
        return {
          "title": "50 x 30",
          'width': 390.00,
          'height': 250.00,
          'targetWidthPx': 400,
          'targetHeightPx': 400,
          'labelWidth': 50,
          'labelHeight': 30,
        };
      case SizeLabelPrint.$50_x_50:
        return {
          "title": "50 x 50",
          'width': 390.00,
          'height': 380.00,
          'targetWidthPx': 400,
          'targetHeightPx': 240,
          'labelWidth': 50,
          'labelHeight': 50,
        };
    }
  }
}
