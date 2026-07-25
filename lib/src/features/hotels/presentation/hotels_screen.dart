import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../workers/data/worker_repository.dart';
import '../../workers/domain/worker.dart';
import '../data/hotel_repository.dart';
import '../domain/hotel_assignment.dart';
import 'hotel_form_screen.dart';
import 'widgets/hotel_status_chip.dart';

class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});
  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  final hotelRepository = InMemoryHotelRepository.instance;
  final workerRepository = InMemoryWorkerRepository.instance;
  final searchController = TextEditingController();
  HotelStatus? selectedStatus;

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  Worker? worker(String id) {
    for (final item in workerRepository.getAll()) { if (item.id == id) return item; }
    return null;
  }

  List<HotelAssignment> get assignments {
    final query = searchController.text.trim().toLowerCase();
    return hotelRepository.getAll().where((a) {
      final name = worker(a.workerId)?.fullName.toLowerCase() ?? '';
      final match = query.isEmpty || name.contains(query) || a.hotelName.toLowerCase().contains(query) || a.city.toLowerCase().contains(query) || a.room.toLowerCase().contains(query) || a.confirmationCode.toLowerCase().contains(query);
      return match && (selectedStatus == null || a.status == selectedStatus);
    }).toList()..sort((a,b) => a.checkInDate.compareTo(b.checkInDate));
  }

  String date(DateTime v) => '${v.day.toString().padLeft(2,'0')}/${v.month.toString().padLeft(2,'0')}/${v.year}';
  String money(double v) {
    final chars = v.toStringAsFixed(0).split('').reversed.toList();
    final parts = <String>[];
    for (var i=0; i<chars.length; i+=3) { parts.add(chars.skip(i).take(3).toList().reversed.join()); }
    return '\$${parts.reversed.join('.')}';
  }

  void syncWorker(HotelAssignment a) {
    final w = worker(a.workerId); if (w == null) return;
    w.hotel = a.status == HotelStatus.cancelled ? '' : a.hotelName;
    w.room = a.status == HotelStatus.cancelled ? '' : a.room;
    if (a.status == HotelStatus.checkedIn) w.status = WorkerStatus.lodging;
    workerRepository.update(w);
  }

  Future<void> addAssignment() async {
    final value = await Navigator.push<HotelAssignment>(context, MaterialPageRoute(builder: (_) => const HotelFormScreen()));
    if (!mounted || value == null) return;
    hotelRepository.add(value); syncWorker(value); setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alojamiento creado correctamente.')));
  }

  Future<void> editAssignment(HotelAssignment a) async {
    final value = await Navigator.push<HotelAssignment>(context, MaterialPageRoute(builder: (_) => HotelFormScreen(assignment: a)));
    if (!mounted || value == null) return;
    hotelRepository.update(value); syncWorker(value); setState(() {});
  }

  Future<void> deleteAssignment(HotelAssignment a) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Eliminar alojamiento'),
      content: const Text('Esta acción quitará la asignación del listado.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context,false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context,true), child: const Text('Eliminar')),
      ],
    ));
    if (ok == true) {
      final w = worker(a.workerId); hotelRepository.delete(a.id);
      if (w != null) { w.hotel=''; w.room=''; workerRepository.update(w); }
      setState(() {});
    }
  }

  int count(HotelStatus s) => hotelRepository.getAll().where((a) => a.status == s).length;

  @override
  Widget build(BuildContext context) {
    final list = assignments;
    return Column(children: [
      _summary(),
      Expanded(child: Padding(
        padding: const EdgeInsets.fromLTRB(22,0,22,22),
        child: Column(children: [
          _filters(), const SizedBox(height:16),
          Expanded(child: list.isEmpty ? const Center(child: Text('No se encontraron alojamientos.')) : ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_,__) => const SizedBox(height:12),
            itemBuilder: (context,index) {
              final a=list[index]; final w=worker(a.workerId);
              return Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
                const CircleAvatar(radius:27, child: Icon(Icons.hotel)),
                const SizedBox(width:16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.hotelName, style: const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
                  const SizedBox(height:5), Text(w?.fullName ?? 'Trabajador no encontrado'),
                  const SizedBox(height:2), Text('${a.city} · Hab. ${a.room} · ${date(a.checkInDate)} → ${date(a.checkOutDate)}', style: const TextStyle(color:Colors.black54)),
                  if (a.dailyRate > 0) Text('${a.nights} noche(s) · ${money(a.totalCost)}', style: const TextStyle(color:Colors.black54)),
                ])),
                HotelStatusChip(status:a.status), const SizedBox(width:6),
                PopupMenuButton<String>(
                  onSelected:(value){ if(value=='edit') editAssignment(a); if(value=='delete') deleteAssignment(a); },
                  itemBuilder:(context)=>const [
                    PopupMenuItem(value:'edit', child:ListTile(dense:true,leading:Icon(Icons.edit),title:Text('Editar'))),
                    PopupMenuItem(value:'delete', child:ListTile(dense:true,leading:Icon(Icons.delete_outline),title:Text('Eliminar'))),
                  ],
                ),
              ])));
            },
          )),
        ]),
      )),
    ]);
  }

  Widget _summary() {
    final all=hotelRepository.getAll();
    return Padding(padding: const EdgeInsets.all(22), child: LayoutBuilder(builder:(context,constraints){
      final width=constraints.maxWidth>=900?(constraints.maxWidth-48)/4:(constraints.maxWidth-16)/2;
      return Wrap(spacing:16,runSpacing:16,children:[
        _card(width,'Total',all.length.toString(),Icons.hotel,Colors.indigo),
        _card(width,'Confirmados',count(HotelStatus.confirmed).toString(),Icons.check_circle,AppColors.success),
        _card(width,'Check-in',count(HotelStatus.checkedIn).toString(),Icons.login,Colors.blue),
        _card(width,'Solicitados',count(HotelStatus.requested).toString(),Icons.schedule,AppColors.warning),
      ]);
    }));
  }

  Widget _card(double width,String title,String value,IconData icon,Color color) => SizedBox(width:width,child:Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
    CircleAvatar(backgroundColor:color.withOpacity(.12),child:Icon(icon,color:color)), const SizedBox(width:13),
    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),Text(title)]),
  ]))));

  Widget _filters() => LayoutBuilder(builder:(context,constraints){
    final compact=constraints.maxWidth<760;
    final search=TextField(controller:searchController,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Buscar trabajador, hotel, ciudad, habitación o confirmación',prefixIcon:Icon(Icons.search)));
    final status=DropdownButtonFormField<HotelStatus?>(initialValue:selectedStatus,isExpanded:true,decoration:const InputDecoration(labelText:'Estado',prefixIcon:Icon(Icons.filter_alt)),items:[
      const DropdownMenuItem<HotelStatus?>(value:null,child:Text('Todos los estados')),
      ...HotelStatus.values.map((s)=>DropdownMenuItem<HotelStatus?>(value:s,child:Text(s.label))),
    ],onChanged:(value)=>setState(()=>selectedStatus=value));
    final add=FilledButton.icon(onPressed:addAssignment,icon:const Icon(Icons.add),label:const Text('Nuevo alojamiento'));
    if(compact) return Column(children:[search,const SizedBox(height:12),status,const SizedBox(height:12),SizedBox(width:double.infinity,child:add)]);
    return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:2,child:search),const SizedBox(width:12),Expanded(child:status),const SizedBox(width:12),add]);
  });
}
