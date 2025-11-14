module.exports = {
  root: true,
  extends: ['@repo/eslint-config/next.js'],
  parserOptions: {
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
  },
};
