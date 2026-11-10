import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';

enum CardStyle { green, paper, night }

/// Preview of a verse card, with a choice of style, that can be shared as a picture.
class ShareVerseScreen extends StatefulWidget {
  const ShareVerseScreen({super.key, required this.text, required this.reference, required this.edition});
  final String text, reference, edition;

  @override
  State<ShareVerseScreen> createState() => _ShareVerseScreenState();
}

class _ShareVerseScreenState extends State<ShareVerseScreen> {
  final _cardKey = GlobalKey();
  CardStyle _style = CardStyle.green;
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ijambo-${widget.reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: '${widget.reference} · Ijambo Bible');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Share verse', style: TextStyle(fontWeight: FontWeight.w700))),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: VerseCard(text: widget.text, reference: widget.reference, edition: widget.edition, style: _style),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    SegmentedButton<CardStyle>(
                      segments: const [
                        ButtonSegment(value: CardStyle.green, label: Text('Green')),
                        ButtonSegment(value: CardStyle.paper, label: Text('Paper')),
                        ButtonSegment(value: CardStyle.night, label: Text('Night')),
                      ],
                      selected: {_style},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) => setState(() => _style = value.first),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _sharing ? null : _share,
                        icon: _sharing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.share_rounded),
                        label: Text(_sharing ? 'Preparing…' : 'Share image'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

/// The square picture that gets shared.
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.text, required this.reference, required this.edition, required this.style});
  final String text, reference, edition;
  final CardStyle style;

  @override
  Widget build(BuildContext context) {
    final (Decoration decoration, Color ink, Color accent, Color soft) = switch (style) {
      CardStyle.green => (
          const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A6556), Brand.green, Brand.greenDeep]),
          ),
          Colors.white,
          Brand.gold,
          const Color(0xFFDCEBE5),
        ),
      CardStyle.paper => (
          const BoxDecoration(color: Color(0xFFFBF5E8)),
          Brand.ink,
          Brand.goldInk,
          Brand.muted,
        ),
      CardStyle.night => (
          const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A2320), Color(0xFF0C1210)]),
          ),
          const Color(0xFFF2EDE0),
          Brand.gold,
          const Color(0xFF9AA7A2),
        ),
    };
    final long = text.length > 220;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: decoration,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: style == CardStyle.paper ? Brand.green : Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Image.asset('assets/brand/mark.png'),
                ),
                const SizedBox(width: 10),
                Text('IJAMBO', style: TextStyle(color: accent, fontWeight: FontWeight.w800, letterSpacing: 3, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Text('“', style: TextStyle(color: accent, fontFamily: scriptureFont, fontSize: 56, height: .6)),
            Text(
              text,
              maxLines: long ? 9 : 7,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink, fontFamily: scriptureFont, fontSize: long ? 17 : 22, height: 1.35),
            ),
            const SizedBox(height: 16),
            Container(width: 32, height: 2, color: accent),
            const SizedBox(height: 10),
            Text(reference, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(edition, style: TextStyle(color: soft, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
