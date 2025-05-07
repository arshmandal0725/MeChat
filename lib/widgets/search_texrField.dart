import 'package:flutter/material.dart';

class SearchTexrfield extends StatelessWidget {
  const SearchTexrfield({super.key, required this.onChanged});
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
          hintText: "Search...",
          suffixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.black))),
    );
  }
}
