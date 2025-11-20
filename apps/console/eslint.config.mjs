import nextConfig from '@repo/eslint-config/next';

export default [
  {
    ignores: ['*.config.mjs', '*.config.js', '.next/**', 'node_modules/**'],
  },
  ...nextConfig,
  {
    languageOptions: {
      parserOptions: {
        project: './tsconfig.json',
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    files: ['next-env.d.ts'],
    rules: {
      '@typescript-eslint/triple-slash-reference': 'off',
    },
  },
];
