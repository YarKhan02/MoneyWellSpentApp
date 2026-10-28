import 'dart:convert';
import 'dart:ui' show Rect;
import 'package:share_plus/share_plus.dart';

/// Hands the CSV to the platform share sheet as a real file.
///
/// Nothing is written to shared storage first — the bytes go straight to the
/// destination the person picks, which is the only way data leaves the app.
Future<void> shareExpenseCsv(String csv, {Rect? originRect}) =>
    SharePlus.instance.share(
      ShareParams(
        title: 'Money Well Spent — expense export',
        files: [
          XFile.fromData(
            utf8.encode(csv),
            mimeType: 'text/csv',
            name: csvFileName,
          ),
        ],
        fileNameOverrides: const [csvFileName],
        sharePositionOrigin: originRect,
      ),
    );

const csvFileName = 'money-well-spent.csv';
