'use client';

import { cn } from '../../lib/utils';

import { HealthBadge, type HealthStatus } from './health-badge';

export interface HealthCheck {
  name: string;
  status: HealthStatus;
  responseTime?: number;
}

export interface HealthStatusCardProps {
  checks: HealthCheck[];
  overallStatus: HealthStatus;
  timestamp: string;
  isLoading?: boolean;
  showError?: boolean;
  variant?: 'fixed-corner' | 'center' | 'inline';
  className?: string;
}

/**
 * 헬스 체크 상태 카드 컴포넌트
 *
 * variant 옵션:
 * - center: 메인 화면 중앙 배치 (기본값)
 * - fixed-corner: 우측 하단 고정
 * - inline: 인라인 배치
 */
export function HealthStatusCard({
  checks,
  overallStatus,
  timestamp,
  isLoading = false,
  showError = false,
  variant = 'center',
  className,
}: HealthStatusCardProps) {
  // variant에 따른 컨테이너 스타일
  const containerStyles = {
    center: 'w-full max-w-md mx-auto',
    'fixed-corner': 'fixed bottom-6 right-6 z-50 min-w-[280px]',
    inline: 'w-full',
  };

  // variant에 따른 카드 스타일
  const cardStyles = {
    center: 'bg-card rounded-xl shadow-sm border p-6',
    'fixed-corner': 'bg-card rounded-lg shadow-lg border p-4',
    inline: 'bg-card rounded-lg shadow-sm border p-4',
  };

  return (
    <div className={cn(containerStyles[variant], className)}>
      <div className={cn(cardStyles[variant])}>
        {/* 헤더 */}
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-semibold text-card-foreground">
            시스템 상태
          </h3>
          {isLoading && (
            <div className="w-4 h-4 border-2 border-muted border-t-primary rounded-full animate-spin" />
          )}
        </div>

        {/* 개별 체커 결과 */}
        <div className="space-y-3">
          {checks.map((check) => (
            <HealthBadge
              key={check.name}
              status={check.status}
              label={check.name}
              responseTime={check.responseTime}
            />
          ))}
        </div>

        {/* 전체 상태 */}
        <div className="mt-4 pt-4 border-t border-border">
          <HealthBadge status={overallStatus} label="전체" />
        </div>

        {/* 에러 메시지 (개발 환경 전용) */}
        {process.env.NODE_ENV === 'development' && showError && (
          <div className="mt-3 text-xs text-destructive">
            폴링 중 오류 발생 (초기 데이터 표시 중)
          </div>
        )}

        {/* 마지막 업데이트 시간 */}
        <div className="mt-3 text-xs text-muted-foreground text-right">
          마지막 업데이트:{' '}
          {new Date(timestamp).toLocaleTimeString('ko-KR', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
          })}
        </div>
      </div>
    </div>
  );
}
