'use client';

import { useHealthCheck, type SystemHealth } from '@repo/health';
import { HealthStatusCard, type HealthCheck } from '@repo/ui';

interface HealthWrapperProps {
  initialData: SystemHealth;
}

/**
 * 헬스체크 래퍼 컴포넌트
 *
 * @repo/health의 비즈니스 로직과 @repo/ui의 프레젠테이션 컴포넌트를 연결
 */
export function HealthWrapper({ initialData }: HealthWrapperProps) {
  const { data, isLoading, isError } = useHealthCheck(initialData);

  // 로딩 중이거나 에러 시 초기 데이터 사용
  const healthData = data || initialData;

  // SystemHealth의 checks를 HealthCheck[] 형태로 변환
  const checks: HealthCheck[] = Object.entries(healthData.checks).map(
    ([name, result]) => ({
      name,
      status: result.status,
      responseTime: result.responseTime,
    }),
  );

  return (
    <HealthStatusCard
      checks={checks}
      overallStatus={healthData.overall}
      timestamp={healthData.timestamp}
      isLoading={isLoading}
      showError={isError}
      variant="center"
    />
  );
}
