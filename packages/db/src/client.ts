/**
 * @gyro/db/client - 서버 전용 진입점
 *
 * ⚠️ 서버 전용 - REACT NATIVE에서 임포트 금지
 *
 * 이 파일이 제공하는 것:
 * - Drizzle 데이터베이스 인스턴스
 * - 데이터베이스 연결 유틸리티
 * - Node.js postgres 드라이버
 *
 * 사용 가능:
 * - apps/erp (Next.js)
 * - apps/mind (Fastify)
 *
 * ❌ 사용 불가:
 * - apps/dollor (React Native)
 *
 * 사용법:
 *   import { db } from '@gyro/db/client';
 *   const users = await db.select().from(usersTable);
 */

import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as iamSchema from './schema/iam';
import * as orgSchema from './schema/org';
import * as bizSchema from './schema/biz';
import * as refSchema from './schema/ref';

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
