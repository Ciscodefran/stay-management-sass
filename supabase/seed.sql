-- =====================================
-- 참조 데이터 시딩
-- 자동 실행: supabase db reset
-- =====================================
--
-- 이 파일은 애플리케이션이 올바르게 작동하기 위해 필요한
-- 참조/조회 데이터만 포함합니다.
--
-- 데모/테스트 데이터는 seed_demo.sql에 작성하세요 (수동 실행).
--

-- =====================================
-- IAM: 역할 타입
-- =====================================

INSERT INTO iam.role_types (code, name, description)
VALUES
  ('tenant_owner', '테넌트 소유', '관리 최고 권한'),
  ('tenant_admin', '테넌트 관리', '운영 전반 관리자로써 사용자 역할, 관리'),
  ('tenant_member', '업무 담당', '일반 쓰기 권한을 가진 업무 담당자'),
  ('tenant_viewer', '조회, 감사', '자원에 읽기 전용')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;

-- =====================================
-- REF: 테넌트 상태 타입
-- =====================================

INSERT INTO ref.tenant_status_types (code, name, description)
VALUES
  ('active', '정상', '정산 로그인, 읽기, 쓰기, 결제 모두 허용'),
  ('suspended', '정지', '로그인 차단. 쓰기, 결제, 웹훅 비활성. 복구 가능'),
  ('archived', '제거', '로그인 완전 차단. 데이터 보존만, 청구 중단. 복구 불가능')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description;
