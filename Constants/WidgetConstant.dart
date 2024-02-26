
import 'package:flutter/material.dart';

const hSpace10 = SizedBox(width: 10);
const vSpace5 = SizedBox(height: 5);
const vSpace10 = SizedBox(height: 10);

Widget get logo => Image.asset("assets/apps_icon.png", fit: BoxFit.scaleDown);

EdgeInsets get eiH10 => const EdgeInsets.symmetric(horizontal: 10);
EdgeInsets get eiV5 => const EdgeInsets.symmetric(vertical: 5);
EdgeInsets get eiH10V3 => const EdgeInsets.symmetric(horizontal: 10, vertical: 3);
EdgeInsets get eiH10V5 => const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
EdgeInsets get eiH20V5 => const EdgeInsets.symmetric(horizontal: 20, vertical: 5);
EdgeInsets get eiAll10 => const EdgeInsets.all(10);

EdgeInsets get eiB5 => const EdgeInsets.only(bottom: 5);

Align alignTopLeft({ required Widget child }) => Align(alignment: Alignment.topLeft, child: child);
Align alignTopCenter({ required Widget child }) => Align(alignment: Alignment.topCenter, child: child);
Align alignTopRight({ required Widget child }) => Align(alignment: Alignment.topRight, child: child);
Align alignCenterLeft({ required Widget child }) => Align(alignment: Alignment.centerLeft, child: child);
Align alignCenter({ required Widget child }) => Align(alignment: Alignment.center, child: child);
Align alignCenterRight({ required Widget child }) => Align(alignment: Alignment.centerRight, child: child);
Align alignBottomLeft({ required Widget child }) => Align(alignment: Alignment.bottomLeft, child: child);
Align alignBottomCenter({ required Widget child }) => Align(alignment: Alignment.bottomCenter, child: child);
Align alignBottomRight({ required Widget child }) => Align(alignment: Alignment.bottomRight, child: child);