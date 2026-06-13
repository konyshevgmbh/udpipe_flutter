# UDPipe models

Model files are not bundled with this package due to their size (5–60 MB each).

Download models from the UDPipe 1 model repository:
https://ufal.mff.cuni.cz/udpipe/1/models

Place the downloaded `.udpipe` file in this directory (`assets/models/`) and
declare the folder in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/
```

Then load the model by its treebank id:

```dart
await svc.init(modelId: 'german-gsd');
```

## Available models (UD 2.5)

| Id (pass to `init`) | File to place in `assets/models/` |
|---|---|
| `ancient_greek-perseus` | `ancient_greek-perseus.udpipe` |
| `ancient_greek-proiel` | `ancient_greek-proiel.udpipe` |
| `arabic-padt` | `arabic-padt.udpipe` |
| `basque-bdt` | `basque-bdt.udpipe` |
| `belarusian-hse` | `belarusian-hse.udpipe` |
| `bulgarian-btb` | `bulgarian-btb.udpipe` |
| `catalan-ancora` | `catalan-ancora.udpipe` |
| `chinese-gsd` | `chinese-gsd.udpipe` |
| `coptic-scriptorium` | `coptic-scriptorium.udpipe` |
| `croatian-set` | `croatian-set.udpipe` |
| `czech-cac` | `czech-cac.udpipe` |
| `czech-cltt` | `czech-cltt.udpipe` |
| `czech-fictree` | `czech-fictree.udpipe` |
| `czech-pdt` | `czech-pdt.udpipe` |
| `danish-ddt` | `danish-ddt.udpipe` |
| `dutch-alpino` | `dutch-alpino.udpipe` |
| `dutch-lassysmall` | `dutch-lassysmall.udpipe` |
| `english-ewt` | `english-ewt.udpipe` |
| `english-gum` | `english-gum.udpipe` |
| `english-lines` | `english-lines.udpipe` |
| `english-partut` | `english-partut.udpipe` |
| `estonian-edt` | `estonian-edt.udpipe` |
| `estonian-ewt` | `estonian-ewt.udpipe` |
| `finnish-ftb` | `finnish-ftb.udpipe` |
| `finnish-tdt` | `finnish-tdt.udpipe` |
| `french-gsd` | `french-gsd.udpipe` |
| `french-partut` | `french-partut.udpipe` |
| `french-sequoia` | `french-sequoia.udpipe` |
| `french-spoken` | `french-spoken.udpipe` |
| `galician-ctg` | `galician-ctg.udpipe` |
| `galician-treegal` | `galician-treegal.udpipe` |
| `german-gsd` | `german-gsd.udpipe` |
| `german-hdt` | `german-hdt.udpipe` |
| `gothic-proiel` | `gothic-proiel.udpipe` |
| `greek-gdt` | `greek-gdt.udpipe` |
| `hebrew-htb` | `hebrew-htb.udpipe` |
| `hindi-hdtb` | `hindi-hdtb.udpipe` |
| `hungarian-szeged` | `hungarian-szeged.udpipe` |
| `indonesian-gsd` | `indonesian-gsd.udpipe` |
| `irish-idt` | `irish-idt.udpipe` |
| `italian-isdt` | `italian-isdt.udpipe` |
| `italian-partut` | `italian-partut.udpipe` |
| `italian-postwita` | `italian-postwita.udpipe` |
| `italian-twittiro` | `italian-twittiro.udpipe` |
| `japanese-gsd` | `japanese-gsd.udpipe` |
| `korean-gsd` | `korean-gsd.udpipe` |
| `korean-kaist` | `korean-kaist.udpipe` |
| `latin-ittb` | `latin-ittb.udpipe` |
| `latin-perseus` | `latin-perseus.udpipe` |
| `latin-proiel` | `latin-proiel.udpipe` |
| `latvian-lvtb` | `latvian-lvtb.udpipe` |
| `lithuanian-alksnis` | `lithuanian-alksnis.udpipe` |
| `lithuanian-hse` | `lithuanian-hse.udpipe` |
| `maltese-mudt` | `maltese-mudt.udpipe` |
| `marathi-ufal` | `marathi-ufal.udpipe` |
| `north_sami-giella` | `north_sami-giella.udpipe` |
| `norwegian-bokmaal` | `norwegian-bokmaal.udpipe` |
| `norwegian-nynorsk` | `norwegian-nynorsk.udpipe` |
| `norwegian-nynorsklia` | `norwegian-nynorsklia.udpipe` |
| `old_church_slavonic-proiel` | `old_church_slavonic-proiel.udpipe` |
| `old_french-srcmf` | `old_french-srcmf.udpipe` |
| `old_russian-torot` | `old_russian-torot.udpipe` |
| `persian-seraji` | `persian-seraji.udpipe` |
| `polish-lfg` | `polish-lfg.udpipe` |
| `polish-pdb` | `polish-pdb.udpipe` |
| `portuguese-bosque` | `portuguese-bosque.udpipe` |
| `portuguese-gsd` | `portuguese-gsd.udpipe` |
| `romanian-nonstandard` | `romanian-nonstandard.udpipe` |
| `romanian-rrt` | `romanian-rrt.udpipe` |
| `russian-gsd` | `russian-gsd.udpipe` |
| `russian-syntagrus` | `russian-syntagrus.udpipe` |
| `russian-taiga` | `russian-taiga.udpipe` |
| `serbian-set` | `serbian-set.udpipe` |
| `slovak-snk` | `slovak-snk.udpipe` |
| `slovenian-ssj` | `slovenian-ssj.udpipe` |
| `slovenian-sst` | `slovenian-sst.udpipe` |
| `spanish-ancora` | `spanish-ancora.udpipe` |
| `spanish-gsd` | `spanish-gsd.udpipe` |
| `swedish-lines` | `swedish-lines.udpipe` |
| `swedish-talbanken` | `swedish-talbanken.udpipe` |
| `swedish_sign_language-sweslam` | `swedish_sign_language-sweslam.udpipe` |
| `tamil-ttb` | `tamil-ttb.udpipe` |
| `telugu-mtg` | `telugu-mtg.udpipe` |
| `turkish-imst` | `turkish-imst.udpipe` |
| `ukrainian-iu` | `ukrainian-iu.udpipe` |
| `upper_sorbian-ufal` | `upper_sorbian-ufal.udpipe` |
| `urdu-udtb` | `urdu-udtb.udpipe` |
| `uyghur-udt` | `uyghur-udt.udpipe` |
| `vietnamese-vtb` | `vietnamese-vtb.udpipe` |
| `wolof-wtb` | `wolof-wtb.udpipe` |

> **Legacy ids**: `'gsd'` and `'hdt'` (used before v0.2.0) still work
> and resolve to `'german-gsd'` and `'german-hdt'` respectively.
