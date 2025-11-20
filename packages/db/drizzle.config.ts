import type { Config } from 'drizzle-kit';

// 환경 변수는 실행 시 자동으로 로드됨
// 루트에서: pnpm db:generate (Turbo/PNPM이 .env 처리)
// 또는: cd packages/db && dotenv -e .env -- pnpm db:generate
if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL 환경 변수가 설정되지 않았습니다.');
}

export default {
  schema: './src/schema/**/*.ts',
  out: '../../supabase/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  verbose: true,
  strict: true,
  schemaFilter: ['iam', 'org', 'biz', 'ref', 'pub'],
  casing: 'snake_case',
  migrations: {
    table: 'drizzle_migrations',
    schema: 'public',
  },
} satisfies Config;
