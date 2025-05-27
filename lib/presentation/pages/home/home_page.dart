import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'detect_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget{const HomePage({super.key});
@override State<HomePage> createState()=>_HomePageState(); }

class _HomePageState extends State<HomePage>{
  int idx=0;
  final pages=[const _Dashboard(),const CalendarPage(),const DetectPage(),const ChatPage(),const ProfilePage()];
  @override Widget build(BuildContext context){
    return Scaffold(
        body:pages[idx],
        bottomNavigationBar:BottomNavigationBar(
            currentIndex:idx,
            onTap:(v)=>setState(()=>idx=v),
            type:BottomNavigationBarType.fixed,
            items:[
              const BottomNavigationBarItem(icon:Icon(Icons.home),label:'Home'),
              const BottomNavigationBarItem(icon:Icon(Icons.calendar_month),label:'Kalender'),
              const BottomNavigationBarItem(icon:Icon(Icons.directions_run),label:'Deteksi'),
              const BottomNavigationBarItem(icon:Icon(Icons.chat),label:'Chat'),
              const BottomNavigationBarItem(icon:Icon(Icons.person),label:'Profil'),
            ]
        )
    );
  }
}

class _Dashboard extends StatelessWidget{ const _Dashboard({super.key});
@override Widget build(BuildContext context){
  return SafeArea(child:SingleChildScrollView(
      padding:const EdgeInsets.all(16),
      child:Column(children:[
        Row(children:[Image.asset('assets/logo_homepage.png',height:32),const SizedBox(width:8),
        const Icon(Icons.notifications_none),
        const SizedBox(height:16),
        Container(height:100,width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.green,borderRadius:BorderRadius.circular(16)),child:const Align(alignment:Alignment.centerLeft,child:Text('Selamat datang,\nJames!',style:TextStyle(color:Colors.white,fontSize:18)))) ,
        const SizedBox(height:16),
        Row(children:[
          _statCard(Icons.accessibility_new,'8','Gerakan'),
          const SizedBox(width:12),
          _statCard(Icons.timer,'20','Menit'),]),
        const SizedBox(height:16),
        ElevatedButton(onPressed:(){},child:const Text('Lanjutkan Program')),
        const SizedBox(height:16),
        ListTile(leading:const Icon(Icons.restaurant),title:const Text('Pola Makan'),tileColor:Colors.orange.shade50,onTap:(){})
      ])])));
}
Widget _statCard(IconData ic,String n,String txt)=>Expanded(child:Container(height:110,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.orange.shade50,borderRadius:BorderRadius.circular(16)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(ic,size:32,color:Colors.orange),const SizedBox(height:8),Text(n,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(txt)])));
}