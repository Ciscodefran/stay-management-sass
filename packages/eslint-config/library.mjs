import baseConfig from './base.mjs';

export default [
  ...baseConfig,
  {
    rules: {
      // 라이브러리/패키지 전용 규칙
      'no-console': 'warn',
    },
  },
];
