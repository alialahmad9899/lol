import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class BrandLogo extends StatefulWidget {
  const BrandLogo({super.key, this.size = 48});

  final double size;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> {
  late final Future<Uint8List> _logoBytes = _loadLogo();

  Future<Uint8List> _loadLogo() async {
    final String encodedLogo = await rootBundle.loadString(
      'assets/branding/logo.jpeg.b64',
    );
    return base64Decode(encodedLogo.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: FutureBuilder<Uint8List>(
        future: _logoBytes,
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          final Uint8List? bytes = snapshot.data;
          if (bytes == null) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: RoohTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 26,
              ),
            );
          }

          return Image.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'شعار رُوح — ابدأ من الداخل',
          );
        },
      ),
    );
  }
}
