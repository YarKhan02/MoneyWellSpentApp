import 'package:flutter/material.dart';
import 'tokens.dart';

/// Accent colours cycled across chart segments and category rows.
const chartColors = [
  Brand.forest,
  Brand.wheat,
  Brand.cherry,
  Brand.muted,
  Color(0xFF6B8F71),
  Color(0xFFE8A13A),
];

/// The chart colour for the segment at [index], wrapping round the palette.
Color chartColorAt(int index) => chartColors[index % chartColors.length];
