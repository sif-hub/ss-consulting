const List<String> _unites = [
  '',
  'un',
  'deux',
  'trois',
  'quatre',
  'cinq',
  'six',
  'sept',
  'huit',
  'neuf',
  'dix',
  'onze',
  'douze',
  'treize',
  'quatorze',
  'quinze',
  'seize',
  'dix-sept',
  'dix-huit',
  'dix-neuf',
];

const List<String> _dizaines = [
  '',
  '',
  'vingt',
  'trente',
  'quarante',
  'cinquante',
  'soixante',
  'soixante',
  'quatre-vingt',
  'quatre-vingt',
];

String _centaines(int n) {
  if (n == 0) return '';

  final centaine = n ~/ 100;
  final reste = n % 100;

  final buffer = StringBuffer();

  if (centaine > 0) {
    if (centaine > 1) buffer.write('${_unites[centaine]} ');
    buffer.write('cent');
    if (centaine > 1 && reste == 0) buffer.write('s');
    if (reste > 0) buffer.write(' ');
  }

  if (reste > 0) {
    if (reste < 20) {
      buffer.write(_unites[reste]);
    } else {
      final dizaine = reste ~/ 10;
      final unite = reste % 10;

      if (dizaine == 7 || dizaine == 9) {
        buffer.write(_dizaines[dizaine]);
        buffer.write(dizaine == 7 && unite == 1 ? ' et ' : '-');
        buffer.write(_unites[10 + unite]);
      } else {
        buffer.write(_dizaines[dizaine]);
        if (unite == 1 && dizaine != 8) {
          buffer.write(' et un');
        } else if (unite > 0) {
          buffer.write('-${_unites[unite]}');
        } else if (dizaine == 8) {
          buffer.write('s');
        }
      }
    }
  }

  return buffer.toString();
}

/// Convertit un entier positif en toutes lettres, en français.
String nombreEnLettres(int montant) {
  if (montant == 0) return 'zéro';

  if (montant < 0) return 'moins ${nombreEnLettres(-montant)}';

  final tranches = <int>[
    montant ~/ 1000000000,
    (montant ~/ 1000000) % 1000,
    (montant ~/ 1000) % 1000,
    montant % 1000,
  ];

  final parts = <String>[];

  if (tranches[0] > 0) {
    parts.add(
      tranches[0] == 1
          ? 'un milliard'
          : '${_centaines(tranches[0])} milliards',
    );
  }

  if (tranches[1] > 0) {
    parts.add(
      tranches[1] == 1
          ? 'un million'
          : '${_centaines(tranches[1])} millions',
    );
  }

  if (tranches[2] > 0) {
    parts.add(
      tranches[2] == 1 ? 'mille' : '${_centaines(tranches[2])} mille',
    );
  }

  if (tranches[3] > 0) {
    parts.add(_centaines(tranches[3]));
  }

  return parts.join(' ');
}
