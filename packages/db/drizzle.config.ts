import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/schema/**/*.ts',
  out: '../../supabase/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  schemaFilter: ['iam', 'org', 'biz', 'ref', 'pub'],
  casing: 'snake_case',
  verbose: true,
  strict: true,
  migrations: {
    table: 'drizzle_migrations',
    schema: 'public',
  },
});
