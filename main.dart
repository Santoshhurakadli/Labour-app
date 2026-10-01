import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = 'https://ykkmzlpagwunczwwvccz.supabase.co';
const supabaseKey = 'sb_publishable_43yMIttcr7BeYWUqWDkkoQ_h2g4BN9i';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const LabourApp());
}
final sb = Supabase.instance.client;

class LabourApp extends StatelessWidget {
  const LabourApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'Labour',
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:Colors.indigo),useMaterial3:true),
    home: sb.auth.currentSession == null ? const LoginPage() : const HomePage());
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
  final phone=TextEditingController(); final otp=TextEditingController(); bool sent=false; bool busy=false;
  Future<void> send() async { setState(()=>busy=true); try { await sb.auth.signInWithOtp(phone:phone.text.trim()); setState(()=>sent=true); } catch(e){ msg('$e'); } setState(()=>busy=false); }
  Future<void> verify() async { setState(()=>busy=true); try { await sb.auth.verifyOTP(phone:phone.text.trim(), token:otp.text.trim(), type:OtpType.sms); if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomePage())); } catch(e){msg('$e');} setState(()=>busy=false); }
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('LABOUR')),body:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
    const Text('ಕೆಲಸ ಬೇಕಾ? Labour ಬೇಕಾ?',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
    const SizedBox(height:20),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Mobile number (+91...)',border:OutlineInputBorder())),
    if(sent) ...[const SizedBox(height:12),TextField(controller:otp,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'OTP',border:OutlineInputBorder()))],
    const SizedBox(height:16),FilledButton(onPressed:busy?null:(sent?verify:send),child:Text(sent?'OTP Verify':'Send OTP'))
  ])));
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage>{
  int tab=0;
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('LABOUR'),actions:[IconButton(onPressed:()async{await sb.auth.signOut();if(mounted)Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>const LoginPage()));},icon:const Icon(Icons.logout))]),
    body:tab==0?const JobsPage():tab==1?const ProfilePage():const NotificationsPage(),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
      NavigationDestination(icon:Icon(Icons.work),label:'Jobs'),NavigationDestination(icon:Icon(Icons.person),label:'Profile'),NavigationDestination(icon:Icon(Icons.notifications),label:'Alerts')]));
}

class JobsPage extends StatefulWidget { const JobsPage({super.key}); @override State<JobsPage> createState()=>_JobsPageState(); }
class _JobsPageState extends State<JobsPage>{
  final title=TextEditingController(),type=TextEditingController(),place=TextEditingController(),wage=TextEditingController(),people=TextEditingController();
  List<Map<String,dynamic>> jobs=[];
  Future<void> load() async { final r=await sb.from('jobs').select().eq('status','open').order('created_at',ascending:false); setState(()=>jobs=List<Map<String,dynamic>>.from(r)); }
  @override void initState(){super.initState();load();}
  Future<void> addJob() async { if(title.text.isEmpty||type.text.isEmpty||place.text.isEmpty)return; await sb.from('jobs').insert({'employer_id':sb.auth.currentUser!.id,'title':title.text,'work_type':type.text,'location_text':place.text,'wage':double.tryParse(wage.text),'people_needed':int.tryParse(people.text)??1}); title.clear();type.clear();place.clear();wage.clear();people.clear();load(); if(mounted)Navigator.pop(context); }
  Future<void> locate() async { if(!await Geolocator.isLocationServiceEnabled())return; var p=await Geolocator.checkPermission(); if(p==LocationPermission.denied)p=await Geolocator.requestPermission(); if(p==LocationPermission.denied||p==LocationPermission.deniedForever)return; final x=await Geolocator.getCurrentPosition(); await sb.from('user_locations').upsert({'user_id':sb.auth.currentUser!.id,'latitude':x.latitude,'longitude':x.longitude,'accuracy_m':x.accuracy}); }
  void form(){ showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.only(left:16,right:16,top:20,bottom:MediaQuery.of(context).viewInsets.bottom+20),child:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'काम')),
    TextField(controller:type,decoration:const InputDecoration(labelText:'ಕೆಲಸದ ಪ್ರಕಾರ')),
    TextField(controller:place,decoration:const InputDecoration(labelText:'ಸ್ಥಳ')),
    TextField(controller:wage,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ದಿನಗೂಲಿ')),
    TextField(controller:people,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ಜನ')),
    const SizedBox(height:10),FilledButton(onPressed:addJob,child:const Text('Job Post'))]));}
  @override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:FilledButton.icon(onPressed:form,icon:const Icon(Icons.add),label:const Text('Labour ಬೇಕು'))),const SizedBox(width:8),IconButton(onPressed:locate,icon:const Icon(Icons.my_location))])),Expanded(child:ListView.builder(itemCount:jobs.length,itemBuilder:(_,i){final j=jobs[i];return Card(child:ListTile(title:Text(j['title']??''),subtitle:Text('${j['work_type']??''} • ${j['location_text']??''}\n₹${j['wage']??'-'} • ${j['people_needed']} ಜನ'));}));]);
}

class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext c)=>Center(child:Text('Logged in: ${sb.auth.currentUser?.phone??''}')); }
class NotificationsPage extends StatefulWidget { const NotificationsPage({super.key}); @override State<NotificationsPage> createState()=>_NotificationsPageState(); }
class _NotificationsPageState extends State<NotificationsPage>{
 List<Map<String,dynamic>> n=[];
 @override void initState(){super.initState();load(); sb.channel('notifications-${sb.auth.currentUser!.id}').onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'notifications',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'user_id',value:sb.auth.currentUser!.id),callback:(_)=>load()).subscribe();}
 Future<void> load()async{final r=await sb.from('notifications').select().eq('user_id',sb.auth.currentUser!.id).order('created_at',ascending:false);setState(()=>n=List<Map<String,dynamic>>.from(r));}
 @override Widget build(BuildContext c)=>ListView(children:n.map((x)=>ListTile(title:Text(x['title']??''),subtitle:Text(x['body']??''))).toList());
}
