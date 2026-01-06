import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportService {
  Future<Uint8List> buildReport({required Map<String, dynamic> reportJson}) async {
    final doc = pw.Document();

    final meta = (reportJson['scanMeta'] as Map?)?.cast<String, dynamic>() ?? {};
    final findings = (reportJson['findings'] as List?)?.cast<Map>() ?? const [];
    final score = (reportJson['riskScore'] as Map?)?.cast<String, dynamic>() ?? {};

    // Use double quotes for strings that contain map key lookups.
    // Access map keys using ["key"] to avoid quote collisions.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'SCAN-X Security Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Text("Scan Time (UTC): ${meta["scanTimeUtc"] ?? '-'}"),
          pw.Text("Target CIDR: ${meta["targetCidr"] ?? '-'}"),
          pw.Text("Scan Mode: ${meta["scanMode"] ?? '-'}"),
          pw.SizedBox(height: 12),

          pw.Text(
            "Risk Score: ${score["score"] ?? 0} (${score["rating"] ?? 'Low'})",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'Findings',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          if (findings.isEmpty)
            pw.Text('No findings were detected.')
          else
            ...findings.map((f) {
              final m = f.cast<String, dynamic>();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${m["title"] ?? "Finding"}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Severity: ${m["severity"] ?? '-'}"),
                    pw.Text("Status: ${m["status"] ?? '-'}"),
                    pw.Text("Device: ${m["deviceIp"] ?? '-'}"),
                    pw.SizedBox(height: 4),
                    pw.Text("Evidence: ${m["evidence"] ?? '-'}"),
                    pw.SizedBox(height: 4),
                    pw.Text("What to do: ${m["recommendation"] ?? '-'}"),
                  ],
                ),
              );
            }),

          pw.SizedBox(height: 12),
          pw.Text(
            'Disclaimer',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('This report is informational and does not perform exploitation or intrusive actions.'),
        ],
      ),
    );

    return doc.save();
  }
}
