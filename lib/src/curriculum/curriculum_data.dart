import 'package:flutter/material.dart';

import 'curriculum_models.dart';

const List<CurriculumLevel> kCurriculumLevels = <CurriculumLevel>[
  CurriculumLevel(
    id: 'primary',
    names: <String, String>{
      'en': 'Elementary School',
      'es': 'Escuela Primaria',
      'pt': 'Escola Primária',
    },
    icon: Icons.school,
    topics: <CurriculumTopic>[
      CurriculumTopic(
        id: 'primary_counting',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Counting',
          'es': 'Conteo',
          'pt': 'Contagem',
        },
        difficulty: 1,
        promptHint: 'counting and number sense',
      ),
      CurriculumTopic(
        id: 'primary_add_sub',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Addition & Subtraction',
          'es': 'Suma y Resta',
          'pt': 'Soma e Subtração',
        },
        difficulty: 1,
        promptHint: 'simple addition and subtraction with integers',
        seedAssetPath: 'assets/elementary/addition_subtraction.json',
      ),
      CurriculumTopic(
        id: 'primary_mul_div',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Multiplication & Division',
          'es': 'Multiplicación y División',
          'pt': 'Multiplicação e Divisão',
        },
        difficulty: 1,
        promptHint: 'multiplication and division with integers',
      ),
      CurriculumTopic(
        id: 'primary_fractions',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Fractions',
          'es': 'Fracciones',
          'pt': 'Frações',
        },
        difficulty: 2,
        promptHint: 'fraction operations and simplification',
      ),
      CurriculumTopic(
        id: 'primary_powers_roots',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Powers & Roots',
          'es': 'Potencias y Raíces',
          'pt': 'Potências e Raízes',
        },
        difficulty: 2,
        promptHint: 'powers and square roots',
      ),
      CurriculumTopic(
        id: 'primary_geometry',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Plane Geometry',
          'es': 'Geometría Plana',
          'pt': 'Geometria Plana',
        },
        difficulty: 2,
        promptHint: 'area and perimeter of basic shapes',
      ),
      CurriculumTopic(
        id: 'primary_percentages',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Percentages',
          'es': 'Porcentajes',
          'pt': 'Porcentagens',
        },
        difficulty: 2,
        promptHint: 'percentage calculations',
      ),
      CurriculumTopic(
        id: 'primary_units',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Unit Conversions',
          'es': 'Conversión de Unidades',
          'pt': 'Conversão de Unidades',
        },
        difficulty: 2,
        promptHint: 'unit conversions',
      ),
      CurriculumTopic(
        id: 'primary_abs_value',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Absolute Value',
          'es': 'Valor Absoluto',
          'pt': 'Valor Absoluto',
        },
        difficulty: 2,
        promptHint: 'absolute value and comparisons',
      ),
      CurriculumTopic(
        id: 'primary_sets_intervals',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Sets & Intervals',
          'es': 'Conjuntos e Intervalos',
          'pt': 'Conjuntos e Intervalos',
        },
        difficulty: 2,
        promptHint: 'basic sets and number line intervals',
      ),
      CurriculumTopic(
        id: 'primary_divisibility',
        levelId: 'primary',
        names: <String, String>{
          'en': 'Divisibility Rules',
          'es': 'Reglas de Divisibilidad',
          'pt': 'Regras de Divisibilidade',
        },
        difficulty: 2,
        promptHint: 'divisibility rules',
      ),
    ],
  ),
  CurriculumLevel(
    id: 'secondary',
    names: <String, String>{
      'en': 'High School',
      'es': 'Escuela Secundaria',
      'pt': 'Escola Secundária',
    },
    icon: Icons.menu_book,
    topics: <CurriculumTopic>[
      CurriculumTopic(
        id: 'secondary_basic_exam',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Basic Level Exam',
          'es': 'Examen de Nivel Básico',
          'pt': 'Exame de Nível Básico',
        },
        difficulty: 2,
        promptHint: 'mixed basic algebra and arithmetic',
      ),
      CurriculumTopic(
        id: 'secondary_advanced_exam',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Advanced Level Exam',
          'es': 'Examen de Nivel Avanzado',
          'pt': 'Exame de Nível Avançado',
        },
        difficulty: 4,
        promptHint: 'mixed advanced algebra and geometry',
      ),
      CurriculumTopic(
        id: 'secondary_real_numbers',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Real Numbers',
          'es': 'Números Reales',
          'pt': 'Números Reais',
        },
        difficulty: 2,
        promptHint: 'operations with real numbers, intervals, absolute value',
      ),
      CurriculumTopic(
        id: 'secondary_functions_equations',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Functions & Equations',
          'es': 'Funciones y Ecuaciones',
          'pt': 'Funções e Equações',
        },
        difficulty: 3,
        promptHint: 'linear and quadratic functions and equations',
      ),
      CurriculumTopic(
        id: 'secondary_linear_equations',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Linear Equations',
          'es': 'Ecuaciones Lineales',
          'pt': 'Equações Lineares',
        },
        difficulty: 2,
        promptHint: 'first degree linear equations with one variable',
      ),
      CurriculumTopic(
        id: 'secondary_systems_intro',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Systems of Equations (Intro)',
          'es': 'Sistemas de Ecuaciones (Intro)',
          'pt': 'Sistemas de Equações (Intro)',
        },
        difficulty: 3,
        promptHint: 'systems of linear equations (with context substitutions)',
      ),
      CurriculumTopic(
        id: 'secondary_trigonometry',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Trigonometry',
          'es': 'Trigonometría',
          'pt': 'Trigonometria',
        },
        difficulty: 4,
        promptHint: 'basic trigonometry',
      ),
      CurriculumTopic(
        id: 'secondary_sequences',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Arithmetic & Geometric Sequences',
          'es': 'Progresiones Aritméticas y Geométricas',
          'pt': 'Progressões Aritméticas e Geométricas',
        },
        difficulty: 3,
        promptHint: 'arithmetic and geometric progressions',
      ),
      CurriculumTopic(
        id: 'secondary_statistics',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Statistics',
          'es': 'Estadística',
          'pt': 'Estatística',
        },
        difficulty: 3,
        promptHint: 'mean, median, mode, standard deviation',
      ),
      CurriculumTopic(
        id: 'secondary_geometry_plane',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Plane Geometry',
          'es': 'Geometría Plana',
          'pt': 'Geometria Plana',
        },
        difficulty: 3,
        promptHint: 'plane geometry',
      ),
      CurriculumTopic(
        id: 'secondary_geometry_space',
        levelId: 'secondary',
        names: <String, String>{
          'en': 'Solid Geometry',
          'es': 'Geometría del Espacio',
          'pt': 'Geometria do Espaço',
        },
        difficulty: 3,
        promptHint: '3d geometry',
      ),
    ],
  ),
  CurriculumLevel(
    id: 'university',
    names: <String, String>{
      'en': 'University',
      'es': 'Universidad',
      'pt': 'Universidade',
    },
    icon: Icons.account_balance,
    topics: <CurriculumTopic>[
      CurriculumTopic(
        id: 'university_limits',
        levelId: 'university',
        names: <String, String>{
          'en': 'Limits',
          'es': 'Límites',
          'pt': 'Limites',
        },
        difficulty: 4,
        promptHint: 'limits of functions',
      ),
      CurriculumTopic(
        id: 'university_derivatives',
        levelId: 'university',
        names: <String, String>{
          'en': 'Derivatives',
          'es': 'Derivadas',
          'pt': 'Derivadas',
        },
        difficulty: 4,
        promptHint: 'derivatives',
      ),
      CurriculumTopic(
        id: 'university_integrals',
        levelId: 'university',
        names: <String, String>{
          'en': 'Integrals',
          'es': 'Integrales',
          'pt': 'Integrais',
        },
        difficulty: 5,
        promptHint: 'integrals',
      ),
      CurriculumTopic(
        id: 'university_matrices',
        levelId: 'university',
        names: <String, String>{
          'en': 'Matrices',
          'es': 'Matrices',
          'pt': 'Matrizes',
        },
        difficulty: 4,
        promptHint: 'matrix operations',
      ),
      CurriculumTopic(
        id: 'university_complex_numbers',
        levelId: 'university',
        names: <String, String>{
          'en': 'Complex Numbers',
          'es': 'Números Complejos',
          'pt': 'Números Complexos',
        },
        difficulty: 4,
        promptHint: 'complex numbers',
      ),
      CurriculumTopic(
        id: 'university_linear_algebra',
        levelId: 'university',
        names: <String, String>{
          'en': 'Linear Algebra',
          'es': 'Álgebra Lineal',
          'pt': 'Álgebra Linear',
        },
        difficulty: 5,
        promptHint: 'linear algebra',
      ),
    ],
  ),
];
