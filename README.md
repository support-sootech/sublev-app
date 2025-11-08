# ootech

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Versões do Android
Versão Mínima (minSdkVersion): O arquivo android/app/build.gradle, que define essa versão, não foi fornecido. No entanto, considerando as tecnologias e dependências usadas (como Kotlin Coroutines e as permissões mais recentes), é muito provável que a versão mínima seja a API 21 (Android 5.0 Lollipop). Este é um padrão comum em projetos Flutter modernos para garantir um bom alcance de dispositivos.

Versão Alvo/Máxima (targetSdkVersion): O código nativo em MainActivity.kt lida com permissões específicas para o Android 12 (API 31), o que indica que a versão alvo do seu app é pelo menos a API 31. Para publicar na Google Play Store, o ideal é que essa versão seja ainda mais recente (API 33 ou 34), mas o app está preparado para funcionar corretamente em versões modernas do Android.
