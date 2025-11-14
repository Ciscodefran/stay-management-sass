-- =====================================
-- 추가 제약 조건 및 개선사항
-- =====================================
--
-- 이 마이그레이션은 다음을 포함합니다:
--   1. CHECK 제약 조건 추가
--   2. 성능 최적화를 위한 인덱스 추가
--   3. 데이터 무결성 강화
--

-- =====================================
-- 1. CHECK 제약 조건 추가
-- =====================================

-- iam.users.status에 CHECK 제약 조건 추가
ALTER TABLE iam.users
ADD CONSTRAINT iam_users_status_check
CHECK (status IN ('active', 'suspended', 'archived'));

-- org.tenants 테이블에 slug 형식 검증 추가
-- slug는 소문자, 숫자, 하이픈만 허용, 3-63자
ALTER TABLE org.tenants
ADD CONSTRAINT org_tenants_slug_format_check
CHECK (slug ~ '^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$');

-- =====================================
-- 2. 성능 최적화 인덱스
-- =====================================

-- iam.users 상태별 조회 최적화
CREATE INDEX IF NOT EXISTS iam_users_status_index
ON iam.users(status)
WHERE status = 'active';

-- biz.bookings 생성일 범위 조회 최적화
CREATE INDEX IF NOT EXISTS biz_bookings_created_at_index
ON biz.bookings(tenant_id, created_at DESC);

-- biz.bookings 업데이트일 범위 조회 최적화
CREATE INDEX IF NOT EXISTS biz_bookings_updated_at_index
ON biz.bookings(tenant_id, updated_at DESC);

-- iam.user_tenants 기본 테넌트 조회 최적화
CREATE INDEX IF NOT EXISTS iam_user_tenants_is_default_index
ON iam.user_tenants(internal_user_id, is_default)
WHERE is_default = true;

-- =====================================
-- 3. 추가 헬퍼 함수
-- =====================================

-- 사용자 생성 시 기본 설정
CREATE OR REPLACE FUNCTION iam.create_user_with_tenant(
  p_user_id uuid,
  p_tenant_id uuid,
  p_role_code varchar DEFAULT 'tenant_member'
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_role_type_id bigint;
BEGIN
  -- 역할 ID 조회
  SELECT id INTO v_role_type_id
  FROM iam.role_types
  WHERE code = p_role_code;

  IF v_role_type_id IS NULL THEN
    RAISE EXCEPTION 'Invalid role code: %', p_role_code;
  END IF;

  -- 사용자 생성
  INSERT INTO iam.users (id, status)
  VALUES (p_user_id, 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 테넌트 연결 (첫 번째 테넌트는 기본값으로 설정)
  INSERT INTO iam.user_tenants (
    internal_user_id,
    tenant_id,
    role_type_id,
    is_default
  )
  VALUES (
    p_user_id,
    p_tenant_id,
    v_role_type_id,
    NOT EXISTS (
      SELECT 1
      FROM iam.user_tenants
      WHERE internal_user_id = p_user_id
    )
  );
END;
$$;

-- 테넌트 생성 헬퍼 함수
CREATE OR REPLACE FUNCTION org.create_tenant(
  p_slug text,
  p_name text,
  p_owner_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_tenant_id uuid;
  v_active_status_id bigint;
  v_owner_role_id bigint;
BEGIN
  -- 활성 상태 ID 조회
  SELECT id INTO v_active_status_id
  FROM ref.tenant_status_types
  WHERE code = 'active';

  -- 소유자 역할 ID 조회
  SELECT id INTO v_owner_role_id
  FROM iam.role_types
  WHERE code = 'tenant_owner';

  -- 테넌트 생성
  INSERT INTO org.tenants (slug, name, status)
  VALUES (p_slug, p_name, v_active_status_id)
  RETURNING id INTO v_tenant_id;

  -- 소유자 설정
  INSERT INTO iam.user_tenants (
    internal_user_id,
    tenant_id,
    role_type_id,
    is_default
  )
  VALUES (
    p_owner_user_id,
    v_tenant_id,
    v_owner_role_id,
    NOT EXISTS (
      SELECT 1
      FROM iam.user_tenants
      WHERE internal_user_id = p_owner_user_id
    )
  );

  RETURN v_tenant_id;
END;
$$;

-- =====================================
-- 완료
-- =====================================
