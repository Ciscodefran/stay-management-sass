module.exports = {
  extends: ['./base.js', 'next/core-web-vitals'],
  rules: {
    // Next.js 전용 규칙
    '@next/next/no-html-link-for-pages': 'off',
    'react/jsx-key': 'error',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // React 포매팅
    'react/jsx-indent': ['error', 2],
    'react/jsx-indent-props': ['error', 2],
    'react/jsx-max-props-per-line': ['error', {
      'maximum': 1,
      'when': 'multiline',
    }],
    'react/jsx-first-prop-new-line': ['error', 'multiline'],
    'react/jsx-closing-bracket-location': ['error', 'line-aligned'],
    'react/jsx-wrap-multilines': ['error', {
      'declaration': 'parens-new-line',
      'assignment': 'parens-new-line',
      'return': 'parens-new-line',
      'arrow': 'parens-new-line',
    }],

    // JSX/TSX 규칙
    'react/self-closing-comp': 'error',
    'react/jsx-boolean-value': ['error', 'never'],
    'react/jsx-curly-brace-presence': ['error', {
      'props': 'never',
      'children': 'never',
    }],
  },
};
