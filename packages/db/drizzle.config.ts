import type { Config } from 'drizzle-kit';
import * as dotenv from 'dotenv';

// .env 파일 로드 (packages/db/.env 또는 루트 .env)
dotenv.config();
dotenv.config({ path: '../../.env' });

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL 환경 변수가 설정되지 않았습니다.');
}

export default {
  schema: './src/schema/index.ts',
  out: './src/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
  verbose: true,
  strict: true,
} satisfies Config;
