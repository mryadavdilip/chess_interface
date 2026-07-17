# TODO - Customizable Piece Assets

- [ ] Update `BoardThemeConfig` to support caller-provided piece image injection (ImageProvider resolver).
- [ ] Update `ChessBoardWidget` to use the injected piece image provider when provided.
- [ ] Keep backward compatibility: if no provider is set, fall back to current `materialVariety/directory/extension` asset loading.
- [ ] Update `chess_interface/README.md` with documentation for custom assets (how to pass `pieceImageProvider` and how to declare assets in host `pubspec.yaml`).
- [ ] (Optional) Update `chess_interface/example/main.dart` to demonstrate custom piece assets.
- [ ] Run `flutter test` / `flutter analyze` (if available) and ensure packages compile.

