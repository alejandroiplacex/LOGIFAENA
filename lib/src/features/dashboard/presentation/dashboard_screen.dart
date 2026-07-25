import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../agenda/data/agenda_service.dart';
import '../../../core/widgets/scroll_navigation_buttons.dart';
import '../../alerts/data/operational_alert_service.dart';
import '../../agenda/domain/agenda_event.dart';
import '../../hotels/data/hotel_repository.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../transfers/data/transfer_repository.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import 'widgets/alert_panel.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/kpi_card.dart';
import 'widgets/recent_activity_panel.dart';
import 'widgets/operational_health.dart';
import 'widgets/quick_actions.dart';
import 'widgets/status_banner.dart';
import 'widgets/worker_status_overview.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final ValueChanged<WorkerStatus> onOpenWorkerStatus;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenWorkerStatus,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _clock;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _scrollFocusNode = FocusNode(debugLabel: 'dashboardScroll');
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scrollController.dispose();
    _scrollFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workers = InMemoryWorkerRepository.instance.getAll();
    final tickets = InMemoryTicketRepository.instance.getAll();
    final hotels = InMemoryHotelRepository.instance.getAll();
    final transfers = InMemoryTransferRepository.instance.getAll();
    final events = AgendaService.instance.getEvents();

    final alerts = OperationalAlertService.instance.getAlerts();

    final totalChecks = workers.isEmpty ? 1 : workers.length * 3;
    final completedChecks = (totalChecks - alerts.length).clamp(0, totalChecks);
    final health = ((completedChecks / totalChecks) * 100).round();
    final todayEvents = events.where((event) => _sameDay(event.date, _now)).toList();
    final displayEvents = todayEvents.isNotEmpty ? todayEvents : events.take(5).toList();
    final arrivalsToday = events.where((event) =>
      _sameDay(event.date, _now) && event.type == AgendaEventType.ticket).length;

    return ColoredBox(
      color: const Color(0xFFF5F7FB),
      child: Stack(
        children: [
          Focus(
            focusNode: _scrollFocusNode,
            autofocus: true,
            onKeyEvent: _handleScrollKey,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _scrollFocusNode.requestFocus,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 20, 72, 96),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardHeader(now: _now, alertCount: alerts.length),
            const SizedBox(height: 18),
            StatusBanner(
              alertCount: alerts.length,
              activeWorkers: workers.length,
              arrivalsToday: arrivalsToday,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1250 ? 6 : width >= 850 ? 3 : width >= 520 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: width >= 1250 ? 1.18 : 1.35,
                children: [
                  KpiCard(title: 'PERSONAL', value: '${workers.length}', subtitle: 'Activos', icon: Icons.groups_rounded, color: const Color(0xFF2367F2), onTap: () => widget.onNavigate(1)),
                  KpiCard(title: 'LLEGADAS', value: '$arrivalsToday', subtitle: 'Hoy', icon: Icons.flight_land_rounded, color: const Color(0xFF16A36A), onTap: () => widget.onNavigate(2)),
                  KpiCard(title: 'PASAJES', value: '${tickets.length}', subtitle: 'Registrados', icon: Icons.airplane_ticket_rounded, color: const Color(0xFFFF7A1A), onTap: () => widget.onNavigate(3)),
                  KpiCard(title: 'HOTELES', value: '${hotels.length}', subtitle: 'Asignaciones', icon: Icons.apartment_rounded, color: const Color(0xFF7B3FF2), onTap: () => widget.onNavigate(4)),
                  KpiCard(title: 'TRASLADOS', value: '${transfers.length}', subtitle: 'Programados', icon: Icons.directions_bus_rounded, color: const Color(0xFF078AA5), onTap: () => widget.onNavigate(5)),
                  KpiCard(title: 'ALERTAS', value: '${alerts.length}', subtitle: 'Pendientes', icon: Icons.warning_amber_rounded, color: const Color(0xFFEF3340), onTap: () => widget.onNavigate(7)),
                ],
              );
            }),
            const SizedBox(height: 18),
            WorkerStatusOverview(
              workers: workers,
              onOpenWorkers: () => widget.onNavigate(1),
              onStatusSelected: widget.onOpenWorkerStatus,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 980;
              final left = Column(children: [
                RecentActivityPanel(
                  workers: workers,
                  tickets: tickets,
                  hotels: hotels,
                  transfers: transfers,
                  events: displayEvents,
                  onOpenAgenda: () => widget.onNavigate(2),
                ),
                const SizedBox(height: 18),
                OperationalHealth(value: health, alertCount: alerts.length),
              ]);
              final right = Column(children: [
                AlertPanel(alerts: alerts.take(3).toList(), onViewAll: () => widget.onNavigate(7)),
                const SizedBox(height: 18),
                QuickActions(onNavigate: widget.onNavigate),
              ]);
              if (!desktop) return Column(children: [left, const SizedBox(height: 18), right]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 5, child: left),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: right),
              ]);
            }),
          ],
        ),
                  ),
                ),
              ),
            ),
          ScrollNavigationButtons(controller: _scrollController),
        ],
      ),
    );
  }

  KeyEventResult _handleScrollKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_scrollController.hasClients) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final viewport = _scrollController.position.viewportDimension;
    double? target;

    if (key == LogicalKeyboardKey.arrowDown) {
      target = _scrollController.offset + 72;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target = _scrollController.offset - 72;
    } else if (key == LogicalKeyboardKey.pageDown) {
      target = _scrollController.offset + viewport * 0.85;
    } else if (key == LogicalKeyboardKey.pageUp) {
      target = _scrollController.offset - viewport * 0.85;
    } else if (key == LogicalKeyboardKey.home) {
      target = _scrollController.position.minScrollExtent;
    } else if (key == LogicalKeyboardKey.end) {
      target = _scrollController.position.maxScrollExtent;
    }

    if (target == null) return KeyEventResult.ignored;

    final boundedTarget = target
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();

    _scrollController.animateTo(
      boundedTarget,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
