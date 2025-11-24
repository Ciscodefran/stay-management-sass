/**
 * Console 앱 헬스 체크 설정
 *
 * 이 앱에서 사용할 헬스 체커를 선택합니다.
 */

import { performHealthCheck } from '@repo/health';
import { databaseChecker } from '@repo/health/checkers';

/**
 * Console 앱에서 사용할 헬스 체커 목록
 *
 * 필요에 따라 다른 체커를 추가할 수 있습니다:
 * - cacheChecker (Redis 등)
 * - storageChecker (S3 등)
 * - externalApiChecker (외부 API)
 */
export const healthCheckers = [
  databaseChecker,
  // 추가 체커가 필요하면 여기에 등록
];

/**
 * Console 앱 헬스 체크 실행
 */
export const performAppHealthCheck = () =>
  performHealthCheck(healthCheckers);
