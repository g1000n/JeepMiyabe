import 'package:flutter/material.dart';

/// The central floating action button (UTB pin) used to trigger the instructions sheet.
class FloatingActionPin extends StatelessWidget {
  final VoidCallback onPressed;
  
  const FloatingActionPin({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The large, pointed orange circle/pin base
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // White floating circle for the icon
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              // The up arrow icon
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 30,
                color: primaryColor,
              ),
            ),
          ),
          // Placeholder text 'UTB'
          const Positioned(
            bottom: 0,
            child: Text(
              'UTB',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
