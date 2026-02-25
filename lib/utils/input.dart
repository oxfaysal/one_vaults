import 'package:flutter/material.dart';

import '../conts/Color.dart';
import '../conts/TextStyle.dart';

class inputField {
  static TextField formField(
      TextEditingController controller,
      String hintText,
      IconData icon,
      Function(String)? onChanged,
      Function(String)? onSubmitted,
      ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: hintText,
        labelStyle: TEXT_STYLE.searchingText,
        prefixIcon: Icon(icon, color: APP_COLOR.colorGray),
        filled: true,
        fillColor: APP_COLOR.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: APP_COLOR.colorGray.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: APP_COLOR.primary2Color.withOpacity(0.5),
          ),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}