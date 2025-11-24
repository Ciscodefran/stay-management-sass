'use client';

import { cn } from '../../lib/utils';

export type HealthStatus = 'healthy' | 'degraded' | 'unhealthy';

export interface HealthBadgeProps {
  status: HealthStatus;
  label: string;
  responseTime?: number;
  className?: string;
}

const statusConfig: Record<
  HealthStatus,
  {
    bg: string;
    text: string;
    dot: string;
    label: string;
  }
> = {
  healthy: {
    bg: 'bg-green-50',
    text: 'text-green-700',
    dot: 'bg-green-500',
    label: '정상',
  },
  degraded: {
    bg: 'bg-yellow-50',
    text: 'text-yellow-700',
    dot: 'bg-yellow-500',
    label: '경고',
  },
  unhealthy: {
    bg: 'bg-red-50',
    text: 'text-red-700',
    dot: 'bg-red-500',
    label: '오류',
  },
};

/**
 * 헬스 체크 상태 배지 컴포넌트
 *
 * 순수 프레젠테이션 컴포넌트로, 비즈니스 로직과 분리되어 있습니다.
 */
export function HealthBadge({
  status,
  label,
  responseTime,
  className,
}: HealthBadgeProps) {
  const config = statusConfig[status];

  return (
    <div className={cn('flex items-center gap-2 text-sm', className)}>
      <div className="flex items-center gap-2">
        <span className="font-medium text-gray-700 min-w-[80px]">{label}:</span>
        <div
          className={cn(
            'flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-colors',
            config.bg,
          )}
        >
          <span
            className={cn('w-2 h-2 rounded-full animate-pulse', config.dot)}
          />
          <span className={cn('font-medium text-xs', config.text)}>
            {config.label}
          </span>
        </div>
      </div>
      {responseTime !== undefined && (
        <span className="text-xs text-gray-500 tabular-nums">
          {responseTime}ms
        </span>
      )}
    </div>
  );
}
