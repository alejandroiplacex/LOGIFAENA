import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';
import 'widgets/sync_queue_status.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late AppSettings settings;
  late final TextEditingController companyController;
  late final TextEditingController taxIdController;
  late final TextEditingController siteController;
  late final TextEditingController coordinatorController;
  late final TextEditingController roleController;
  late final TextEditingController apiController;
  bool saving = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode(
    debugLabel: 'settings_keyboard_scroll',
  );

  @override
  void initState() {
    super.initState();
    settings = SettingsRepository.instance.load();
    companyController = TextEditingController(text: settings.companyName);
    taxIdController = TextEditingController(text: settings.taxId);
    siteController = TextEditingController(text: settings.defaultSite);
    coordinatorController = TextEditingController(
      text: settings.coordinatorName,
    );
    roleController = TextEditingController(text: settings.coordinatorRole);
    apiController = TextEditingController(text: settings.apiBaseUrl);
  }

  @override
  void dispose() {
    companyController.dispose();
    taxIdController.dispose();
    siteController.dispose();
    coordinatorController.dispose();
    roleController.dispose();
    apiController.dispose();
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final updated = settings.copyWith(
      companyName: companyController.text.trim(),
      taxId: taxIdController.text.trim(),
      defaultSite: siteController.text.trim(),
      coordinatorName: coordinatorController.text.trim(),
      coordinatorRole: roleController.text.trim(),
      apiBaseUrl: apiController.text.trim(),
    );
    await SettingsRepository.instance.save(updated);
    if (!mounted) return;
    setState(() {
      settings = updated;
      saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada correctamente.')),
    );
  }

  Future<void> restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar configuración'),
        content: const Text(
          'Se restaurarán los parámetros generales. Los datos operacionales no serán eliminados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final defaults = AppSettings.defaults();
    await SettingsRepository.instance.restoreDefaults();
    if (!mounted) return;
    setState(() {
      settings = defaults;
      companyController.text = defaults.companyName;
      taxIdController.text = defaults.taxId;
      siteController.text = defaults.defaultSite;
      coordinatorController.text = defaults.coordinatorName;
      roleController.text = defaults.coordinatorRole;
      apiController.text = defaults.apiBaseUrl;
    });
  }

  KeyEventResult _handleScrollKeys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_scrollController.hasClients) {
      return KeyEventResult.ignored;
    }

    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext != null &&
        focusedContext.findAncestorWidgetOfExactType<EditableText>() != null) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final position = _scrollController.position;
    final pageStep = position.viewportDimension * 0.85;
    double? target;

    if (key == LogicalKeyboardKey.arrowDown) {
      target = position.pixels + 56;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target = position.pixels - 56;
    } else if (key == LogicalKeyboardKey.pageDown) {
      target = position.pixels + pageStep;
    } else if (key == LogicalKeyboardKey.pageUp) {
      target = position.pixels - pageStep;
    } else if (key == LogicalKeyboardKey.home) {
      target = position.minScrollExtent;
    } else if (key == LogicalKeyboardKey.end) {
      target = position.maxScrollExtent;
    }

    if (target == null) return KeyEventResult.ignored;

    _scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleScrollKeys,
      child: ColoredBox(
        color: AppColors.background,
        child: Form(
          key: _formKey,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              children: [
                _Header(onSave: saving ? null : save),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 980;
                    final cards = [
                      _SectionCard(
                        title: 'Empresa y operación',
                        subtitle: 'Identificación principal de la instalación.',
                        icon: Icons.business,
                        children: [
                          _field(
                            companyController,
                            'Nombre de la empresa',
                            true,
                          ),
                          _field(taxIdController, 'RUT de la empresa', false),
                          _field(siteController, 'Faena predeterminada', true),
                        ],
                      ),
                      _SectionCard(
                        title: 'Usuario coordinador',
                        subtitle: 'Datos visibles en la cabecera del sistema.',
                        icon: Icons.badge,
                        children: [
                          _field(coordinatorController, 'Nombre', true),
                          _field(roleController, 'Cargo o función', true),
                        ],
                      ),
                      _SectionCard(
                        title: 'Operación local',
                        subtitle: 'Preferencias de respaldo y avisos.',
                        icon: Icons.storage,
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Notificaciones operacionales'),
                            subtitle: const Text(
                              'Mostrar avisos generados por el motor logístico.',
                            ),
                            value: settings.notificationsEnabled,
                            onChanged: (value) => setState(
                              () => settings = settings.copyWith(
                                notificationsEnabled: value,
                              ),
                            ),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Respaldo automático local'),
                            subtitle: const Text(
                              'Preparado para integrarse con el servicio de respaldos.',
                            ),
                            value: settings.automaticBackup,
                            onChanged: (value) => setState(
                              () => settings = settings.copyWith(
                                automaticBackup: value,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _SectionCard(
                        title: 'Base de datos local',
                        subtitle:
                            'Estado verificable del almacenamiento SQLite.',
                        icon: Icons.dns,
                        children: [_DatabaseStatus()],
                      ),
                      _SectionCard(
                        title: 'Servidor y sincronización',
                        subtitle:
                            'Parámetros preparados para la futura API empresarial.',
                        icon: Icons.cloud_sync,
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Sincronización automática'),
                            subtitle: const Text(
                              'Se habilitará cuando exista un servidor configurado.',
                            ),
                            value: settings.automaticSync,
                            onChanged: (value) => setState(
                              () => settings = settings.copyWith(
                                automaticSync: value,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<int>(
                            value: settings.syncIntervalMinutes,
                            decoration: const InputDecoration(
                              labelText: 'Intervalo de sincronización',
                            ),
                            items: const [5, 15, 30, 60]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text('$value minutos'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null)
                                setState(
                                  () => settings = settings.copyWith(
                                    syncIntervalMinutes: value,
                                  ),
                                );
                            },
                          ),
                          const SizedBox(height: 12),
                          _field(
                            apiController,
                            'URL base de API',
                            false,
                            hint: 'https://servidor/api',
                          ),
                          const SizedBox(height: 8),
                          const SyncQueueStatus(),
                        ],
                      ),
                    ];

                    if (!twoColumns) {
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    }

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: cards
                          .map(
                            (card) => SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'LogiFaena Enterprise 1.3.1+1301 · Sprint 15.1',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: restoreDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restaurar valores'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    bool required, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Campo obligatorio'
                  : null
            : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onSave;

  const _Header({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración empresarial',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Administra parámetros locales y deja preparada la conexión con servicios centrales.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save),
          label: const Text('Guardar cambios'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE7F0FC),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DatabaseStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final database = DatabaseService.instance;
    final sizeKb = database.databaseSizeBytes / 1024;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: database.databaseExists
            ? const Color(0xFFEAF7EF)
            : const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: database.databaseExists
              ? const Color(0xFFA8D9B9)
              : const Color(0xFFFFC98D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                database.databaseExists
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: database.databaseExists
                    ? const Color(0xFF21844A)
                    : AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  database.isSqlite
                      ? database.databaseExists
                            ? 'SQLite activo y archivo creado'
                            : 'SQLite configurado, archivo no detectado'
                      : 'Modo web: almacenamiento compatible',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Ruta de almacenamiento',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          SelectableText(
            database.databasePath,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          if (database.databaseExists) ...[
            const SizedBox(height: 8),
            Text(
              'Tamaño actual: ${sizeKb.toStringAsFixed(1)} KB',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
