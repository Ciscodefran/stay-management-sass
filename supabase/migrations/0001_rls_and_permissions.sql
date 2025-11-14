-- =====================================
-- Row Level Security (RLS) 정책
-- =====================================
--
-- 이 마이그레이션은 다음을 포함합니다:
--   1. PostgreSQL 확장 설치 (pgcrypto)
--   2. 데이터베이스 역할 생성 및 권한 부여
--   3. RLS 정책 활성화 및 정책 정의
--   4. JWT 클레임 헬퍼 함수
--

-- =====================================
-- 1. 확장 설치
-- =====================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================
-- 2. 데이터베이스 역할 및 권한
-- =====================================

-- 애플리케이션 역할 생성
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user NOLOGIN;
  END IF;

  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_admin') THEN
    CREATE ROLE app_admin NOLOGIN;
  END IF;

  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ai_bot') THEN
    CREATE ROLE ai_bot NOLOGIN;
  END IF;
END
$$;

-- 스키마 사용 권한 부여
GRANT USAGE ON SCHEMA iam, org, biz, ref, pub TO app_user, app_admin, ai_bot;

-- 테이블 기본 권한 부여
-- app_user: 일반 사용자 (읽기, 쓰기)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA iam TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA org TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA biz TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA ref TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA pub TO app_user;

-- app_admin: 관리자 (모든 권한)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA iam TO app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA org TO app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA biz TO app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ref TO app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pub TO app_admin;

-- ai_bot: AI 봇 (읽기 전용 + 특정 테이블 쓰기)
GRANT SELECT ON ALL TABLES IN SCHEMA iam TO ai_bot;
GRANT SELECT ON ALL TABLES IN SCHEMA org TO ai_bot;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA biz TO ai_bot;
GRANT SELECT ON ALL TABLES IN SCHEMA ref TO ai_bot;
GRANT SELECT ON ALL TABLES IN SCHEMA pub TO ai_bot;

-- 시퀀스 사용 권한
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA iam TO app_user, app_admin, ai_bot;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA org TO app_user, app_admin, ai_bot;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA biz TO app_user, app_admin, ai_bot;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ref TO app_user, app_admin, ai_bot;

-- 미래 테이블에 대한 기본 권한 설정
ALTER DEFAULT PRIVILEGES IN SCHEMA iam GRANT SELECT, INSERT, UPDATE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA org GRANT SELECT, INSERT, UPDATE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA biz GRANT SELECT, INSERT, UPDATE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ref GRANT SELECT ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA pub GRANT SELECT ON TABLES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA iam GRANT ALL PRIVILEGES ON TABLES TO app_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA org GRANT ALL PRIVILEGES ON TABLES TO app_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA biz GRANT ALL PRIVILEGES ON TABLES TO app_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA ref GRANT ALL PRIVILEGES ON TABLES TO app_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA pub GRANT ALL PRIVILEGES ON TABLES TO app_admin;

-- =====================================
-- 3. JWT 클레임 헬퍼 함수
-- =====================================

-- JWT에서 internal_user_id 추출
CREATE OR REPLACE FUNCTION iam.get_internal_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'internal_user_id')::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid
  );
$$;

-- JWT에서 active_tenant_id 추출
CREATE OR REPLACE FUNCTION iam.get_active_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'active_tenant_id')::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid
  );
$$;

-- JWT에서 role 추출
CREATE OR REPLACE FUNCTION iam.get_user_role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'role',
    'anonymous'
  );
$$;

-- 사용자가 특정 테넌트에 속하는지 확인
CREATE OR REPLACE FUNCTION iam.user_belongs_to_tenant(tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM iam.user_tenants
    WHERE internal_user_id = iam.get_internal_user_id()
      AND iam.user_tenants.tenant_id = user_belongs_to_tenant.tenant_id
  );
$$;

-- =====================================
-- 4. RLS 정책 활성화
-- =====================================

-- IAM 스키마
ALTER TABLE iam.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE iam.user_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE iam.role_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE iam.user_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE iam.session_contexts ENABLE ROW LEVEL SECURITY;

-- ORG 스키마
ALTER TABLE org.tenants ENABLE ROW LEVEL SECURITY;

-- BIZ 스키마
ALTER TABLE biz.bookings ENABLE ROW LEVEL SECURITY;

-- REF 스키마 (참조 데이터는 읽기 전용)
ALTER TABLE ref.tenant_status_types ENABLE ROW LEVEL SECURITY;

