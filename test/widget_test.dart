import 'package:flutter_test/flutter_test.dart';
import 'package:udpipe_flutter/udpipe_flutter.dart';

void main() {
  const sample = '''# text = Er steigt aus dem Bus aus.
1\tEr\ter\tPRON\t_\t_\t2\tnsubj\t_\t_
2\tsteigt\tsteigen\tVERB\t_\t_\t0\troot\t_\t_
3\taus\taus\tADP\t_\t_\t5\tcase\t_\t_
4\tdem\tder\tDET\t_\t_\t5\tdet\t_\t_
5\tBus\tBus\tNOUN\t_\t_\t2\tobl\t_\t_
6\taus\taus\tADP\t_\t_\t2\tcompound:prt\t_\t_
7\t.\t.\tPUNCT\t_\t_\t2\tpunct\t_\t_

''';

  test('parseConlluSentences parses tokens correctly', () {
    final sents = parseConlluSentences(sample);
    expect(sents.length, 1);
    expect(sents.first.text, 'Er steigt aus dem Bus aus.');
    expect(sents.first.tokens.length, 7);
    expect(sents.first.tokens[1].form, 'steigt');
    expect(sents.first.tokens[1].upos, 'VERB');
    expect(sents.first.tokens[1].head, 0);
  });

  test('findSepVerbs detects compound:prt particle', () {
    final sents = parseConlluSentences(sample);
    final verbs = findSepVerbs(sents.first.tokens);
    expect(verbs.length, 1);
    expect(verbs.first.particle, 'aus');
    expect(verbs.first.verbForm, 'steigt');
    expect(verbs.first.fullLemma, 'aussteigen');
  });

  test('buildUDPipeResult returns empty for empty input', () {
    final result = buildUDPipeResult('');
    expect(result.sentences, isEmpty);
  });

  test('tokensByFormAll maps lower-case forms', () {
    final sents = parseConlluSentences(sample);
    final map = tokensByFormAll(sents.first.tokens);
    expect(map.containsKey('Bus'), isTrue);
    expect(map.containsKey('bus'), isTrue);
    expect(map['Er'], isNotEmpty);
  });
}
