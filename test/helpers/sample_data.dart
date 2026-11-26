/// Shared sample payload for widget tests (mirrors the home seed).
const List<Map<String, dynamic>> samplePrograms = [
  <String, dynamic>{
    'id': 1,
    'name': 'روشنایی محوطه',
    'cycle': 'weekly',
    'events': [
      <String, dynamic>{'type': 'astro', 'astro': 'sunset', 'offset': 20, 'sign': 'after', 'cmd': 'on'},
      <String, dynamic>{'type': 'fixed', 'hh': 22, 'mm': 30, 'cmd': 'off'},
    ],
    'assign': <String, dynamic>{'weekly': [0, 1, 2, 3, 4]},
  },
  <String, dynamic>{
    'id': 2,
    'name': 'پمپ استخر',
    'cycle': 'daily',
    'events': [
      <String, dynamic>{
        'type': 'fixed', 'hh': 8, 'mm': 0, 'cmd': 'timer',
        'onPhase': <String, dynamic>{'h': 0, 'm': 30},
        'offPhase': <String, dynamic>{'h': 0, 'm': 15},
        'start': 'onPhase',
      },
      <String, dynamic>{'type': 'fixed', 'hh': 14, 'mm': 0, 'cmd': 'off'},
    ],
    'assign': <String, dynamic>{},
  },
];
