# Stay Management Database Migrations

이 디렉토리는 Stay Management SaaS 프로젝트의 데이터베이스 마이그레이션 파일들을 포함합니다.

## 📁 마이그레이션 구조

### 초기 마이그레이션 (순서대로 실행)

```
00000000000000_create_schemas.sql       # PostgreSQL 스키마 생성
0000_overrated_snowbird.sql            # Drizzle 생성: 테이블, FK, 인덱스
0001_rls_and_permissions.sql           # RLS 정책 및 권한
0002_functions_and_utilities.sql       # 헬퍼 함수 및 트리거
0003_add_constraints.sql               # 제약 조건 및 최적화
```

## 🏗️ 데이터베이스 아키텍처

### 스키마 구성

- **iam** (Identity & Access Management): 사용자, 인증, 권한, 세션
- **org** (Organization): 테넌트, 조직 정보
- **biz** (Business): 비즈니스 도메인 (예약, 결제 등)
- **ref** (Reference): 참조 데이터, 조회 테이블
- **pub** (Public): 공개 뷰, 집계 데이터

### 주요 테이블

#### IAM Schema
- `users`: 사용자 계정
- `user_identities`: 외부 인증 (Supabase Auth 연동)
- `role_types`: 역할 타입 (owner, admin, member, viewer)
- `user_tenants`: 사용자-테넌트 관계 및 역할
- `session_contexts`: 활성 세션 및 테넌트 컨텍스트

#### ORG Schema
- `tenants`: 멀티테넌트 조직

#### BIZ Schema
- `bookings`: 예약 정보 (Stay 비즈니스 도메인)

#### REF Schema
- `tenant_status_types`: 테넌트 상태 (active, suspended, archived)

## 🔐 보안 아키텍처

### Row Level Security (RLS)

모든 테이블에 RLS가 활성화되어 있으며, JWT 클레임 기반으로 동작합니다:

```sql
-- JWT 클레임에서 정보 추출
SELECT iam.get_internal_user_id();    -- 현재 사용자 ID
SELECT iam.get_active_tenant_id();    -- 현재 활성 테넌트 ID
SELECT iam.get_user_role();           -- 현재 사용자 역할
```

### 테넌트 격리

- 모든 비즈니스 테이블은 `tenant_id` 컬럼 보유
- RLS 정책으로 자동 필터링
- 사용자는 자신이 속한 테넌트 데이터만 접근 가능

### 역할 기반 접근 제어 (RBAC)

| 역할 | 코드 | 권한 |
|------|------|------|
| 테넌트 소유자 | `tenant_owner` | 전체 관리 권한 |
| 테넌트 관리자 | `tenant_admin` | 운영 관리 권한 |
| 업무 담당자 | `tenant_member` | 일반 읽기/쓰기 |
| 조회자 | `tenant_viewer` | 읽기 전용 |

## 🔧 Drizzle ORM 통합

### 마이그레이션 생성 워크플로우

1. **TypeScript 스키마 작성**: `packages/db/src/schema/` 에 Drizzle 스키마 정의
2. **마이그레이션 생성**: `pnpm db:generate` 실행
3. **수동 SQL 추가**: RLS 정책, 함수 등 Drizzle이 처리하지 못하는 부분
4. **적용**: `supabase db reset` 또는 `pnpm db:migrate`

### meta/ 폴더

Drizzle은 `meta/` 폴더에 마이그레이션 히스토리를 추적합니다:
- `_journal.json`: 마이그레이션 실행 기록
- `*_snapshot.json`: 각 마이그레이션 시점의 스키마 스냅샷

**⚠️ 중요**: meta/ 폴더를 Git에 커밋하세요. 향후 스키마 변경 감지에 필요합니다.

## 📝 개발 가이드

### 로컬 개발 환경

```bash
# Supabase 시작
supabase start

# 마이그레이션 적용 (reset)
supabase db reset

# 마이그레이션만 적용 (데이터 유지)
pnpm db:migrate
```

### 새 마이그레이션 생성

```bash
# 1. packages/db/src/schema/ 에서 TypeScript 스키마 수정
cd packages/db

# 2. Drizzle 마이그레이션 생성
pnpm db:generate

# 3. 필요시 수동 SQL 추가 (RLS, 함수 등)
# supabase/migrations/000X_custom.sql 생성

# 4. 테스트
cd ../..
supabase db reset
```

## 🧪 시딩 데이터

### seed.sql (자동 실행)
`supabase/seed.sql`은 필수 참조 데이터를 포함하며 `db reset` 시 자동 실행됩니다:
- 역할 타입 (role_types)
- 테넌트 상태 타입 (tenant_status_types)

### seed_demo.sql (수동 실행)
`supabase/seed_demo.sql`은 테스트용 데모 데이터를 포함하며 수동 실행해야 합니다:
```bash
psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed_demo.sql
```

## 🔍 유용한 헬퍼 함수

### 테넌트 관리
```sql
-- 새 테넌트 생성 (소유자 자동 설정)
SELECT org.create_tenant('my-hotel', 'My Hotel', '<user_id>');

-- 테넌트가 활성 상태인지 확인
SELECT org.is_tenant_active('<tenant_id>');
```

### 사용자 관리
```sql
-- 사용자 생성 및 테넌트 연결
SELECT iam.create_user_with_tenant('<user_id>', '<tenant_id>', 'tenant_admin');

-- 사용자의 모든 테넌트 조회
SELECT * FROM iam.get_user_tenants('<user_id>');

-- 사용자가 관리자인지 확인
SELECT iam.user_is_admin('<user_id>', '<tenant_id>');
```

### 세션 관리
```sql
-- 세션 컨텍스트 생성/업데이트
SELECT iam.upsert_session_context('<session_id>', '<user_id>', 'app', '<tenant_id>');

-- 활성 테넌트 전환
SELECT iam.switch_active_tenant('<session_id>', '<new_tenant_id>');
```

## 📊 성능 최적화

### 인덱스 전략

- **테넌트 격리**: 모든 비즈니스 테이블에 `(tenant_id, ...)` 복합 인덱스
- **역할 조회**: `user_tenants(internal_user_id, tenant_id)` 인덱스
- **시간 범위 조회**: `created_at DESC`, `updated_at DESC` 인덱스
- **상태 필터링**: `WHERE status = 'active'` 부분 인덱스

### 트리거

- `updated_at` 컬럼 자동 업데이트 트리거 (tenants, bookings, session_contexts)

## 🚨 주의사항

### Drizzle vs 수동 SQL

- **Drizzle로 관리**: 테이블, 컬럼, FK, 기본 인덱스
- **수동 SQL로 관리**: RLS 정책, 복잡한 함수, CHECK 제약조건, 트리거

### 마이그레이션 순서

마이그레이션 파일명은 자동으로 정렬됩니다:
1. `00000000000000_*`: 우선 실행 (스키마 생성)
2. `0000_*`: Drizzle 생성 마이그레이션
3. `0001_*`, `0002_*`: 순차 실행

### 롤백

Supabase는 마이그레이션 롤백을 직접 지원하지 않습니다:
- 개발: `supabase db reset`으로 초기화 후 재실행
- 프로덕션: 수동 롤백 SQL 작성 필요

## 📚 참고 자료

- [Drizzle ORM Documentation](https://orm.drizzle.team/)
- [Supabase Local Development](https://supabase.com/docs/guides/cli)
- [PostgreSQL Row Level Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
