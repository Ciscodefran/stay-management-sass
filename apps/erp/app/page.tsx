import { performAppHealthCheck } from '@/lib/health';
import { HealthWrapper } from '@/lib/health-wrapper';

/**
 * ERP 메인 페이지
 *
 * Hybrid SSR + CSR:
 * - SSR로 초기 헬스체크 데이터 로드 (0ms 초기 로딩)
 * - CSR로 30초마다 React Query 폴링 (실시간 업데이트)
 */
export default async function Home() {
  // 서버에서 초기 헬스체크 실행
  const initialHealthData = await performAppHealthCheck();

  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-24">
      <main className="flex flex-col items-center gap-8">
        <h1 className="text-4xl font-bold text-primary">ERP App</h1>
        <p className="text-lg text-muted-foreground">
          Stay Management ERP Application
        </p>

        {/* 헬스체크 상태 표시 (중앙 배치) */}
        <HealthWrapper initialData={initialHealthData} />
      </main>
    </div>
  );
}
