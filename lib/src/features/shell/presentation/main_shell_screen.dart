import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/login_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../workers/presentation/workers_screen.dart';
import '../../workers/domain/worker.dart';
import '../../tickets/presentation/tickets_screen.dart';
import '../../hotels/presentation/hotels_screen.dart';
import '../../agenda/presentation/agenda_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../transfers/presentation/transfers_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int selectedIndex = 0;
  WorkerStatus? workerStatusFilter;
  String? ticketInitialWorkerId;
  String? hotelInitialWorkerId;
  String? transferInitialWorkerId;

  final items = const [
    _NavigationItem(label: 'Centro de Operaciones', icon: Icons.dashboard),
    _NavigationItem(label: 'Personal', icon: Icons.groups),
    _NavigationItem(label: 'Agenda', icon: Icons.calendar_month),
    _NavigationItem(label: 'Pasajes', icon: Icons.airplane_ticket),
    _NavigationItem(label: 'Hoteles', icon: Icons.hotel),
    _NavigationItem(label: 'Traslados', icon: Icons.directions_bus),
    _NavigationItem(label: 'Reportes', icon: Icons.assignment),
    _NavigationItem(label: 'Alertas', icon: Icons.notifications_active),
    _NavigationItem(label: 'Configuración', icon: Icons.settings),
  ];

  Future<void> logout() async {
    await LocalStorageService.instance.remove('auth.session.active');
    await LocalStorageService.instance.remove('auth.session.rut');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget content() {
    if (selectedIndex == 0) {
      return DashboardScreen(
        onNavigate: (index) {
          setState(() {
            selectedIndex = index;
            if (index == 1) workerStatusFilter = null;
          });
        },
        onOpenWorkerStatus: (status) {
          setState(() {
            workerStatusFilter = status;
            selectedIndex = 1;
          });
        },
      );
    }

    if (selectedIndex == 1) {
      return WorkersScreen(
        key: ValueKey(workerStatusFilter),
        initialStatus: workerStatusFilter,
      );
    }

    if (selectedIndex == 2) {
      return const AgendaScreen();
    }

    if (selectedIndex == 3) {
      return TicketsScreen(initialWorkerId: ticketInitialWorkerId);
    }

    if (selectedIndex == 4) {
      return HotelsScreen(initialWorkerId: hotelInitialWorkerId);
    }
    if (selectedIndex == 5) {
      return TransfersScreen(initialWorkerId: transferInitialWorkerId);
    }

    if (selectedIndex == 6) {
      return const ReportsScreen();
    }

    if (selectedIndex == 7) {
      return AlertsScreen(
        onNavigate: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        onManageTicket: (workerId) {
          setState(() {
            ticketInitialWorkerId = workerId;
            selectedIndex = 3;
          });
        },
        onManageHotel: (workerId) {
          setState(() {
            hotelInitialWorkerId = workerId;
            selectedIndex = 4;
          });
        },
        onManageTransfer: (workerId) {
          setState(() {
            transferInitialWorkerId = workerId;
            selectedIndex = 5;
          });
        },
      );
    }

    return const SettingsScreen();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;

        if (!desktop) {
          return Scaffold(
            appBar: AppBar(
              leading: selectedIndex == 0
                  ? null
                  : IconButton(
                      tooltip: 'Volver al Centro de Operaciones',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() {
                        selectedIndex = 0;
                        workerStatusFilter = null;
                      }),
                    ),
              title: Text(items[selectedIndex].label),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            drawer: Drawer(
              child: _Sidebar(
                items: items,
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                    if (index == 1) workerStatusFilter = null;
                  });
                  Navigator.pop(context);
                },
                onLogout: logout,
              ),
            ),
            body: content(),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 276,
                child: _Sidebar(
                  items: items,
                  selectedIndex: selectedIndex,
                  onSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                      if (index == 1) workerStatusFilter = null;
                    });
                  },
                  onLogout: logout,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 72,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          if (selectedIndex != 0)
                            IconButton(
                              tooltip: 'Volver al Centro de Operaciones',
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => setState(() {
                                selectedIndex = 0;
                                workerStatusFilter = null;
                              }),
                            ),
                          if (selectedIndex != 0)
                            Text(
                              items[selectedIndex].label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const Spacer(),
                          CircleAvatar(child: Icon(Icons.person)),
                          SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alejandro Cárdenas',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Coordinador Logístico',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: content()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.engineering, color: AppColors.primary),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          AppStrings.edition,
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: Colors.white.withValues(alpha: 0.13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onSelected(index),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: onLogout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;

  const _NavigationItem({required this.label, required this.icon});
}
