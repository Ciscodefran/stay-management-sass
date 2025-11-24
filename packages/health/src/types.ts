/**
 * Health Check 시스템 타입 정의
 *
 * 보안 고려사항:
 * - 프로덕션 환경에서는 상세한 에러 메시지 대신 error code만 노출
 * - 서버 로그에만 상세 에러 정보 기록
 */

/**
 * 헬스 체크 상태
 */
export type HealthStatus = 'healthy' | 'degraded' | 'unhealthy';

/**
 * 에러 코드 (클라이언트 노출용)
 */
export type HealthErrorCode =
  | 'DB_CONNECTION_FAILED'      // 데이터베이스 연결 실패
  | 'DB_QUERY_TIMEOUT'          // 쿼리 타임아웃
  | 'SERVICE_UNAVAILABLE'       // 서비스 사용 불가
  | 'UNKNOWN_ERROR';            // 알 수 없는 에러

/**
 * 개별 헬스 체크 결과
 */
export interface HealthCheckResult {
  status: HealthStatus;
  message: string;               // 사용자용 메시지 (한글)
  code?: HealthErrorCode;        // 에러 발생 시 코드
  timestamp: string;             // ISO 8601 형식
  responseTime?: number;         // 응답 시간 (ms)
  debug?: string;                // 개발 환경 전용 디버그 정보
}

/**
 * 헬스 체커 인터페이스
 *
 * 각 앱이 필요한 체커를 선택하여 사용할 수 있도록 설계
 */
export interface HealthChecker {
  name: string;                                  // 체커 이름 (동적 키로 사용)
  check: () => Promise<HealthCheckResult>;       // 체크 함수
}

/**
 * 시스템 전체 헬스 체크 결과
 *
 * checks는 동적 Record 타입으로 유연성 확보
 */
export interface SystemHealth {
  overall: HealthStatus;                         // 전체 시스템 상태
  checks: Record<string, HealthCheckResult>;     // 동적 체커 결과
  timestamp: string;                             // 체크 시각
}

/**
 * API 응답 타입
 */
export interface HealthApiResponse {
  success: boolean;
  data: SystemHealth;
  error?: {
    code: string;
    message: string;
  };
}
