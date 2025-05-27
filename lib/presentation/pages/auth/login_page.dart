import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common.dart';

class LoginPage extends StatefulWidget{ const LoginPage({super.key});
@override State<LoginPage> createState()=>_LoginPageState(); }

class _LoginPageState extends State<LoginPage>{
  final emailC=TextEditingController(), passC=TextEditingController();
  @override Widget build(BuildContext context){
    return Scaffold(
        body:BlocConsumer<AuthBloc,AuthState>(
            listener:(c,s){ if(s is AuthSuccess) context.go('/home');
            if(s is AuthFailure) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s.msg)));},
            builder:(c,s){ final loading=s is AuthLoading; return SingleChildScrollView(
                padding:const EdgeInsets.fromLTRB(24,120,24,24),
                child:Column(children:[
                  const Text('Log In',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
                  const SizedBox(height:32),
                  TextField(controller:emailC,decoration:const InputDecoration(labelText:'Email')),
                  const SizedBox(height:16),
                  TextField(controller:passC,obscureText:true,decoration:const InputDecoration(labelText:'Password')),
                  const SizedBox(height:32),
                  NeuButton(label:'Masuk',loading:loading,onTap:(){
                    context.read<AuthBloc>().add(SignInRequested(emailC.text,passC.text));}),
                  const SizedBox(height:12),
                  TextButton(onPressed:()=>context.go('/signup'),child:const Text('Belum punya akun? Daftar'))
                ]
                )
              );
            }
          )
    );
  }
}
