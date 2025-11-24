'use client';

import { useQuery } from '@tanstack/react-query';

import type { HealthApiResponse, SystemHealth } from '../types';

/**
 * Health Check React Query Hook
 *
 * 30초마다 자동으로 폴링하여 시스템 상태 업데이트
 */
export function useHealthCheck(initialData?: SystemHealth) {
  return useQuery<SystemHealth>({
    queryKey: ['health'],
    queryFn: async () => {
      const response = await fetch('/api/health');

      if (!response.ok) {
        throw new Error(`Health check failed: ${response.status}`);
      }

      const data: HealthApiResponse = await response.json();

      if (!data.success) {
        throw new Error(data.error?.message || 'Health check failed');
      }

      return data.data;
    },
    // 초기 데이터 설정 (SSR에서 전달)
    initialData,
    // 30초마다 자동 refetch
    refetchInterval: 30 * 1000,
    // 컴포넌트 마운트 시에도 refetch
    refetchOnMount: true,
    // 네트워크 재연결 시 refetch
    refetchOnReconnect: true,
    // stale 시간 (30초)
    staleTime: 30 * 1000,
  });
}
