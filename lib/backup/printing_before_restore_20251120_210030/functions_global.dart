import 'package:intl/intl.dart';

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

/// Formata um valor de peso para envio ao servidor seguindo o padrão brasileiro:
/// - inteiros são enviados sem casas decimais: "100"
/// - decimais usam vírgula: "3,5" ou "10,25"
String formatPesoForServer(dynamic value) {
  if (value == null) return '';

  double? v;
  if (value is String) {
    var s = value.trim();
    if (s.isEmpty) return '';
    // Aceitar formatos com ponto ou vírgula e remover separador de milhares
    // Ex.: "1.000,5" -> "1000,5" -> parse -> 1000.5
    s = s.replaceAll('.', '');
    s = s.replaceAll(',', '.');
    v = double.tryParse(s);
  } else if (value is num) {
    v = value.toDouble();
  } else {
    try {
      v = double.tryParse(value.toString());
    } catch (_) {
      v = null;
    }
  }

  if (v == null) return value.toString();
  if (v % 1 == 0) return v.toInt().toString();

  final fmt = NumberFormat('#.######', 'pt_BR');
  return fmt.format(v);
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
          // Dimensões físicas aproximadas em pixels (203 DPI)
          'width': 390.00, // legado: largura usada pelo plugin
          'height': 250.00, // legado: altura usada pelo plugin
          // Dimensões alvo derivadas de (mm/25.4)*203
          'targetWidthPx': 400, // captura permanece quadrada para firmware
          'targetHeightPx': 400, // evita replicação/rotação inesperada
          'labelWidth': 50,
          'labelHeight': 30,
        };
      case SizeLabelPrint.$50_x_50:
        return {
          "title": "50 x 50",
          'width': 390.00,
          'height': 380.00,
          'targetWidthPx': 400, // (50mm)
          'targetHeightPx': 400, // (50mm)
          'labelWidth': 50,
          'labelHeight': 50,
        };
    }
  }
}
