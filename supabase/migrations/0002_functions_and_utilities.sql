-- =====================================
-- 헬퍼 함수 및 유틸리티
-- =====================================
--
-- 이 마이그레이션은 다음을 포함합니다:
--   1. updated_at 자동 업데이트 트리거
--   2. 테넌트 컨텍스트 관리 함수
--   3. 사용자 역할 확인 함수
--   4. 데이터 무결성 검증 함수
--

-- =====================================
-- 1. updated_at 자동 업데이트
-- =====================================

-- updated_at 컬럼을 현재 시간으로 자동 업데이트하는 트리거 함수
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- org.tenants 테이블에 트리거 적용
DROP TRIGGER IF EXISTS update_tenants_updated_at ON org.tenants;
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON org.tenants
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- biz.bookings 테이블에 트리거 적용
DROP TRIGGER IF EXISTS update_bookings_updated_at ON biz.bookings;
CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON biz.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- iam.session_contexts 테이블에 트리거 적용
DROP TRIGGER IF EXISTS update_session_contexts_updated_at ON iam.session_contexts;
CREATE TRIGGER update_session_contexts_updated_at
  BEFORE UPDATE ON iam.session_contexts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================
-- 2. 테넌트 컨텍스트 관리
-- =====================================

-- 사용자의 기본 테넌트 조회
CREATE OR REPLACE FUNCTION iam.get_user_default_tenant(p_internal_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT tenant_id
  FROM iam.user_tenants
  WHERE internal_user_id = p_internal_user_id
    AND is_default = true
  LIMIT 1;
$$;

-- 사용자의 모든 테넌트 조회
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

-- =====================================
-- 3. 사용자 역할 확인
-- =====================================

-- 사용자가 특정 테넌트에서 특정 역할을 가지고 있는지 확인
CREATE OR REPLACE FUNCTION iam.user_has_role(
  p_internal_user_id uuid,
  p_tenant_id uuid,
  p_role_code varchar
)
RETURNS boolean
LANGUAGE sql
STABLE
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

-- 사용자가 특정 테넌트에서 관리자 권한을 가지고 있는지 확인
CREATE OR REPLACE FUNCTION iam.user_is_admin(
  p_internal_user_id uuid,
  p_tenant_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
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

-- 현재 사용자가 활성 테넌트에서 관리자인지 확인
CREATE OR REPLACE FUNCTION iam.current_user_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT iam.user_is_admin(
    iam.get_internal_user_id(),
    iam.get_active_tenant_id()
  );
$$;

-- =====================================
-- 4. 세션 컨텍스트 관리
-- =====================================

-- 세션 컨텍스트 생성 또는 업데이트
CREATE OR REPLACE FUNCTION iam.upsert_session_context(
  p_session_id text,
  p_internal_user_id uuid,
  p_client_id text,
  p_active_tenant_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO iam.session_contexts (
    session_id,
    internal_user_id,
    client_id,
    active_tenant_id,
    updated_at
  )
  VALUES (
    p_session_id,
    p_internal_user_id,
    p_client_id,
    p_active_tenant_id,
    now()
  )
  ON CONFLICT (session_id)
  DO UPDATE SET
    active_tenant_id = EXCLUDED.active_tenant_id,
    updated_at = now();
END;
$$;

-- 활성 테넌트 전환
CREATE OR REPLACE FUNCTION iam.switch_active_tenant(
  p_session_id text,
  p_new_tenant_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  v_internal_user_id uuid;
  v_has_access boolean;
BEGIN
  -- 세션의 사용자 ID 조회
  SELECT internal_user_id INTO v_internal_user_id
  FROM iam.session_contexts
  WHERE session_id = p_session_id;

  IF v_internal_user_id IS NULL THEN
    RETURN false;
  END IF;

  -- 사용자가 해당 테넌트에 접근 권한이 있는지 확인
  SELECT iam.user_belongs_to_tenant(p_new_tenant_id) INTO v_has_access;

  IF NOT v_has_access THEN
    RETURN false;
  END IF;

  -- 활성 테넌트 업데이트
  UPDATE iam.session_contexts
  SET active_tenant_id = p_new_tenant_id,
      updated_at = now()
  WHERE session_id = p_session_id;

  RETURN true;
END;
$$;

-- =====================================
-- 5. 데이터 무결성 검증
-- =====================================

-- 테넌트가 활성 상태인지 확인
CREATE OR REPLACE FUNCTION org.is_tenant_active(p_tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM org.tenants t
    JOIN ref.tenant_status_types tst ON t.status = tst.id
    WHERE t.id = p_tenant_id
      AND tst.code = 'active'
  );
$$;

-- 사용자가 활성 상태인지 확인
CREATE OR REPLACE FUNCTION iam.is_user_active(p_internal_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM iam.users
    WHERE id = p_internal_user_id
      AND status = 'active'
  );
$$;

-- =====================================
-- 6. 통계 및 집계 함수
-- =====================================

-- 테넌트별 예약 수 조회
CREATE OR REPLACE FUNCTION biz.get_tenant_booking_count(p_tenant_id uuid)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)
  FROM biz.bookings
  WHERE tenant_id = p_tenant_id;
$$;

-- 테넌트별 활성 사용자 수 조회
CREATE OR REPLACE FUNCTION iam.get_tenant_active_user_count(p_tenant_id uuid)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(DISTINCT ut.internal_user_id)
  FROM iam.user_tenants ut
  JOIN iam.users u ON ut.internal_user_id = u.id
  WHERE ut.tenant_id = p_tenant_id
    AND u.status = 'active';
$$;

-- =====================================
-- 완료
-- =====================================
