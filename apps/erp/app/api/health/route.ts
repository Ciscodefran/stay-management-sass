/**
 * Health Check API Route
 *
 * GET /api/health
 *
 * React Query에서 폴링하여 시스템 상태를 실시간 모니터링
 */

import type { HealthApiResponse } from '@repo/health';
import { NextResponse } from 'next/server';

import { performAppHealthCheck } from '@/lib/health';

export const dynamic = 'force-dynamic'; // 캐싱 비활성화 (항상 최신 상태 반환)

export async function GET() {
  try {
    const healthData = await performAppHealthCheck();

    const response: HealthApiResponse = {
      success: true,
      data: healthData,
    };

    return NextResponse.json(response, {
      status: 200,
      headers: {
        'Cache-Control': 'no-store, max-age=0', // 캐싱 방지
      },
    });
  } catch (error) {
    // 예상치 못한 에러 발생
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    console.error('[Health API] Unexpected error:', {
      error: errorMessage,
      timestamp: new Date().toISOString(),
    });

    const response: HealthApiResponse = {
      success: false,
      data: {
        overall: 'unhealthy',
        checks: {
          database: {
            status: 'unhealthy',
            message: '시스템 오류',
            code: 'UNKNOWN_ERROR',
            timestamp: new Date().toISOString(),
          },
          supabase: {
            status: 'unhealthy',
            message: '시스템 오류',
            code: 'UNKNOWN_ERROR',
            timestamp: new Date().toISOString(),
          },
        },
        timestamp: new Date().toISOString(),
      },
      error: {
        code: 'UNKNOWN_ERROR',
        message: '시스템 상태 확인 중 오류가 발생했습니다',
      },
    };

    return NextResponse.json(response, {
      status: 500,
    });
  }
}
