import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/relatorio_recebimento_controller.dart';
import 'package:ootech/models/relatorio_recebimento_item.dart';

class RelatorioRecebimentoPage extends StatelessWidget {
  RelatorioRecebimentoPage({super.key});
  final ctrl = Get.put(RelatorioRecebimentoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recebimento de Materiais')),
      body: Obx(() {
        if (ctrl.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.erro.value != null) {
          return Center(
            child: Text(ctrl.erro.value!, style: const TextStyle(color: Colors.red)),
          );
        }
        if (ctrl.itens.isEmpty) {
          return const Center(child: Text('Nenhum registro no período.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ctrl.carregar(refresh: true),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ctrl.itens.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = ctrl.itens[index];
              return _ItemWidget(item: item);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ctrl.carregar(refresh: true),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  final RelatorioRecebimentoItem item;
  const _ItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.descricao ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _kv('Cadastro', item.dhCadastro),
                _kv('Vencimento', item.dtVencimento),
                _kv('Qtd', item.quantidade),
                _kv('Fornecedor', item.nmFornecedor),
                _kv('Embalagem', item.dsEmbalagemCondicoes),
                _kv('Responsável', (item.nmResponsavel == null || item.nmResponsavel!.isEmpty) ? '—' : item.nmResponsavel),
                _kv('Lote', item.lote),
                _kv('Nota', item.nroNota),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String? v) {
    return SizedBox(
      width: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$k: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(v == null || v.isEmpty ? '-' : v, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
