import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget{const HomeScreen({super.key});@override State<HomeScreen> createState()=>_HomeScreenState();}

class _HomeScreenState extends State<HomeScreen>{
  final api=ApiService();
  final member=TextEditingController(text:'000101020212');
  final password=TextEditingController(text:'123123');
  Map<String,dynamic>? customer,dashboard;
  String? error;
  bool loading=false;

  Future<void> logout() async{
    try { await api.post('/api/customer/logout',{}); } catch (_) { await api.clearSession(); }
    if (mounted) setState(() { customer=null; dashboard=null; error=null; });
  }

  Future<void> login() async{
    setState(()=>loading=true);
    try{
      final r=await api.post('/api/customer/login',{'membership':member.text.trim(),'password':password.text});
      customer=r['customer'];
      dashboard=await api.get('/api/customer/dashboard');
      setState(()=>error=null);
    }catch(e){setState(()=>error=e.toString());}
    finally{setState(()=>loading=false);}
  }

  @override Widget build(BuildContext context){
    if(customer==null)return Scaffold(body:Center(child:ConstrainedBox(constraints:BoxConstraints(maxWidth:420),child:Card(margin:const EdgeInsets.all(24),child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Hasani Customer',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const SizedBox(height:8),
      const Text('Member Login'),const SizedBox(height:24),
      TextField(controller:member,decoration:const InputDecoration(labelText:'Membership Card Number')),
      const SizedBox(height:14),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password')),
      const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:loading?null:login,child:Text(loading?'Signing in…':'Login'))),
      if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.red))),
      const SizedBox(height:14),const Text('Initial test password: 123123',style:TextStyle(color:Colors.grey))
    ]))))));
    }

    final purchases=(dashboard?['purchases'] as List? ?? []);
    final points=customer!['points'] ?? 0;
    final spend=purchases.fold<double>(0,(s,x)=>s+((x['total']??0) as num).toDouble());

    return Scaffold(
      appBar:AppBar(title:const Text('Hasani Customer'),actions:[IconButton(onPressed:logout,icon:const Icon(Icons.logout))]),
      drawer:Drawer(child:ListView(children:[
        const DrawerHeader(child:Text('Member Menu',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold))),
        ListTile(leading:const Icon(Icons.dashboard),title:const Text('Dashboard'),onTap:()=>Navigator.pop(context)),
        ListTile(leading:const Icon(Icons.receipt_long),title:const Text('Purchase History'),onTap:()=>_showPurchases(context,purchases)),
        ListTile(leading:const Icon(Icons.stars),title:const Text('Member Points'),onTap:()=>_showPoints(context,points,spend)),
        const ListTile(leading:Icon(Icons.card_giftcard),title:Text('Rewards')),
        const ListTile(leading:Icon(Icons.local_offer),title:Text('Offers')),
        const ListTile(leading:Icon(Icons.shopping_cart),title:Text('Online Store')),
        const ListTile(leading:Icon(Icons.location_on),title:Text('Locations')),
        ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:logout),
      ])),
      body:RefreshIndicator(onRefresh:login,child:ListView(padding:const EdgeInsets.all(18),children:[
        Text('Welcome, ${customer!['name']}',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
        const SizedBox(height:18),
        _memberCard(customer!),
        const SizedBox(height:14),
        Row(children:[
          Expanded(child:_stat('Points','$points')),
          const SizedBox(width:10),Expanded(child:_stat('Purchase','RM ${spend.toStringAsFixed(2)}')),
          const SizedBox(width:10),Expanded(child:_stat('Transactions','${purchases.length}')),
        ]),
        const SizedBox(height:18),
        _section('Quick Access',[
          _tile(Icons.receipt_long,'Purchase History','View your purchases',()=>_showPurchases(context,purchases)),
          _tile(Icons.stars,'Member Points','Points earned from purchases',()=>_showPoints(context,points,spend)),
          _tile(Icons.card_giftcard,'Rewards','Member rewards',null),
          _tile(Icons.local_offer,'Offers','Special offers',null),
          _tile(Icons.shopping_cart,'Online Store','Shop online',null),
          _tile(Icons.location_on,'Locations','Find stores',null),
        ])
      ]))
    );
  }

  Widget _memberCard(Map c)=>Card(color:const Color(0xff2358d8),child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('HASANI MEMBER',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.bold,letterSpacing:1.2)),
    Text(c['name'],style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
    Text(c['membership'],style:const TextStyle(color:Colors.white70)),
    const SizedBox(height:16),
    Wrap(spacing:18,runSpacing:12,crossAxisAlignment:WrapCrossAlignment.end,children:[
      Container(color:Colors.white,padding:const EdgeInsets.all(7),child:QrImageView(data:'HASANI-MEMBER:${c['membership']}',size:90)),
      Container(color:Colors.white,padding:const EdgeInsets.all(7),width:210,child:BarcodeWidget(barcode:Barcode.code128(),data:c['membership'],height:60,drawText:true))
    ])
  ]));

  Widget _stat(String title,String value)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.grey)),const SizedBox(height:5),Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold))])));

  Widget _section(String title,List<Widget> children)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:10),...children]);

  Widget _tile(IconData icon,String title,String sub,VoidCallback? onTap)=>Card(child:ListTile(leading:Icon(icon),title:Text(title),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:onTap));

  void _showPurchases(BuildContext c,List purchases)=>showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:ListView(shrinkWrap:true,children:[const Text('Purchase History',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),...purchases.map((p)=>ListTile(title:Text('Receipt #${p['receiptNo']}'),subtitle:Text('${p['date']} · +${p['points']} points'),trailing:Text('RM ${(p['total'] as num).toStringAsFixed(2)}')))])));

  void _showPoints(BuildContext c,int points,double spend)=>showModalBottomSheet(context:c,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Member Points',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text('Current points: $points'),Text('Verified purchase value: RM ${spend.toStringAsFixed(2)}'),Text('Points earned: $points'),const SizedBox(height:20)])));
}
