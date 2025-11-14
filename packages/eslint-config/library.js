module.exports = {
  extends: ['./base.js'],
  env: {
    node: true,
  },
  rules: {
    // 라이브러리/패키지 전용 규칙
    'no-console': 'warn',
  },
};
