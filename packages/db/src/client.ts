import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';
import * as iamSchema from './schema/iam';
import * as orgSchema from './schema/org';
import * as bizSchema from './schema/biz';
import * as refSchema from './schema/ref';

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

// 데이터베이스 연결 설정
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    'DATABASE_URL 환경 변수가 설정되지 않았습니다. .env 파일에 설정해주세요.'
  );
}

// Postgres 연결 생성
export const connection = postgres(connectionString, {
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
});

// 모든 스키마를 포함한 Drizzle 인스턴스 생성
export const db = drizzle(connection, {
  schema: {
    ...iamSchema,
    ...orgSchema,
    ...bizSchema,
    ...refSchema,
  },
});

// 편의를 위한 스키마 재출력
export * from './schema';

// 타입 헬퍼
export type Database = typeof db;

/**
 * 커스텀 연결 문자열로 새 DB 클라이언트를 생성하는 팩토리 함수
 * Next.js Server Actions에서 요청당 캐싱에 유용함
 *
 * @param customConnectionString - 선택적 커스텀 연결 문자열
 * @returns 새 Drizzle 데이터베이스 인스턴스
 */
export function createDbClient(customConnectionString?: string) {
  const connString = customConnectionString || connectionString;

  if (!connString) {
    throw new Error('DATABASE_URL이 필요합니다');
  }

  const client = postgres(connString, {
    max: 10,
    idle_timeout: 20,
    connect_timeout: 10,
  });

  return drizzle(client, {
    schema: {
      ...iamSchema,
      ...orgSchema,
      ...bizSchema,
      ...refSchema,
    },
  });
}

export type DbClient = ReturnType<typeof createDbClient>;
