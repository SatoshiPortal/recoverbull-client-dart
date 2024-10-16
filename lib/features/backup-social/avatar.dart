import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String publicKey;

  const Avatar({super.key, required this.publicKey});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        'https://robohash.org/$publicKey',
        key: ValueKey(publicKey),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, exception, stackTrace) {
          return const Placeholder();
        },
      ),
    );
  }
}
