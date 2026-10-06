import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';

/// Placeholder accesible para consultas asíncronas mientras llega el contenido.
class A2CLoadingSkeleton extends StatelessWidget {
  const A2CLoadingSkeleton({super.key, required this.label, this.rows = 3});

  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: label,
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: A2CColors.surface,
              borderRadius: BorderRadius.circular(A2CRadii.lg),
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < rows; index++) ...[
            Container(
              height: 68,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: A2CColors.surface,
                borderRadius: BorderRadius.circular(A2CRadii.md),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: index.isEven ? .68 : .48,
                  heightFactor: .28,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: A2CColors.border,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
            if (index + 1 < rows) const SizedBox(height: 8),
          ],
        ],
      ),
    ),
  );
}

/// Version compacta del esqueleto para listas de filas, anunciada una sola vez.
class A2CLoadingRows extends StatelessWidget {
  const A2CLoadingRows({super.key, required this.label, this.rows = 4});

  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: label,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var index = 0; index < rows; index++) ...[
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: A2CColors.surface,
                borderRadius: BorderRadius.circular(A2CRadii.md),
              ),
            ),
            if (index + 1 < rows) const SizedBox(height: 8),
          ],
        ],
      ),
    ),
  );
}
