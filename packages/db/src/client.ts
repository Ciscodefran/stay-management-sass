import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

/**
 * DATABASE_URL 환경 변수로부터 Drizzle 클라이언트를 생성합니다.
 *
 * 각 앱에서 .env.local에 DATABASE_URL을 설정하면
 * 해당 Supabase 인스턴스에 연결됩니다.
 */
const getDatabaseUrl = (): string => {
  const url = process.env.DATABASE_URL;

  if (!url) {
    throw new Error(
      'DATABASE_URL 환경 변수가 설정되지 않았습니다.\n' +
      '앱의 .env.local 파일에 DATABASE_URL을 추가해주세요.'
    );
  }

  return url;
};

// Connection pool 생성
const connectionString = getDatabaseUrl();

const client = postgres(connectionString, {
  max: 10,                    // 최대 연결 수
  idle_timeout: 20,           // idle 연결 타임아웃 (초)
  connect_timeout: 10,        // 연결 타임아웃 (초)
  prepare: false,             // Supabase에서 권장
});

// Drizzle 인스턴스
export const db = drizzle(client, { schema });

// 타입 export
export type DB = typeof db;
