/**
 * Health Check 코어 로직
 *
 * 동적으로 선택된 체커들을 실행하고 전체 시스템 상태를 반환합니다.
 */

import type { HealthChecker, HealthCheckResult, HealthStatus, SystemHealth } from './types';

/**
 * 헬스 체크 실행
 *
 * @param checkers - 실행할 체커 배열 (각 앱이 선택)
 * @returns 전체 시스템 헬스 상태
 *
 * @example
 * ```typescript
 * import { databaseChecker, performHealthCheck } from '@repo/health';
 *
 * const result = await performHealthCheck([databaseChecker]);
 * // result.checks.database: HealthCheckResult
 * ```
 */
export async function performHealthCheck(
  checkers: HealthChecker[],
): Promise<SystemHealth> {
  // 병렬로 모든 체커 실행
  const results = await Promise.all(
    checkers.map(async (checker) => ({
      name: checker.name,
      result: await checker.check(),
    })),
  );

  // 동적으로 checks 객체 생성
  const checks: Record<string, HealthCheckResult> = {};
  const statuses: HealthStatus[] = [];

  for (const { name, result } of results) {
    checks[name] = result;
    statuses.push(result.status);
  }

  // 전체 상태 결정
  const overall = determineOverallStatus(statuses);

  return {
    overall,
    checks,
    timestamp: new Date().toISOString(),
  };
}

/**
 * 전체 상태 결정 로직
 *
 * - 모두 healthy → healthy
 * - 하나라도 unhealthy → unhealthy
 * - 그 외 → degraded
 */
function determineOverallStatus(statuses: HealthStatus[]): HealthStatus {
  if (statuses.every((s) => s === 'healthy')) {
    return 'healthy';
  }
  if (statuses.some((s) => s === 'unhealthy')) {
    return 'unhealthy';
  }
  return 'degraded';
}
