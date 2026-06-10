# UDPipe models

Model files are not bundled with this package due to their size (20–60 MB).

Download German models from the UDPipe 1 model repository:
https://ufal.mff.cuni.cz/udpipe/1/models

- **german-gsd.udpipe** (~20 MB) — Universal Dependencies GSD corpus
- **german-hdt.udpipe** (~60 MB) — Hamburg Dependency Treebank

Place the downloaded `.udpipe` files in this directory (`assets/models/`),
then declare the asset in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/
```
