import 'dart:math';

import 'models.dart';

class EquationBank {
  EquationBank({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const List<EquationItem> _pool = <EquationItem>[
    EquationItem(id: 'eq1', prompt: '5x + 3 = 28', expectedFinal: 'x=5'),
    EquationItem(id: 'eq2', prompt: '6x = 42', expectedFinal: 'x=7'),
    EquationItem(id: 'eq3', prompt: '2x + 5 = 17', expectedFinal: 'x=6'),
    EquationItem(id: 'eq4', prompt: '3x - 4 = 11', expectedFinal: 'x=5'),
    EquationItem(id: 'eq5', prompt: '4x + 2 = 18', expectedFinal: 'x=4'),
    EquationItem(id: 'eq6', prompt: 'x/2 + 3 = 7', expectedFinal: 'x=8'),
    EquationItem(
      id: 'eq7',
      prompt: '2x + 2y = 20',
      expectedFinal: 'x=6',
      contextHint: 'y=4',
    ),
    EquationItem(id: 'eq8', prompt: '7x - 1 = 34', expectedFinal: 'x=5'),
  ];

  EquationItem next([String? avoidId]) {
    if (_pool.length <= 1) {
      return _pool.first;
    }
    EquationItem picked = _pool[_random.nextInt(_pool.length)];
    while (picked.id == avoidId) {
      picked = _pool[_random.nextInt(_pool.length)];
    }
    return picked;
  }
}
