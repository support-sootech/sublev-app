/// Mapeia mensagens técnicas de erro de impressão para textos amigáveis em PT-BR.
/// Mantém fallback caso não reconheça o padrão.
String mapPrintError(String raw) {
  if (raw.isEmpty) return 'Erro desconhecido.';
  final lower = raw.toLowerCase();

  if (lower.contains('not connected') || lower.contains('impressora não conectada')) {
    return 'Impressora não conectada. Verifique a conexão antes de imprimir.';
  }
  if (lower.contains('bluetooth') && lower.contains('off')) {
    return 'Bluetooth desativado. Ative o Bluetooth do aparelho.';
  }
  if (lower.contains('timeout')) {
    return 'Tempo de resposta excedido. Reaproxime o aparelho da impressora e tente novamente.';
  }
  if (lower.contains('bytes length') || lower.contains('unexpected length')) {
    return 'Falha no envio dos dados da etiqueta. Tente reenviar.';
  }
  if (lower.contains('permission') || lower.contains('permiss')) {
    return 'Permissão de Bluetooth ou localização ausente. Conceda as permissões e tente de novo.';
  }
  if (lower.contains('queue') && lower.contains('busy')) {
    return 'Impressão em andamento. Aguarde a finalização da etiqueta atual.';
  }
  if (lower.contains('invalid size') || lower.contains('dimension')) {
    return 'Dimensão da etiqueta inválida para o modelo selecionado.';
  }
  if (lower.contains('printer') && lower.contains('busy')) {
    return 'A impressora está ocupada. Aguarde liberação e tente novamente.';
  }
  if (lower.contains('paper') && lower.contains('absent')) {
    return 'Papel não detectado. Verifique o carregamento da etiqueta.';
  }
  if (lower.contains('head') && lower.contains('open')) {
    return 'Cabeça de impressão aberta. Feche a impressora corretamente.';
  }
  if (lower.contains('out of paper')) {
    return 'Sem mídia/etiqueta. Reabasteça e tente novamente.';
  }
  if (lower.contains('low battery')) {
    return 'Bateria fraca na impressora. Recarregue para evitar falhas.';
  }
  // Fallback genérico
  return 'Erro na impressão: ${raw.trim()}';
}
