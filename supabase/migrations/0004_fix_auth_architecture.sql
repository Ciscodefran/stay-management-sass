-- =====================================
-- 인증 아키텍처 수정 (Gyro 호환)
-- =====================================
--
-- 이 마이그레이션은 다음을 수정합니다:
--   1. 멀티 Provider 인증 지원 (current_user_id 함수)
--   2. Function Security 강화 (SECURITY DEFINER + search_path)
--   3. pub 스키마 보안 강화
--   4. 권한 최소화 원칙 적용
--

-- =====================================
-- 1. current_user_id() 함수 (멀티 Provider 안전)
-- =====================================

-- 기존 함수 삭제 (있다면)
DROP FUNCTION IF EXISTS iam.current_user_id();

-- JWT (iss + sub)에서 user_identities를 통해 internal_user_id 반환
-- Clerk, Supabase Auth, Auth0 등 모든 Provider 지원
CREATE OR REPLACE FUNCTION iam.current_user_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
DECLARE
  v_iss text;
  v_sub text;
  v_user_id uuid;
BEGIN
  -- JWT에서 iss와 sub 추출
  -- Note: Supabase의 auth.jwt() 함수 사용
  -- 만약 auth 스키마가 없다면 current_setting 사용
  BEGIN
    v_iss := (current_setting('request.jwt.claims', true)::jsonb->>'iss');
    v_sub := (current_setting('request.jwt.claims', true)::jsonb->>'sub');
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;

  -- NULL 체크
  IF v_iss IS NULL OR v_sub IS NULL THEN
    RETURN NULL;
  END IF;

  -- user_identities에서 내부 user_id 조회 (issuer + subject 복합 검증)
  SELECT ui.internal_user_id INTO v_user_id
  FROM iam.user_identities ui
  WHERE ui.issuer = v_iss
    AND ui.subject = v_sub
  LIMIT 1;

  RETURN v_user_id;
END;
$$;

COMMENT ON FUNCTION iam.current_user_id() IS
'JWT (iss + sub)에서 iam.user_identities를 통해 내부 user_id (uuid)를 반환합니다. 멀티 provider 안전 (Clerk, Supabase Auth 등)';

-- authenticated 역할에만 실행 권한 부여
REVOKE ALL ON FUNCTION iam.current_user_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.current_user_id() TO authenticated;

-- =====================================
-- 2. 기존 헬퍼 함수 Security 강화
-- =====================================

-- get_internal_user_id() 함수 Security 강화
DROP FUNCTION IF EXISTS iam.get_internal_user_id();
CREATE OR REPLACE FUNCTION iam.get_internal_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT COALESCE(
    (current_setting('request.jwt.claims', true)::jsonb->>'internal_user_id')::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid
  );
$$;

-- get_active_tenant_id() 함수 Security 강화
DROP FUNCTION IF EXISTS iam.get_active_tenant_id();
CREATE OR REPLACE FUNCTION iam.get_active_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT COALESCE(
    (current_setting('request.jwt.claims', true)::jsonb->>'active_tenant_id')::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid
  );
$$;

-- get_user_role() 함수 Security 강화
DROP FUNCTION IF EXISTS iam.get_user_role();
CREATE OR REPLACE FUNCTION iam.get_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::jsonb->>'role',
    'anonymous'
  );
$$;

-- PUBLIC 권한 제거 및 authenticated만 허용
REVOKE ALL ON FUNCTION iam.get_internal_user_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION iam.get_active_tenant_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION iam.get_user_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.get_internal_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION iam.get_active_tenant_id() TO authenticated;
GRANT EXECUTE ON FUNCTION iam.get_user_role() TO authenticated;

-- =====================================
-- 3. 트리거 함수 Security 강화
-- =====================================

-- update_updated_at_column() 함수 재생성 (Security 강화)
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- 트리거 재생성
DROP TRIGGER IF EXISTS update_tenants_updated_at ON org.tenants;
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON org.tenants
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_bookings_updated_at ON biz.bookings;
CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON biz.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_session_contexts_updated_at ON iam.session_contexts;
CREATE TRIGGER update_session_contexts_updated_at
  BEFORE UPDATE ON iam.session_contexts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================
-- 4. pub 스키마 보안 강화
-- =====================================

-- PUBLIC 권한 명시적 제거
REVOKE ALL ON SCHEMA pub FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA pub FROM PUBLIC;

-- anon과 ai_bot 역할에만 접근 권한 부여
GRANT USAGE ON SCHEMA pub TO anon, ai_bot;
GRANT SELECT ON ALL TABLES IN SCHEMA pub TO anon, ai_bot;
ALTER DEFAULT PRIVILEGES IN SCHEMA pub GRANT SELECT ON TABLES TO anon, ai_bot;

