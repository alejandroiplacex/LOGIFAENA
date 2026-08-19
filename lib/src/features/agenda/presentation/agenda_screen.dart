import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../data/agenda_service.dart';
import '../domain/agenda_event.dart';
import 'widgets/agenda_event_card.dart';

enum AgendaRange { today, upcoming, all }

extension AgendaRangeLabel on AgendaRange {
  String get label {
    switch (this) {
      case AgendaRange.today:
        return 'Hoy';
      case AgendaRange.upcoming:
        return 'Próximos';
      case AgendaRange.all:
        return 'Todos';
    }
  }
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final agendaService = AgendaService.instance;
  final workerRepository = InMemoryWorkerRepository.instance;
  final searchController = TextEditingController();

  AgendaRange selectedRange = AgendaRange.upcoming;
  AgendaEventType? selectedType;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<AgendaEvent> get events {
    final query = searchController.text.trim().toLowerCase();
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final endToday = startToday.add(const Duration(days: 1));

    return agendaService.getEvents().where((event) {
      final worker = _worker(event.workerId);
      final workerName = worker?.fullName.toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          workerName.contains(query) ||
          event.title.toLowerCase().contains(query) ||
          event.subtitle.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query);

      final matchesType = selectedType == null || event.type == selectedType;

      final matchesRange = switch (selectedRange) {
        AgendaRange.today =>
          !event.dateTime.isBefore(startToday) &&
              event.dateTime.isBefore(endToday),
        AgendaRange.upcoming => !event.dateTime.isBefore(startToday),
        AgendaRange.all => true,
      };

      return matchesSearch && matchesType && matchesRange;
    }).toList();
  }

  Worker? _worker(String id) {
    for (final worker in workerRepository.getAll()) {
      if (worker.id == id) return worker;
    }
    return null;
  }

  String formatDate(DateTime value) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];

    return '${value.day.toString().padLeft(2, '0')} '
        '${months[value.month - 1]} ${value.year}';
  }

  Map<DateTime, List<AgendaEvent>> groupedEvents() {
    final grouped = <DateTime, List<AgendaEvent>>{};

    for (final event in events) {
      final day = DateTime(event.date.year, event.date.month, event.date.day);
      grouped.putIfAbsent(day, () => []).add(event);
    }

    return grouped;
  }

  int countStatus(AgendaEventStatus status) {
    return agendaService
        .getEvents()
        .where((event) => event.status == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedEvents();
    final days = grouped.keys.toList()..sort();

    return Column(
      children: [
        _summary(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              children: [
                _filters(),
                const SizedBox(height: 16),
                Expanded(
                  child: days.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay eventos para los filtros seleccionados.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: days.length,
                          itemBuilder: (context, dayIndex) {
                            final day = days[dayIndex];
                            final dayEvents = grouped[day]!;
                            dayEvents.sort(
                              (a, b) => a.dateTime.compareTo(b.dateTime),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        formatDate(day),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Chip(
                                        label: Text(
                                          '${dayEvents.length} evento(s)',
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...dayEvents.map(
                                    (event) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: AgendaEventCard(
                                        event: event,
                                        worker: _worker(event.workerId),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    final all = agendaService.getEvents();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayCount = all.where((event) {
      return !event.dateTime.isBefore(today) &&
          event.dateTime.isBefore(tomorrow);
    }).length;

    final upcomingCount = all.where((event) {
      return !event.dateTime.isBefore(today);
    }).length;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 900
              ? (constraints.maxWidth - 48) / 4
              : (constraints.maxWidth - 16) / 2;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _summaryCard(
                width: itemWidth,
                title: 'Eventos hoy',
                value: todayCount.toString(),
                icon: Icons.today,
                color: Colors.indigo,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Próximos',
                value: upcomingCount.toString(),
                icon: Icons.upcoming,
                color: Colors.blue,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Confirmados',
                value: countStatus(AgendaEventStatus.confirmed).toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
              _summaryCard(
                width: itemWidth,
                title: 'Pendientes',
                value: countStatus(AgendaEventStatus.pending).toString(),
                icon: Icons.warning_amber,
                color: AppColors.warning,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        final search = TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Buscar trabajador, evento, hotel, ruta o empresa',
            prefixIcon: Icon(Icons.search),
          ),
        );

        final range = SegmentedButton<AgendaRange>(
          segments: AgendaRange.values
              .map(
                (item) => ButtonSegment(value: item, label: Text(item.label)),
              )
              .toList(),
          selected: {selectedRange},
          onSelectionChanged: (value) {
            setState(() => selectedRange = value.first);
          },
        );

        final type = DropdownButtonFormField<AgendaEventType?>(
          initialValue: selectedType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tipo de evento',
            prefixIcon: Icon(Icons.filter_alt),
          ),
          items: [
            const DropdownMenuItem<AgendaEventType?>(
              value: null,
              child: Text('Todos los tipos'),
            ),
            ...AgendaEventType.values.map(
              (item) => DropdownMenuItem<AgendaEventType?>(
                value: item,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => selectedType = value);
          },
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              range,
              const SizedBox(height: 12),
              type,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: 12),
            range,
            const SizedBox(width: 12),
            Expanded(child: type),
          ],
        );
      },
    );
  }
}