-- =====================================
-- 5. IAM 스키마 RLS 정책
-- =====================================

-- iam.users: 자신의 정보만 조회/수정 가능
CREATE POLICY "users_select_own"
  ON iam.users
  FOR SELECT
  USING (id = iam.get_internal_user_id());

CREATE POLICY "users_update_own"
  ON iam.users
  FOR UPDATE
  USING (id = iam.get_internal_user_id());

-- iam.user_identities: 자신의 인증 정보만 조회 가능
CREATE POLICY "user_identities_select_own"
  ON iam.user_identities
  FOR SELECT
  USING (internal_user_id = iam.get_internal_user_id());

-- iam.role_types: 모든 사용자가 조회 가능 (참조 데이터)
CREATE POLICY "role_types_select_all"
  ON iam.role_types
  FOR SELECT
  USING (true);

-- iam.user_tenants: 자신의 테넌트 관계만 조회 가능
CREATE POLICY "user_tenants_select_own"
  ON iam.user_tenants
  FOR SELECT
  USING (internal_user_id = iam.get_internal_user_id());

-- iam.session_contexts: 자신의 세션만 조회/수정 가능
CREATE POLICY "session_contexts_select_own"
  ON iam.session_contexts
  FOR SELECT
  USING (internal_user_id = iam.get_internal_user_id());

CREATE POLICY "session_contexts_insert_own"
  ON iam.session_contexts
  FOR INSERT
  WITH CHECK (internal_user_id = iam.get_internal_user_id());

CREATE POLICY "session_contexts_update_own"
  ON iam.session_contexts
  FOR UPDATE
  USING (internal_user_id = iam.get_internal_user_id());

CREATE POLICY "session_contexts_delete_own"
  ON iam.session_contexts
  FOR DELETE
  USING (internal_user_id = iam.get_internal_user_id());

-- =====================================
-- 6. ORG 스키마 RLS 정책
-- =====================================

-- org.tenants: 자신이 속한 테넌트만 조회 가능
CREATE POLICY "tenants_select_member"
  ON org.tenants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM iam.user_tenants
      WHERE user_tenants.tenant_id = tenants.id
        AND user_tenants.internal_user_id = iam.get_internal_user_id()
    )
  );

-- org.tenants: tenant_owner 역할만 수정 가능
CREATE POLICY "tenants_update_owner"
  ON org.tenants
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM iam.user_tenants ut
      JOIN iam.role_types rt ON ut.role_type_id = rt.id
      WHERE ut.tenant_id = tenants.id
        AND ut.internal_user_id = iam.get_internal_user_id()
        AND rt.code = 'tenant_owner'
    )
  );

-- =====================================
-- 7. BIZ 스키마 RLS 정책
-- =====================================

-- biz.bookings: 활성 테넌트의 데이터만 조회 가능
CREATE POLICY "bookings_select_tenant"
  ON biz.bookings
  FOR SELECT
  USING (tenant_id = iam.get_active_tenant_id());

-- biz.bookings: 활성 테넌트에 대해 INSERT 가능
CREATE POLICY "bookings_insert_tenant"
  ON biz.bookings
  FOR INSERT
  WITH CHECK (tenant_id = iam.get_active_tenant_id());

-- biz.bookings: 활성 테넌트의 데이터만 수정 가능
CREATE POLICY "bookings_update_tenant"
  ON biz.bookings
  FOR UPDATE
  USING (tenant_id = iam.get_active_tenant_id());

-- biz.bookings: tenant_owner와 tenant_admin만 삭제 가능
CREATE POLICY "bookings_delete_admin"
  ON biz.bookings
  FOR DELETE
  USING (
    tenant_id = iam.get_active_tenant_id()
    AND EXISTS (
      SELECT 1
      FROM iam.user_tenants ut
      JOIN iam.role_types rt ON ut.role_type_id = rt.id
      WHERE ut.tenant_id = bookings.tenant_id
        AND ut.internal_user_id = iam.get_internal_user_id()
        AND rt.code IN ('tenant_owner', 'tenant_admin')
    )
  );

-- =====================================
-- 8. REF 스키마 RLS 정책
-- =====================================

-- ref.tenant_status_types: 모든 사용자가 조회 가능 (참조 데이터)
CREATE POLICY "tenant_status_types_select_all"
  ON ref.tenant_status_types
  FOR SELECT
  USING (true);

-- =====================================
-- 완료
-- =====================================
