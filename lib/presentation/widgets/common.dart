import 'package:flutter/material.dart';
class NeuButton extends StatelessWidget {
  final String label; final VoidCallback onTap; final bool loading;
  const NeuButton({super.key, required this.label, required this.onTap, this.loading=false});
  @override Widget build(BuildContext context)=>ElevatedButton(
      onPressed: loading?null:onTap,
      style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: const Color(0xFF2F3026)
      ),
      child: loading?const CircularProgressIndicator():Text(label));
}
