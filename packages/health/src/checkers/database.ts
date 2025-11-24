/**
 * Database Health Checker
 *
 * DB 연결 상태를 체크합니다.
 * 구체적인 구현 (Supabase 등)을 숨기고 추상화된 DB 체크만 제공합니다.
 */

import { db } from '@repo/db';
import { sql } from 'drizzle-orm';

import type { HealthChecker } from '../types';

const isDev = process.env.NODE_ENV === 'development';

export const databaseChecker: HealthChecker = {
  name: 'database',
  check: async () => {
    const startTime = Date.now();

    try {
      // 간단한 SELECT 1 쿼리로 연결 확인
      await db.execute(sql`SELECT 1`);

      return {
        status: 'healthy',
        message: 'DB 연결 정상',
        timestamp: new Date().toISOString(),
        responseTime: Date.now() - startTime,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);

      // 서버 로그에만 상세 에러 기록
      // eslint-disable-next-line no-console
      console.error('[Health Check] Database error:', {
        error: errorMessage,
        timestamp: new Date().toISOString(),
      });

      // 타임아웃 vs 연결 실패 구분
      const isTimeout = errorMessage.includes('timeout') || errorMessage.includes('aborted');
      const code = isTimeout ? 'DB_QUERY_TIMEOUT' : 'DB_CONNECTION_FAILED';

      return {
        status: 'unhealthy',
        message: 'DB 연결 실패',
        code,
        timestamp: new Date().toISOString(),
        responseTime: Date.now() - startTime,
        ...(isDev && { debug: errorMessage }), // 개발 환경에서만 노출
      };
    }
  },
};
