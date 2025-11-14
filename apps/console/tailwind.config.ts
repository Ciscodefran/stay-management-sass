import type { Config } from 'tailwindcss';
import sharedConfig from '@repo/ui/tailwind.config';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    '../../packages/ui/src/**/*.{js,ts,jsx,tsx}',
  ],
  presets: [sharedConfig],
  theme: {
    extend: {
      // Console 앱 전용 커스터마이징
    },
  },
};

export default config;
