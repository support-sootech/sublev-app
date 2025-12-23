
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/catalogo_avulso_controller.dart';
import 'package:ootech/models/catalogo_avulso_model.dart';
import 'package:ootech/views/etiqueta_avulsa_page.dart';
import 'package:ootech/views/widgets/home/app_bar_linear_gradient_widget.dart';

class CatalogoAvulsoPage extends StatefulWidget {
  const CatalogoAvulsoPage({super.key});

  @override
  State<CatalogoAvulsoPage> createState() => _CatalogoAvulsoPageState();
}

class _CatalogoAvulsoPageState extends State<CatalogoAvulsoPage> {
  final _ctrl = Get.put(CatalogoAvulsoController());
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Garante que o filtro esteja limpo ao entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchCtrl.clear();
        _ctrl.filtroBusca.value = ''; // Dispara listener que recarrega lista
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _novoItem() async {
    // Modo novo (comum)
    await Get.to(() => const EtiquetaAvulsaPage(
          isCatalogoMode: true,
          modo: 'novo',
        ));
    _ctrl.carregar();
  }

  void _abrirItem(CatalogoAvulsoModel item) async {
      // Logica: se favorito, 'gerar_favorito' (travado). Se nao, 'gerar_comum' (livre).
      final modo = item.favorito ? 'gerar_favorito' : 'gerar_comum';
      await Get.to(() => EtiquetaAvulsaPage(
          isCatalogoMode: true,
          catalogoItem: item,
          modo: modo,
      ));
      _ctrl.carregar();
  }
  
  void _editarItem(CatalogoAvulsoModel item) async {
      // Edicao do catalogo apenas
      await Get.to(() => EtiquetaAvulsaPage(
          isCatalogoMode: true,
          catalogoItem: item,
          modo: 'editar_catalogo',
      ));
      _ctrl.carregar();
  }

  void _excluirItem(CatalogoAvulsoModel item) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Excluir Item'),
        content: Text('Deseja excluir "${item.descricao}" do catálogo?'),
        actions: [
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx)),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'), 
                onPressed: () async {
                    Navigator.pop(ctx);
                    await _ctrl.excluir(item.id!);
                }
            ),
        ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catálogo Avulso', style: TextStyle(fontSize: 20)),
          flexibleSpace: AppBarLinearGradientWidget(),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _ctrl.carregar(),
            )
          ],
        ),
        body: Column(
          children: [
            // Barra de busca igual MateriaisListPage
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Buscar por descrição, peso ou modo...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _ctrl.filtroBusca.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _ctrl.filtroBusca.value = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => _ctrl.filtroBusca.value = v,
              ),
            ),
            
            Expanded(
              child: Obx(() {
                if (_ctrl.isLoading.value) {
                   return const Center(child: CircularProgressIndicator());
                }
                if (_ctrl.lista.isEmpty) {
                   return const Center(child: Text('Nenhum item encontrado no catálogo.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _ctrl.lista.length,
                  itemBuilder: (ctx, i) {
                    final item = _ctrl.lista[i];
                    
                    // Definições visuais
                    final descricao = item.descricao;
                    // Formatacao Inteligente do Peso
                    final p = item.peso ?? 0.0;
                    final pesoLabel = (p % 1 == 0) ? p.toInt().toString() : p.toString().replaceAll('.', ',');
                    
                    final unidLabel = item.dsUnidadeMedida ?? "-";
                    final modoLabel = item.dsModoConservacao ?? "-";
                    final vencLabel = "${item.qtdeDiasVencimento} dias";
                    
                    final isFavorito = item.favorito;
                    final statusColor = isFavorito ? Colors.amber.shade700 : Colors.grey;
                    final statusLabel = isFavorito ? "Favorito" : "Comum";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _abrirItem(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      descricao,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 0, 
                                    children: [
                                      // Botao Favorito Rapido (AJAX-like)
                                      IconButton(
                                        tooltip: isFavorito ? 'Remover Favorito' : 'Marcar Favorito',
                                        icon: Icon(isFavorito ? Icons.star : Icons.star_border, color: statusColor),
                                        onPressed: () => _ctrl.toggleFavorito(item),
                                      ),
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _editarItem(item),
                                      ),
                                      IconButton(
                                        tooltip: 'Excluir',
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _excluirItem(item),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Validade: +$vencLabel após geração',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Peso: $pesoLabel $unidLabel',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text('Modo: $modoLabel', style: const TextStyle(fontSize: 13)),
                              
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => _ctrl.toggleFavorito(item),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                         Icon(isFavorito ? Icons.star : Icons.star_border, size: 14, color: statusColor),
                                         const SizedBox(width: 4),
                                         Text(
                                           statusLabel,
                                           style: TextStyle(
                                             fontSize: 12,
                                             fontWeight: FontWeight.w600,
                                             color: statusColor,
                                           ),
                                         ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _novoItem,
          label: const Text('Novo'),
          icon: const Icon(Icons.add),
          // backgroundColor padrão do tema ou manter consistency
        ),
      ),
    );
  }
}
