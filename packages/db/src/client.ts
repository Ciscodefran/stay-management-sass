import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

import * as bizSchema from './schema/biz';
import * as iamSchema from './schema/iam';
import * as orgSchema from './schema/org';
import * as refSchema from './schema/ref';

/**
 * 전역 PostgreSQL 클라이언트
 * Vercel Fluid Compute에서 동일 인스턴스 내 재사용됨
 */
let globalClient: postgres.Sql | null = null;

/**
 * PostgreSQL 클라이언트 가져오기 (싱글톤 패턴)
 *
 * Vercel Serverless 최적화:
 * - max: 1 (함수당 1개 연결)
 * - idle_timeout: 5 (5초 후 자동 정리)
 * - prepare: false (Supabase 권장)
 */
function getPostgresClient(): postgres.Sql {
  if (!globalClient) {
    const connectionString = process.env.DATABASE_URL;

    if (!connectionString) {
      throw new Error(
        'DATABASE_URL 환경 변수가 필요합니다.\n\n' +
        '로컬 개발:\n' +
        '  postgresql://postgres:postgres@127.0.0.1:54322/postgres\n\n' +
        '프로덕션 (Supabase Pooler 사용 권장):\n' +
        '  postgresql://postgres.[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true\n\n' +
        'Supabase Dashboard > Settings > Database > Connection Pooling에서 확인하세요.',
      );
    }

    globalClient = postgres(connectionString, {
      max: 1,                    // Vercel 권장: 함수당 1개 연결
      idle_timeout: 5,           // Vercel 권장: 5초 후 자동 정리
      connect_timeout: 10,       // 연결 타임아웃
      prepare: false,            // Supabase 권장 (Pooler와 호환)
    });

    // 개발 환경에서만 연결 정보 로그
    if (process.env.NODE_ENV === 'development') {
      // eslint-disable-next-line no-console
      console.log('✅ PostgreSQL 클라이언트 생성됨');
    }
  }

  return globalClient;
}

/**
 * 통합 데이터베이스 스키마
 */
const schema = {
  ...iamSchema,
  ...orgSchema,
  ...bizSchema,
  ...refSchema,
};

/**
 * 메인 Drizzle ORM 인스턴스
 *
 * 전역으로 선언되어 Vercel Fluid Compute에서 재사용됩니다.
 * 각 요청은 동일한 인스턴스를 공유하여 성능을 최적화합니다.
 */
export const db = drizzle(getPostgresClient(), { schema });

/**
 * 데이터베이스 타입 정의
 */
export type Database = typeof db;