-- =====================================
-- 5. 모든 헬퍼 함수 Security 강화
-- =====================================

-- user_belongs_to_tenant
DROP FUNCTION IF EXISTS iam.user_belongs_to_tenant(uuid);
CREATE OR REPLACE FUNCTION iam.user_belongs_to_tenant(tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM iam.user_tenants
    WHERE internal_user_id = iam.get_internal_user_id()
      AND iam.user_tenants.tenant_id = user_belongs_to_tenant.tenant_id
  );
$$;
REVOKE ALL ON FUNCTION iam.user_belongs_to_tenant(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.user_belongs_to_tenant(uuid) TO authenticated;

-- get_user_default_tenant
DROP FUNCTION IF EXISTS iam.get_user_default_tenant(uuid);
CREATE OR REPLACE FUNCTION iam.get_user_default_tenant(p_internal_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT tenant_id
  FROM iam.user_tenants
  WHERE internal_user_id = p_internal_user_id
    AND is_default = true
  LIMIT 1;
$$;
REVOKE ALL ON FUNCTION iam.get_user_default_tenant(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.get_user_default_tenant(uuid) TO authenticated;

-- get_user_tenants
DROP FUNCTION IF EXISTS iam.get_user_tenants(uuid);
CREATE OR REPLACE FUNCTION iam.get_user_tenants(p_internal_user_id uuid)
RETURNS TABLE(
  tenant_id uuid,
  tenant_slug text,
  tenant_name text,
  role_code varchar,
  is_default boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT
    ut.tenant_id,
    t.slug,
    t.name,
    rt.code,
    ut.is_default
  FROM iam.user_tenants ut
  JOIN org.tenants t ON ut.tenant_id = t.id
  JOIN iam.role_types rt ON ut.role_type_id = rt.id
  WHERE ut.internal_user_id = p_internal_user_id
  ORDER BY ut.is_default DESC, t.name;
$$;
REVOKE ALL ON FUNCTION iam.get_user_tenants(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.get_user_tenants(uuid) TO authenticated;

-- user_has_role
DROP FUNCTION IF EXISTS iam.user_has_role(uuid, uuid, varchar);
CREATE OR REPLACE FUNCTION iam.user_has_role(
  p_internal_user_id uuid,
  p_tenant_id uuid,
  p_role_code varchar
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM iam.user_tenants ut
    JOIN iam.role_types rt ON ut.role_type_id = rt.id
    WHERE ut.internal_user_id = p_internal_user_id
      AND ut.tenant_id = p_tenant_id
      AND rt.code = p_role_code
  );
$$;
REVOKE ALL ON FUNCTION iam.user_has_role(uuid, uuid, varchar) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.user_has_role(uuid, uuid, varchar) TO authenticated;

-- user_is_admin
DROP FUNCTION IF EXISTS iam.user_is_admin(uuid, uuid);
CREATE OR REPLACE FUNCTION iam.user_is_admin(
  p_internal_user_id uuid,
  p_tenant_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM iam.user_tenants ut
    JOIN iam.role_types rt ON ut.role_type_id = rt.id
    WHERE ut.internal_user_id = p_internal_user_id
      AND ut.tenant_id = p_tenant_id
      AND rt.code IN ('tenant_owner', 'tenant_admin')
  );
$$;
REVOKE ALL ON FUNCTION iam.user_is_admin(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.user_is_admin(uuid, uuid) TO authenticated;

-- current_user_is_admin
DROP FUNCTION IF EXISTS iam.current_user_is_admin();
CREATE OR REPLACE FUNCTION iam.current_user_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'pg_catalog'
AS $$
  SELECT iam.user_is_admin(
    iam.get_internal_user_id(),
    iam.get_active_tenant_id()
  );
$$;
REVOKE ALL ON FUNCTION iam.current_user_is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION iam.current_user_is_admin() TO authenticated;

-- =====================================
-- 6. 함수 소유자 명시 (RLS 우회 방지)
-- =====================================

ALTER FUNCTION iam.current_user_id() OWNER TO postgres;
ALTER FUNCTION iam.get_internal_user_id() OWNER TO postgres;
ALTER FUNCTION iam.get_active_tenant_id() OWNER TO postgres;
ALTER FUNCTION iam.get_user_role() OWNER TO postgres;
ALTER FUNCTION iam.user_belongs_to_tenant(uuid) OWNER TO postgres;
ALTER FUNCTION iam.get_user_default_tenant(uuid) OWNER TO postgres;
ALTER FUNCTION iam.get_user_tenants(uuid) OWNER TO postgres;
ALTER FUNCTION iam.user_has_role(uuid, uuid, varchar) OWNER TO postgres;
ALTER FUNCTION iam.user_is_admin(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION iam.current_user_is_admin() OWNER TO postgres;
ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

-- =====================================
-- 완료
-- =====================================
