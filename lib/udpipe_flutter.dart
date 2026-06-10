/// UDPipe Flutter library — tokenization, POS tagging, dependency parsing.
///
/// Usage:
/// ```dart
/// final svc = UDPipeService();
/// await svc.init(modelId: 'gsd');  // or 'hdt'
/// final result = svc.process('Er steigt aus dem Bus aus.');
/// for (final sentence in result.sentences) {
///   for (final token in sentence.tokens) {
///     print('${token.form}  ${token.upos}  ${token.lemma}');
///   }
/// }
/// ```
library;

export 'udpipe/udpipe_flutter.dart';
