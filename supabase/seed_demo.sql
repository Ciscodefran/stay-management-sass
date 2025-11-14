-- =====================================
-- 데모/테스트 데이터 시딩
-- 수동 실행: psql -f seed_demo.sql
-- =====================================
--
-- 이 파일은 로컬 개발 및 테스트를 위한 데모/테스트 데이터를 포함합니다.
-- Supabase 프리뷰 브랜치나 db reset에 의해 자동으로 실행되지 않습니다.
--
-- 사용법:
--   psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed_demo.sql
--

-- =====================================
-- 예시 Tenants
-- =====================================

INSERT INTO org.tenants (slug, name, status)
VALUES
  ('demo-hotel', 'Demo Hotel', (SELECT id FROM ref.tenant_status_types WHERE code = 'active')),
  ('test-resort', 'Test Resort', (SELECT id FROM ref.tenant_status_types WHERE code = 'active'))
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    status = EXCLUDED.status;

-- =====================================
-- 예시 Users
-- =====================================

-- 필요한 경우 여기에 데모 유저를 추가하세요
-- INSERT INTO iam.users (id, status, created_at)
-- VALUES
--   (gen_random_uuid(), 'active', now());

-- =====================================
-- 예시 User-Tenant 관계
-- =====================================

-- 필요한 경우 여기에 유저를 테넌트와 역할로 연결하세요
-- INSERT INTO iam.user_tenants (internal_user_id, tenant_id, role_type_id, is_default, created_at)
-- VALUES
--   (...);

-- =====================================
-- 예시 Bookings
-- =====================================

-- 필요한 경우 여기에 데모 bookings를 추가하세요
-- INSERT INTO biz.bookings (tenant_id, owner_user_id, created_at)
-- VALUES
--   (...);
